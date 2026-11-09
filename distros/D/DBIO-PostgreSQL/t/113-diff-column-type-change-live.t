use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k121, point U3: the type of a column changes between two
# enum or composite types, or between one of them and text.
#
# WHY it exists: t/113-diff-column-type-change.t pins the statements the diff
# writes; only a server says that it takes them, that the rows come through
# and that the database is the target's afterwards. Before the fix the diff
# wrote ALTER COLUMN ... TYPE without USING (and with the default still on the
# column), so enum to enum, composite to composite and text to either died
# with 'column "v" cannot be cast automatically to type ...'.
#
# For every case, in a private database (karr k81): the old column is made by
# hand with rows in it, the target is diffed against it, and then
#
#  1. the upgrade runs (or the diff is refused, and nothing changes);
#  2. the rows hold what they held;
#  3. a second diff finds nothing to do.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my $n = 0;

{
  package T113L::Pub;
  use base 'DBIO::PostgreSQL::PgSchema';
  __PACKAGE__->pg_enum(e_new => [qw( a b )]);
  __PACKAGE__->pg_type(c_new   => { x => 'integer', y => 'text' });
  __PACKAGE__->pg_type(c_other => { x => 'integer' });
}

# The schema class whose table t has the column v as $column.
sub target {
  my ($column, $default) = @_;
  my $result = 'T113L::Result::R' . ++$n;
  eval qq{
    package $result;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    1;
  } or die $@;
  $result->table('t');
  my %col = ref $column ? %$column : (data_type => $column);
  $col{is_nullable} = 1;
  $col{default_value} = \$default if defined $default;
  $result->add_columns(id => { data_type => 'bigint', is_nullable => 0 }, v => \%col);
  $result->set_primary_key('id');

  my $class = 'T113L::Schema::S' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->pg_schemas('public');
  $class->pg_schema_class(public => 'T113L::Pub');
  $class->register_class(T => $result);
  return $class;
}

sub enum   { +{ data_type => 'enum', pg_enum_type => 'e_new' } }
sub comp   { +{ data_type => 'composite', pg_type_name => $_[0] } }

sub values_of {
  my ($dbh) = @_;
  return $dbh->selectcol_arrayref('SELECT v::text FROM t ORDER BY id');
}

sub type_of {
  my ($dbh) = @_;
  return $dbh->selectrow_array(q{SELECT format_type(atttypid, atttypmod)
    FROM pg_attribute WHERE attrelid = 't'::regclass AND attname = 'v'});
}

# $old: the old column definition; @rows: the literals of v. Returns the
# schema (connected) and the diff, or undef and the error.
sub prepared {
  my ($tag, $old, $to, @rows) = @_;
  my @db  = PrivatePgDatabase->create($tag);
  my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
  $dbh->do($_) for
    q{CREATE TYPE e_old AS ENUM ('a', 'b')},
    q{CREATE TYPE c_old AS (x integer, y text)},
    "CREATE TABLE t (id bigint PRIMARY KEY, v $old)";
  my $i = 0;
  $dbh->do('INSERT INTO t VALUES (' . ++$i . ", $_)") for @rows;
  $dbh->disconnect;

  my $schema = $to->connect(@db, @CONNECT);
  my $diff = eval { $schema->pg_deploy->diff };
  return ($schema, $diff, $@);
}

sub settled {
  my ($label, $schema) = @_;
  my $again = eval { $schema->pg_deploy->diff };
  ok($again && !$again->has_changes, "$label: a second diff finds nothing to do")
    or diag $again ? $again->as_sql : $@;
}

