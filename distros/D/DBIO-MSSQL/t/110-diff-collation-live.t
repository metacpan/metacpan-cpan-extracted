use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Core ();
use DBIO::MSSQL::Deploy;
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Introspect;

# LIVE (karr k77). Counterpart of t/109-diff-collation.t (offline).
#
# Names follow the collation of the database, and a migration runs in the live
# database. Against SQL Server, in a database of its own per scenario
# (dbio_mssql_k77_<pid>_<n>, created with an explicit COLLATE, dropped at the end):
#   A. the introspect reads the collation of the database it is connected to;
#   B. case-insensitive (CI): the classes spell table, column, index and
#      foreign key names in another case than the database: the diff is empty,
#      and stays empty after a real change was applied;
#   C. case-sensitive (CS): the same spelling is another object, so the diff
#      drops and creates, the server accepts it, the second diff is empty;
#   D. CS database, classes that declare two tables that differ in case only:
#      the throwaway database the target is deployed into takes the collation
#      of the live database (the server default would refuse the second one,
#      Msg 2714), so the diff works and the upgrade runs.

my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/} ],
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/}      ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN} (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless @paths;

my $CI = 'SQL_Latin1_General_CP1_CI_AS';
my $CS = 'SQL_Latin1_General_CP1_CS_AS';

my %conn = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);
my $seq = 0;

# declared: { Table => [ [col, type_spec...], ... ] }; hand-written indexes
sub schema_class {
  my ($tag, $tables, $indexes) = @_;
  my $sc = "K77::${tag}::Schema";
  eval "package $sc; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); 1" or die $@;
  for my $t (sort keys %$tables) {
    my $rc = "$sc\::Result::$t";
    eval "package $rc; use base 'DBIO::Core'; __PACKAGE__->load_components('MSSQL::Result'); 1" or die $@;
    $rc->table($t);
    my ($cols, $fk) = @{ $tables->{$t} };
    $rc->add_columns(@$cols);
    $rc->set_primary_key($cols->[0]);
    $rc->mssql_index($_ => $indexes->{$t}{$_}) for sort keys %{ $indexes->{$t} || {} };
  }
  for my $t (sort keys %$tables) {
    my $fk = $tables->{$t}[1] or next;
    "$sc\::Result::$t"->belongs_to($fk->[0], "$sc\::Result::$fk->[1]", $fk->[2]);
  }
  for my $t (sort keys %$tables) {
    $sc->register_class($t => "$sc\::Result::$t");
  }
  return $sc;
}

