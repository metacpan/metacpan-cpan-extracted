# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

eval 'require DBI'
  or plan skip_all => 'DBI required for these tests';

use DBIx::TableLoader;

# These tests are fragile as the databases/drivers could change things.
# This script was only to make sure the code in the module was correct...
# In reality the ones we want often aren't mapped anyway.

my @types = (
  DBI::SQL_LONGVARCHAR(),
  DBI::SQL_VARCHAR(),
  # pick something that appears to be mapped in the drivers
  DBI::SQL_BOOLEAN(),
  DBI::SQL_INTEGER(),
);

my @tests = (
  [SQLite => 'dbname=:memory:',          [undef,  undef,     undef,   undef]],
  [Pg     => 'host=localhost;port=5432', [undef,  'text',    'bool', 'int4']],
  [PgPP   => 'host=localhost;port=5432', [undef,  undef,     undef,   undef]],
  [mysql  => 'host=127.0.0.1;port=3306', ['text', 'varchar', undef,   'integer']],
);

foreach my $test ( @tests ){
  my ($dbd, $dsn, $exp) = @$test;

  my %e = (
    dsn => "TEST_DBI_\U${dbd}_DSN",
    userpass => "TEST_DBI_\U${dbd}_USERPASS"
  );

  subtest $dbd => sub {
    eval "require DBD::$dbd";
    plan skip_all => "DBD::$dbd required for testing data type"
      if $@;

    $dsn = $ENV{$e{dsn}}
      if $ENV{$e{dsn}};

    my ($user, $pass) = split(/:/, $ENV{$e{userpass}} || '');

    my %attr = (RaiseError => 0, PrintWarn => 0, PrintError => 0);
    my $dbh = DBI->connect("dbi:$dbd:$dsn", $user, $pass, \%attr)
      or plan skip_all => "DBI connection failed for $dbd.  " .
        "Set $e{dsn} and/or $e{userpass} to test with $dbd";
    my $loader = new_ok('DBIx::TableLoader', [dbh => $dbh, columns => ['test']]);

    foreach my $i ( 0 .. $#types ){
      is($loader->_data_type_from_driver($types[$i]), $$exp[$i], 'db data type');
    }
  };
}

done_testing;