# A case that must run: the type becomes $type, the rows read $want.
sub runs {
  my (%c) = @_;
  my $label = $c{label};
  my ($schema, $diff, $error) = prepared($c{tag}, $c{old}, $c{to}, @{ $c{rows} });
  ok($diff, "$label: the diff is built") or diag $error;
  SKIP: {
    skip "$label: no diff", 5 unless $diff;
    like($diff->as_sql, $c{sql}, "$label: and says what it should") if $c{sql};
    # a change to or from an enum or composite type is lossy, and the old type is dropped
    ok(eval { $schema->pg_deploy->apply($diff, allow_destructive => 1); 1 }, "$label: the upgrade runs") or diag $@;
    my $dbh = $schema->storage->dbh;
    is(scalar type_of($dbh), $c{type}, "$label: the column has the target's type");
    is_deeply(values_of($dbh), $c{want}, "$label: and the rows hold what they held");
    $c{after}->($dbh) if $c{after};
    settled($label, $schema);
  }
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# enum -> another enum
# ---------------------------------------------------------------------------
runs(label => 'enum to enum', tag => 't113ee', old => 'e_old', to => target(enum()),
  rows => [ q{'a'}, q{'b'}, 'NULL' ], want => [ 'a', 'b', undef ], type => 'e_new',
  sql => qr/TYPE public\.e_new USING v::text::public\.e_new/);

runs(label => 'enum to enum with a default', tag => 't113eed', old => q{e_old DEFAULT 'b'},
  to => target(enum(), q{'b'::e_new}),
  rows => [ q{'a'} ], want => ['a'], type => 'e_new',
  after => sub {
    my ($dbh) = @_;
    $dbh->do('INSERT INTO t (id) VALUES (2)');
    is_deeply(values_of($dbh), [ 'a', 'b' ], 'enum to enum with a default: the default works on the new type');
  });

# ---------------------------------------------------------------------------
# enum <-> text
# ---------------------------------------------------------------------------
runs(label => 'enum to text', tag => 't113et', old => 'e_old', to => target('text'),
  rows => [ q{'a'}, q{'b'} ], want => [ 'a', 'b' ], type => 'text');

runs(label => 'enum to text with a default', tag => 't113etd', old => q{e_old DEFAULT 'b'},
  to => target('text', q{'b'::text}),
  rows => [ q{'a'} ], want => ['a'], type => 'text');

runs(label => 'text to enum with a default', tag => 't113ted', old => q{text DEFAULT 'b'},
  to => target(enum(), q{'b'::e_new}),
  rows => [ q{'a'} ], want => ['a'], type => 'e_new',
  after => sub {
    my ($dbh) = @_;
    $dbh->do('INSERT INTO t (id) VALUES (2)');
    is_deeply(values_of($dbh), [ 'a', 'b' ], 'text to enum with a default: the default works on the new type');
  });

runs(label => 'text to enum', tag => 't113te', old => 'text', to => target(enum()),
  rows => [ q{'a'}, q{'b'} ], want => [ 'a', 'b' ], type => 'e_new',
  sql => qr/TYPE public\.e_new USING v::text::public\.e_new/);

# ---------------------------------------------------------------------------
# composite -> composite of the same attributes, and composite <-> text
# ---------------------------------------------------------------------------
runs(label => 'composite to composite', tag => 't113cc', old => 'c_old', to => target(comp('c_new')),
  rows => [ q{'(1,z)'}, q{'(2,"a b")'}, 'NULL' ], want => [ '(1,z)', '(2,"a b")', undef ], type => 'c_new',
  sql => qr/TYPE public\.c_new USING v::text::public\.c_new/);

runs(label => 'composite to text', tag => 't113ct', old => 'c_old', to => target('text'),
  rows => [ q{'(1,z)'} ], want => ['(1,z)'], type => 'text');

runs(label => 'text to composite', tag => 't113tc', old => 'text', to => target(comp('c_new')),
  rows => [ q{'(1,z)'} ], want => ['(1,z)'], type => 'c_new',
  sql => qr/TYPE public\.c_new USING v::text::public\.c_new/);

# ---------------------------------------------------------------------------
# composite -> composite of other attributes: refused, nothing is changed
# ---------------------------------------------------------------------------
{
  my $label = 'composite to a composite of other attributes';
  my ($schema, $diff, $error) = prepared('t113cx', 'c_old', target(comp('c_other')), q{'(1,z)'});
  ok(!$diff, "$label: the diff dies");
  like($error, qr/\Arefusing to diff: column public\.t\.v changes from composite type public\.c_old to public\.c_other,/,
    "$label: with a refusal that names both types");
  my $dbh = $schema->storage->dbh;
  is(scalar type_of($dbh), 'c_old', "$label: the column is as it was");
  is_deeply(values_of($dbh), ['(1,z)'], "$label: and so are the rows");
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# text that is no value of the enum: the server refuses, the rows stay
# ---------------------------------------------------------------------------
{
  my $label = 'text that is no label of the enum';
  my ($schema, $diff, $error) = prepared('t113bad', 'text', target(enum()), q{'a'}, q{'zzz'});
  ok($diff, "$label: the diff is built") or diag $error;
  SKIP: {
    skip "$label: no diff", 3 unless $diff;
    # released, so that it is the server that refuses
    ok(!eval { $schema->pg_deploy->apply($diff, allow_destructive => 1); 1 }, "$label: the upgrade fails");
    like($@, qr/invalid input value for enum e_new: "\*\*\*"/, "$label: with the server's reason"); # the row value is masked, the enum stays
    my $dbh = $schema->storage->dbh;
    is_deeply([ scalar type_of($dbh), @{ values_of($dbh) } ], [ 'text', 'a', 'zzz' ],
      "$label: the column and its rows are as they were");
  }
  $schema->storage->disconnect;
}

done_testing;
