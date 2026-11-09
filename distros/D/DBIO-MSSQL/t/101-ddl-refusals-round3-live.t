use strict;
use warnings;
use Test::More;
use DBI;

BEGIN { $ENV{CAG_ILLEGAL_ACCESSOR_NAME_OK} = 1 }

use DBIO::Test::Schema;
use DBIO::MSSQL::DDL;
use lib 't/lib';
use K71Fixtures qw(schema_for);

# LIVE (karr k71, review round 3; written 2026-10-19, NOT yet run: no live
# runs that day). Counterpart of t/100 (offline).
#
# WHAT is asked of the server, and what we expect:
#  1. Msg 2714: a unique constraint named like a table fails at the server
#     (by hand). The driver refuses such a schema before: no server error.
#     (Core's Artist declared it until core k351.)
#     EXPECTED: by hand the CREATE TABLE fails with 2714 ("There is already
#     an object named"); install_ddl dies with "refus" and 2714, nothing sent.
#  2. DEFAULT 'true' on a bit column, written by the driver as DEFAULT 1:
#     the DDL runs and an INSERT without the column reads 1 (and 0 for
#     'false'). EXPECTED: runs, 1 and 0.
#  3. '1e5' as the default of an int: by hand the server takes it at CREATE
#     TABLE and fails at the first INSERT (Msg 245). The driver refuses first.
#     EXPECTED: by hand create ok, insert fails; install_ddl refuses.
#  4. MEASURED 2026-10-20: ALTER COLUMN that changes only the nullability
#     (NULL -> NOT NULL) works on a FOREIGN KEY column and FAILS on a column of
#     a UNIQUE constraint ("The object 'UQ_chi_code' is dependent on column
#     'code'"), as it does for an index. DBIO::MSSQL::Diff drops and re-creates
#     such a constraint around the ALTER: t/102 (offline), t/93 (live, end to
#     end, second diff empty).
#
# One database of its own, _dbio_k71e_<pid>_1, dropped at the end.

my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/} ],
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/}      ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN} (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless @paths;
my ($dsn, $user, $pass) = @{ $paths[0] };
my ($dbd) = $dsn =~ /^dbi:(\w+)/i;

my %conn = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);
my $admin = DBI->connect($dsn, $user, $pass, \%conn);
my $db = sprintf '_dbio_k71e_%d_1', $$;
my $dsn_db = $dsn;
$dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
  or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;

sub one_line { (my $m = $_[0] // '') =~ s/\s+/ /g; $m }

$admin->do("CREATE DATABASE [$db]");
my $ok = eval {
  my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);

  # ---- 1. constraint named like a table
  ok !eval { $dbh->do('CREATE TABLE artist (artistid int NOT NULL, CONSTRAINT artist UNIQUE (artistid))'); 1 },
    'by hand: a unique constraint named like its table fails at the server';
  like $@, qr/\b2714\b|already an object named/i, '... with Msg 2714'
    or diag one_line $@;
  # core's Artist no longer declares a unique constraint named like its table
  # (artist_artistid since core k351), so the core test schema is not refused;
  # the refusal is held by a schema that does declare one.
  my $named = schema_for(
    ['artist', undef, undef, sub { $_[0]->add_unique_constraint(artist => ['id']) }],
  );
  ok !eval { DBIO::MSSQL::DDL->install_ddl($named); 1 },
    'install_ddl refuses a unique constraint named like its table';
  like "$@", qr/refus.*Msg 2714/s, '... with the driver\'s text, before the server';

  # ---- 2. DEFAULT 'true' / 'false' on bit
  my $c = schema_for(['flags', undef, {
    yes => { data_type => 'bit', default_value => 'true' },
    no  => { data_type => 'boolean', default_value => 'FALSE' },
  }]);
  my $ddl = DBIO::MSSQL::DDL->install_ddl($c);
  $dbh->do($_) for grep { /\S/ } split /\n\n/, $ddl;
  $dbh->do('INSERT INTO flags (id) VALUES (1)');
  my ($yes, $no) = $dbh->selectrow_array('SELECT yes, no FROM flags WHERE id = 1');
  is $yes, 1, "DEFAULT 'true' on bit reads 1";
  is $no,  0, "DEFAULT 'FALSE' on boolean reads 0";

  # ---- 3. '1e5' on an int
  # measured 2026-10-20 (as t/99): the server takes the literal at CREATE TABLE
  # and fails only at the first INSERT
  ok eval { $dbh->do(q{CREATE TABLE e5 (id int NOT NULL, v int DEFAULT '1e5')}); 1 },
    q{by hand: DEFAULT '1e5' on an int is taken at CREATE TABLE};
  ok !eval { $dbh->do('INSERT INTO e5 (id) VALUES (1)'); 1 },
    q{... and fails at the first INSERT (conversion)};
  like $@, qr/Conversion failed|\b245\b|22018/, '... with the conversion error'
    or diag one_line $@;
  my $c5 = schema_for(['e5b', undef, { v => { data_type => 'int', default_value => '1e5', is_nullable => 1 } }]);
  ok !eval { DBIO::MSSQL::DDL->install_ddl($c5); 1 }, "install_ddl refuses '1e5' on an int first";
  like "$@", qr/refus/, '... saying refus';

  # ---- 4. ALTER COLUMN of the nullability only, on FK and UQ columns
  $dbh->do('CREATE TABLE par (id int NOT NULL PRIMARY KEY)');
  $dbh->do('CREATE TABLE chi (id int NOT NULL PRIMARY KEY, par_id int NULL, code int NULL, '
    . 'CONSTRAINT FK_chi_par_id FOREIGN KEY (par_id) REFERENCES par (id), '
    . 'CONSTRAINT UQ_chi_code UNIQUE (code))');
  my $r = eval { $dbh->do('ALTER TABLE chi ALTER COLUMN par_id int NOT NULL'); 1 };
  ok $r, 'nullability-only ALTER COLUMN on a foreign key column works' or diag one_line $@;
  $r = eval { $dbh->do('ALTER TABLE chi ALTER COLUMN code int NOT NULL'); 1 };
  ok !$r, 'nullability-only ALTER COLUMN on a unique constraint column fails at the server';
  like $@, qr/UQ_chi_code.*dependent on column/s, '... because the constraint depends on the column';
  1;
};
my $err = $@;
eval {
  $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
    . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
  1;
} or diag "could not drop $db: $@";
die $err unless $ok;

done_testing;
