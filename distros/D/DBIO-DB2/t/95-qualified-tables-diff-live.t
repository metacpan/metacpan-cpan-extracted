use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k57), the counterpart of t/94: tables named schema.table through
# the public DBIO::DB2::Deploy API, in schemas of their own (dbio_k57q_<pid> and
# dbio_k57r_<pid>) next to a table of the current schema:
#
#   - install makes the schema and the table; the diff against the same
#     declaration is empty
#   - upgrade adds a column and an index to a table of the schema and creates a
#     new table there; a table of that schema the declaration never named is
#     not touched; a table the declaration stops naming is not dropped either
#   - a table in a schema that does not exist yet is created, schema included
#   - every follow-up diff is empty; the schemas are dropped again at the end

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

use DBIO::Schema ();
use DBIO::Core ();
use DBIO::DB2::Deploy;

my $Q    = "dbio_k57q_$$";
my $R    = "dbio_k57r_$$";
my $MAIN = "dbio_k57m_$$";
my $seq  = 0;

# a schema class declaring the given tables: name => [ columns ], plus options
sub schema_for {
  my (@tables) = @_;
  my $base = 'DBIO::Test::K57Q' . ++$seq;
  no strict 'refs';
  @{"${base}::Schema::ISA"} = ('DBIO::Schema');
  "${base}::Schema"->load_components('DB2');
  my $i = 0;
  for my $t (@tables) {
    my ($name, $cols, $indexes) = @$t;
    my $class = "${base}::R" . ++$i;
    @{"${class}::ISA"} = ('DBIO::Core');
    $class->table($name);
    $class->add_columns(id => { data_type => 'integer' },
      map { ($_ => { data_type => 'varchar', size => 20, is_nullable => 1 }) } @$cols);
    $class->set_primary_key('id');
    $class->result_source_instance->add_index_declaration($_) for @{ $indexes || [] };
    "${base}::Schema"->register_class("T$i" => $class);
  }
  return "${base}::Schema"->connect($dsn, $user, $pass);
}

my $first = schema_for([ $MAIN, ['n'] ], [ "$Q.t1", ['a'] ]);
my $dbh = eval { $first->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $COMPARE = "DBIO_TEST_$$";
sub cleanup {
  local $dbh->{PrintError} = 0;
  for my $s ($Q, $R) {
    my $tabs = eval { $dbh->selectcol_arrayref('SELECT tabname FROM syscat.tables WHERE tabschema = ?', undef, $s) } || [];
    eval { $dbh->do(qq{DROP TABLE "$s"."$_"}) } for @$tabs;
    eval { $dbh->do(qq{DROP SCHEMA "$s" RESTRICT}) };
  }
  eval { $dbh->do(qq{DROP TABLE "$MAIN"}) };
}
END { cleanup() if $dbh && $dbh->{Active} }

sub deploy_of { DBIO::DB2::Deploy->new(schema => $_[0]) }
sub columns_of {
  my ($s, $t) = @_;
  return join ',', @{ $dbh->selectcol_arrayref(
    'SELECT colname FROM syscat.columns WHERE tabschema = ? AND tabname = ? ORDER BY colno', undef, $s, $t) };
}
sub tables_of { join ',', @{ $dbh->selectcol_arrayref('SELECT tabname FROM syscat.tables WHERE tabschema = ? ORDER BY tabname', undef, $_[0]) } }
sub indexes_of {
  join ',', @{ $dbh->selectcol_arrayref(q{SELECT indname FROM syscat.indexes WHERE tabschema = ? AND tabname = ? AND uniquerule <> 'P' ORDER BY indname}, undef, @_) };
}
sub empty_diff {
  my ($schema, $what) = @_;
  my $diff = eval { deploy_of($schema)->diff } or return fail("$what: diff died: $@");
  is scalar(@{ $diff->operations }), 0, $what or diag $diff->as_sql;
}

cleanup();

# --- install ------------------------------------------------------------------------
lives_ok { deploy_of($first)->install } 'install makes the schema and its table';
is tables_of($Q), 't1', '... the table is in its schema';
ok !scalar($dbh->selectrow_array('SELECT 1 FROM syscat.tables WHERE tabschema = CURRENT SCHEMA AND tabname = ?', undef, 't1')),
  '... and not in the current one';
empty_diff($first, 'the diff against the same declaration is empty');

# a table of that schema the declaration never named
$dbh->do(qq{CREATE TABLE "$Q"."foreign_x" ("id" INTEGER NOT NULL)});
$dbh->do(qq{INSERT INTO "$Q"."t1" ("id", "a") VALUES (1, 'kept')});
empty_diff($first, 'a foreign table in the schema is not part of the comparison');

# --- upgrade: column, index, new table ------------------------------------------------
my $second = schema_for([ $MAIN, ['n'] ],
  [ "$Q.t1", ['a', 'b'], [ { name => 'k57_t1_a', columns => ['a'] } ] ],
  [ "$Q.t2", ['c'] ]);
{
  my $diff = deploy_of($second)->diff;
  like $diff->as_sql, qr/ALTER TABLE "\Q$Q\E"\."t1" ADD COLUMN "b"/, 'the diff adds the column to the table in its schema';
  like $diff->as_sql, qr/CREATE TABLE "\Q$Q\E"\."t2"/, '... and creates the new table there';
}
lives_ok { deploy_of($second)->upgrade } 'upgrade';
is columns_of($Q, 't1'), 'id,a,b', 'the column is there';
is tables_of($Q), 'foreign_x,t1,t2', 'the new table is there, the foreign one untouched';
is indexes_of($Q, 't1'), 'k57_t1_a', 'the index is in the schema of its table';
is_deeply $dbh->selectall_arrayref(qq{SELECT "id", "a" FROM "$Q"."t1"}), [ [1, 'kept'] ], 'the row is kept';
empty_diff($second, 'the follow-up diff is empty');

# --- the declaration no longer names a table ----------------------------------------------
# Only the declared tables of a schema are compared: one the declaration stopped
# naming is indistinguishable from a table of someone else, and is left alone.
my $third = schema_for([ $MAIN, ['n'] ], [ "$Q.t1", ['a', 'b'], [ { name => 'k57_t1_a', columns => ['a'] } ] ]);
lives_ok { deploy_of($third)->upgrade } 'upgrade, the declaration no longer names t2';
is tables_of($Q), 'foreign_x,t1,t2', '... t2 and the foreign table stay';
empty_diff($third, 'the follow-up diff is empty');

# --- a schema that does not exist yet ----------------------------------------------------
my $fourth = schema_for([ $MAIN, ['n'] ], [ "$Q.t1", ['a', 'b'], [ { name => 'k57_t1_a', columns => ['a'] } ] ],
  [ "$R.u", ['x'] ]);
ok !scalar($dbh->selectrow_array('SELECT 1 FROM syscat.schemata WHERE schemaname = ?', undef, $R)), 'the schema is not there yet';
lives_ok { deploy_of($fourth)->upgrade } 'upgrade creates a table in a schema that is missing';
is tables_of($R), 'u', '... schema and table are there';
empty_diff($fourth, 'the follow-up diff is empty');

# --- the current schema is not disturbed ---------------------------------------------------
is columns_of(scalar($dbh->selectrow_array('VALUES RTRIM(CURRENT SCHEMA)')), $MAIN), 'id,n', 'the table of the current schema is as declared';

done_testing;