sub run {
  my ($dsn, $user, $pass, $label) = @_;
  my ($dbd) = $dsn =~ /^dbi:(\w+)/i;
  my $admin = DBI->connect($dsn, $user, $pass, \%conn);

  my $scenario = sub {
    my ($name, $collation, %arg) = @_;
    my $db = sprintf 'dbio_mssql_k77_%d_%d', $$, ++$seq;
    my $dsn_db = $dsn;
    $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
      or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;
    $admin->do("CREATE DATABASE [$db] COLLATE $collation");
    my $ok = eval {
      my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
      $dbh->do($_) for @{ $arg{before} || [] };
      my $sc = schema_class("${label}_" . ($name =~ s/\W/_/gr), @{ $arg{declare} });
      my $schema = $sc->connect($dsn_db, $user, $pass, { %conn });
      my $diff = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
      $arg{first}->($dbh, $diff, $schema);
      my $again = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
      ok !$again->has_changes, "$label $name: the second diff is empty"
        or diag $again->summary . "\n" . $again->as_sql;
      $schema->storage->disconnect;
      $dbh->disconnect;
      1;
    };
    my $err = $@;
    eval {
      $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
        . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
      1;
    } or diag "could not drop $db: $@";
    die $err unless $ok;
  };

  # A. the model carries the collation
  for my $c ($CI, $CS) {
    $scenario->("model $c", $c,
      declare => [ { Foo => [ [ id => { data_type => 'integer' } ] ] } ],
      before  => [ 'CREATE TABLE Foo (id bigint NOT NULL CONSTRAINT PK_Foo PRIMARY KEY)' ],
      first   => sub {
        my ($dbh) = @_;
        my $m = DBIO::MSSQL::Introspect->new(dbh => $dbh)->model;
        is $m->{collation}{name}, $c, "$label A: the model names the collation of the database ($c)";
        is $m->{collation}{case_sensitive}, ($c eq $CS ? 1 : 0),
          "$label A: ... and whether it is case-sensitive";
      });
  }

  # B. CI: another spelling everywhere, no change; then a real change
  my $live_ddl = [
    'CREATE TABLE foo (id bigint NOT NULL CONSTRAINT pk_foo PRIMARY KEY, name nvarchar(20) NULL)',
    'CREATE TABLE bar (id bigint NOT NULL CONSTRAINT pk_bar PRIMARY KEY, foo_id bigint NULL)',
    'CREATE INDEX ix_name ON foo (name)',
    'ALTER TABLE bar ADD CONSTRAINT fk_bar_foo_id FOREIGN KEY (foo_id) REFERENCES foo (id)',
  ];
  my $declared = sub {
    my ($extra) = @_;
    return [ {
      Foo => [ [ Id => { data_type => 'integer' },
                 NAME => { data_type => 'varchar', size => 20, is_nullable => 1 },
                 ($extra ? (Extra => { data_type => 'integer', is_nullable => 1 }) : ()) ] ],
      BAR => [ [ ID => { data_type => 'integer' }, Foo_Id => { data_type => q(integer), is_nullable => 1 } ], [ q(foo), q(Foo), q(Foo_Id) ] ],
    }, { Foo => { IX_NAME => { columns => ['NAME'] } } } ];
  };
  $scenario->('CI spelling', $CI,
    declare => $declared->(0), before => $live_ddl,
    first   => sub {
      my ($dbh, $diff) = @_;
      ok !$diff->has_changes, "$label B: names in another case are no change in a CI database"
        or diag $diff->summary . "\n" . $diff->as_sql;
    });
  $scenario->('CI spelling and a real change', $CI,
    declare => $declared->(1), before => $live_ddl,
    first   => sub {
      my ($dbh, $diff, $schema) = @_;
      ok $diff->has_changes, "$label B: a new column is a change";
      my @sql = grep { length } split /\n/, $diff->as_sql;
      is scalar(@sql), 1, "$label B: and the only one" or diag $diff->as_sql;
      like $sql[0], qr/^ALTER TABLE foo ADD Extra /, "$label B: written on the live table name";
      my $ok = eval { DBIO::MSSQL::Deploy->new(schema => $schema)->apply($diff, allow_destructive => 1); 1 };
      ok $ok, "$label B: the server accepts it" or diag $@;
    });

  # C. CS: the same spelling is another object
  $scenario->('CS spelling', $CS,
    declare => [ { Foo => [ [ Id => { data_type => 'integer' } ] ] }, {} ],
    before  => [ 'CREATE TABLE foo (id bigint NOT NULL CONSTRAINT pk_foo PRIMARY KEY)' ],
    first   => sub {
      my ($dbh, $diff, $schema) = @_;
      ok $diff->has_changes, "$label C: Foo is not foo in a CS database";
      like $diff->as_sql, qr/DROP TABLE foo;/, "$label C: foo is dropped";
      like $diff->as_sql, qr/CREATE TABLE Foo/, "$label C: Foo is created";
      my $ok = eval { DBIO::MSSQL::Deploy->new(schema => $schema)->apply($diff, allow_destructive => 1); 1 };
      ok $ok, "$label C: the server accepts it" or diag $@;
    });

  # D. CS: two tables that differ in case only; the throwaway database must be CS too
  $scenario->('CS two tables', $CS,
    declare => [ { Foo => [ [ Id => { data_type => 'integer' } ] ],
                   foo => [ [ id => { data_type => 'integer' } ] ] }, {} ],
    before  => [ 'CREATE TABLE Foo (Id bigint NOT NULL CONSTRAINT PK_Foo PRIMARY KEY)' ],
    first   => sub {
      my ($dbh, $diff, $schema) = @_;
      ok $diff->has_changes, "$label D: the diff is made (the throwaway database takes the live collation)";
      like $diff->as_sql, qr/CREATE TABLE foo \(/, "$label D: foo is created next to Foo";
      is scalar(() = $diff->as_sql =~ /CREATE TABLE Foo/g), 0, "$label D: Foo exists and stays";
      my $ok = eval { DBIO::MSSQL::Deploy->new(schema => $schema)->apply($diff, allow_destructive => 1); 1 };
      ok $ok, "$label D: the server accepts it" or diag $@;
    });

  $admin->disconnect;
}

for my $p (@paths) {
  my ($dbd) = $p->[0] =~ /^dbi:(\w+)/i;
  run(@$p, $dbd);
}

my @left = do {
  my $admin = DBI->connect(@{ $paths[0] }, \%conn);
  map { $_->[0] } @{ $admin->selectall_arrayref(
    q{SELECT name FROM sys.databases WHERE name LIKE 'dbio[_]mssql[_]k77[_]%'}) };
};
is_deeply \@left, [], 'no database of this test is left behind';

done_testing;
