use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Oracle::Storage;
use DBIO::Oracle::Diff;

# OFFLINE (karr k63). What the Diff and Bind lists of the shared case table
# showed in the driver, pinned on the wire without a server. Each of these was
# a server error or a wrong answer before; t/87 and t/89 run them against one.
#
#   1. a column dropped with an index on it writes no DROP INDEX (Oracle drops
#      the index with the column, a DROP INDEX after it is ORA-01418), and the
#      DROP COLUMN takes the constraints of the column with it (ORA-12991);
#   2. a LOB is compared by value in parts of 1000 characters (text) or 2000
#      bytes sent as hex (binary), and an empty value as an empty LOB;
#   3. an insert of no values names one column, DEFAULT VALUES is no Oracle.

# --- 1: the diff ---------------------------------------------------------------

{
  sub col { my ($n, %o) = @_; return { column_name => $n, data_type => 'integer', %o } }
  my $wide = sub {
    my ($cols, $indexes) = @_;
    return {
      tables  => { wide => { table_name => 'wide', kind => 'table' } },
      columns => { wide => [ map { col($_) } @$cols ] },
      indexes => { wide => $indexes },
    };
  };

  my $diff = DBIO::Oracle::Diff->new(
    source => $wide->([qw(id a b c)], {
      wide_a_idx  => { columns => ['a'],      is_unique => 0 },
      wide_ab_idx => { columns => ['a', 'b'], is_unique => 0 },
      wide_c_idx  => { columns => ['c'],      is_unique => 0 },
    }),
    target => $wide->([qw(id c)], { wide_c_idx => { columns => ['c'], is_unique => 0 } }),
  );
  my @sql = grep { length } map { s/\s+\z//r } split /\n/, $diff->as_sql;
  is_deeply \@sql, [
    'ALTER TABLE "wide" DROP COLUMN "a" CASCADE CONSTRAINTS;',
    'ALTER TABLE "wide" DROP COLUMN "b" CASCADE CONSTRAINTS;',
  ], 'the columns are dropped with their constraints, and no index that went with them is dropped';

  my $kept = DBIO::Oracle::Diff->new(
    source => $wide->([qw(id a c)], { wide_a_idx => { columns => ['a'], is_unique => 0 } }),
    target => $wide->([qw(id a c)], {}),
  );
  like $kept->as_sql, qr/DROP INDEX "wide_a_idx"/,
    'an index of a column that stays is still dropped when the target has none';
}

# --- 4: a default the target no longer has is removed (karr k63) -----------------
#
# CLAIM: removing the default of a column from the declaration is a change the
# diff writes (DEFAULT NULL); before, the desired-state comparison skipped a
# default the target leaves undef and the old default stayed. A target that is
# no introspection (a model written by hand, no 'schema' on its table) still
# leaves an unstated default alone.
{
  my $model = sub {
    my ($default, $described) = @_;
    return {
      tables  => { opt => { table_name => 'opt', kind => 'table', ($described ? (schema => 'U') : ()) } },
      columns => { opt => [ {
        column_name => 'c', data_type => 'varchar', size => 20,
        (defined $default ? (default_value => $default) : ()),
      } ] },
    };
  };
  my $diff = DBIO::Oracle::Diff->new(source => $model->('x', 1), target => $model->(undef, 1));
  is $diff->as_sql, qq{ALTER TABLE "opt" MODIFY ("c" DEFAULT NULL);},
    'the default the described target no longer has is set to DEFAULT NULL';

  my $second = DBIO::Oracle::Diff->new(source => $model->(undef, 1), target => $model->(undef, 1));
  ok !$second->has_changes, '... and the result has no further diff';

  my $hand = DBIO::Oracle::Diff->new(source => $model->('x', 1), target => $model->(undef, 0));
  ok !$hand->has_changes, 'a hand-written target that states no default leaves it alone';
}

# --- 2 and 3: the storage -------------------------------------------------------

DBIO::Test::Schema::BindType->add_columns(
  blb2 => { data_type => 'blob', is_nullable => 1 },
);

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::Oracle::Storage');
$schema = $schema->connect('dbi:Oracle:never', 'u', 'p');
my $storage = $schema->storage;
my $source  = $schema->resultset('BindType')->result_source;

sub select_by {
  my ($cond) = @_;
  return $storage->_prep_for_execute('select', $source, [ [ 'id' ], $cond, {} ]);
}

{
  my ($sql, $bind) = select_by({ clob => 'abc' });
  like $sql, qr/\( DBMS_LOB\.SUBSTR\("clob", 1000, 1\) = \? \)/,
    'text: one part, the whole column up to the part is compared';
  is_deeply [ map { $_->[1] } @$bind ], ['abc'], '... the bind is the value';

  my $long = join '', map { chr(65 + $_ % 26) } 0 .. 2499;
  ($sql, $bind) = select_by({ clob => $long });
  my @offsets = $sql =~ /DBMS_LOB\.SUBSTR\("clob", 1000, (\d+)\) = \?/g;
  is_deeply \@offsets, [ 1, 1001, 2001 ], 'text: 2500 characters are three parts of 1000';
  is_deeply [ map { length $_->[1] } @$bind ], [ 1000, 1000, 500 ], '... bound as such';

  my $wide = "\x{65e5}\x{672c}\x{8a9e}" x 1667;
  ($sql, $bind) = select_by({ clob => $wide });
  is scalar(() = $sql =~ /DBMS_LOB\.SUBSTR\("clob", 1000,/g), 6,
    'text: 5001 Japanese characters are six parts, none of them more than 4000 bytes';

  ($sql, $bind) = select_by({ clob => '' });
  like $sql, qr/\( DBMS_LOB\.GETLENGTH\("clob"\) = 0 \)/,
    'empty: the empty LOB is compared by its length, there is no part';
  is scalar @$bind, 0, '... and nothing is bound';

  ($sql, $bind) = select_by({ blob => "\x00\xff\x10" });
  like $sql, qr/\( DBMS_LOB\.SUBSTR\("blob", 2000, 1\) = HEXTORAW\(\?\) \)/,
    'binary: compared as RAW';
  is_deeply [ map { $_->[1] } @$bind ], ['00FF10'], '... the part sent as hex';

  my $bytes = join '', map { chr($_ % 256) } 0 .. 4499;
  ($sql, $bind) = select_by({ blob => $bytes });
  @offsets = $sql =~ /DBMS_LOB\.SUBSTR\("blob", 2000, (\d+)\) = HEXTORAW/g;
  is_deeply \@offsets, [ 1, 2001, 4001 ], 'binary: 4500 bytes are three parts of 2000';

  ($sql, $bind) = select_by({ blob => '' });
  like $sql, qr/DBMS_LOB\.GETLENGTH\("blob"\) = 0/, 'binary, empty: by length as well';
}

# an insert of no values (create({})): one column is named, set to DEFAULT
{
  my @seen;
  no warnings 'redefine';
  local *DBIO::Storage::DBI::insert = sub {
    my ($self, $source, $to_insert) = @_;
    push @seen, $to_insert;
    return { %$to_insert, id => 7 };
  };

  my $row = $storage->insert($source, {});
  is_deeply [ map { [ keys %$_ ] } @seen ], [ [ 'id' ] ],
    'an empty insert names the first column (the auto-increment one)';
  is ref $seen[0]{id}, 'SCALAR', '... as a literal';
  is ${ $seen[0]{id} }, 'DEFAULT', '... DEFAULT';
  is_deeply $row, { id => 7 }, '... the value the server made is the row\'s key';

  @seen = ();
  $row = $storage->insert($source, { id => 3 });
  is_deeply \@seen, [ { id => 3 } ], 'an insert with values is core\'s own';

  my ($sql, $bind) = $storage->_prep_for_execute('insert', $source, [ { id => \'DEFAULT' } ]);
  like $sql, qr/\AINSERT INTO "bindtype_test" \("id"\) VALUES \(DEFAULT\)/,
    'the statement is INSERT INTO t (col) VALUES (DEFAULT), not DEFAULT VALUES';
}

# populate: core's array execution, but for a LOB (DBD::Oracle cannot) row by row
{
  my (@bulk, @rows);
  no warnings qw(redefine once);
  local *DBIO::Storage::DBI::_insert_bulk = sub { shift; push @bulk, [ @_ ]; 'core' };
  local *DBIO::Oracle::Storage::insert = sub {
    my ($self, $src, $values, $opts) = @_;
    push @rows, [ { %$values }, { %{ $opts || {} } } ];
    return {};
  };
  local *DBIO::Oracle::Storage::txn_scope_guard = sub { bless {}, 'Guard' };
  local *Guard::commit = sub { 1 };

  my $data = [ [ 1, 'a' ], [ 2, 'b' ] ];
  my $plain = [ [ 1 ], [ 2 ] ];
  is $storage->_insert_bulk($source, [ 'id' ], $plain), 'core',
    'populate without a LOB column is core\'s array execution';
  is_deeply \@bulk, [ [ $source, [ 'id' ], $plain ] ], '... with its own arguments';

  is $storage->_insert_bulk($source, [ 'id', 'clob' ], $data), 2,
    'populate with a LOB column inserts the rows one by one';
  is_deeply \@rows, [
    [ { id => 1, clob => 'a' }, { no_retrieve => 1 } ],
    [ { id => 2, clob => 'b' }, { no_retrieve => 1 } ],
  ], '... as the values of the columns, nothing read back';
  is scalar @bulk, 1, '... and core\'s array execution is not run';
}

done_testing;
