use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::MSSQL::DDL;
use lib 't/lib';
use K71Fixtures qw(schema_for);

# LIVE (karr k71). Counterpart of t/96 (offline, string defaults).
#
# Measured 2026-10-20 (MSSQL 2022): the server takes a string literal that
# cannot be converted as the DEFAULT of a datetime/date/time/datetime2/int/bit
# column at CREATE TABLE and fails only at the first INSERT (Msg 22007 for
# dates, 22018 for int/bit): 'create_ok_insert_fails'. A convertible one
# ('2020-01-01' on datetime, '7' on int) runs. So the driver refuses the
# unconvertible ones itself (DBIO::MSSQL::DDL::_default_literal): loud at
# deploy instead of late at the INSERT. This file pins both: what the server
# does by hand, and that install_ddl refuses exactly those and lets the
# convertible ones through.
#
# One database of its own, _dbio_k71d_<pid>_1, dropped at the end.

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
my $db = sprintf '_dbio_k71d_%d_1', $$;
my $dsn_db = $dsn;
$dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
  or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;

$admin->do("CREATE DATABASE [$db]");
my $ok = eval {
  my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
  my $i = 0;

  # [ type, literal as the DDL writes it, expectation ]
  my @cases = (
    [ 'datetime',  q{N'GETDATE()'},  'create_ok_insert_fails' ],
    [ 'datetime',  q{'GETDATE()'},   'create_ok_insert_fails' ],
    [ 'datetime',  q{'abc'},         'create_ok_insert_fails' ],
    [ 'date',      q{'abc'},         'create_ok_insert_fails' ],
    [ 'time',      q{'abc'},         'create_ok_insert_fails' ],
    [ 'datetime2', q{'abc'},         'create_ok_insert_fails' ],
    [ 'int',       q{'abc'},         'create_ok_insert_fails' ],
    [ 'int',       q{'GETDATE()'},   'create_ok_insert_fails' ],
    [ 'bit',       q{'abc'},         'create_ok_insert_fails' ],
    [ 'datetime',  q{'2020-01-01'},  'create_ok_insert_ok' ],
    [ 'int',       q{'7'},           'create_ok_insert_ok' ],
  );

  for my $c (@cases) {
    my ($type, $lit, $expect) = @$c;
    my $t = 'k71d_' . ++$i;
    my $create = eval { $dbh->do("CREATE TABLE $t (id int NOT NULL, v $type DEFAULT $lit)"); 1 };
    my $cerr = $create ? '' : $@;
    my ($insert, $ierr) = (undef, '');
    if ($create) {
      $insert = eval { $dbh->do("INSERT INTO $t (id) VALUES (1)"); 1 };
      $ierr = $insert ? '' : $@;
    }
    my $got = !$create ? 'create_fails'
            : $insert  ? 'create_ok_insert_ok'
            :            'create_ok_insert_fails';
    diag sprintf '%-9s DEFAULT %-16s -> %s%s', $type, $lit, $got,
      $cerr ? " ($cerr)" =~ s/\s+/ /gr : $ierr ? " ($ierr)" =~ s/\s+/ /gr : '';
    is $got, $expect, "$type DEFAULT $lit: server: $expect";

    # the driver: refuses what the server only fails at the INSERT
    (my $dv = $lit) =~ s/\AN?'(.*)'\z/$1/;
    my $c = schema_for(['dt' . $i, undef, { v => { data_type => $type, default_value => $dv, is_nullable => 1 } }]);
    my $ddl = eval { DBIO::MSSQL::DDL->install_ddl($c) };
    my $e = $@;
    if ($expect eq 'create_ok_insert_ok') {
      ok defined $ddl, "install_ddl lets $type DEFAULT '$dv' through";
    } else {
      ok !defined $ddl && ref $e && $e->isa('DBIO::Exception') && "$e" =~ /refused/,
        "install_ddl refuses $type DEFAULT '$dv' with DBIO::Exception";
    }
  }
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
