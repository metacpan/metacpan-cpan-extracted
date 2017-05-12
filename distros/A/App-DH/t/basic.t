use strict;
use warnings;

use Test::More;
use Test::Requires { 'DBD::SQLite' => 0 };
use Test::TempDir::Tiny qw( tempdir );
use DBI;

use App::DH;

my $d  = tempdir();
my $db = "$d/test.sqlite3";

my $dbh = DBI->connect( 'dbi:SQLite:' . $db );

subtest "create db" => sub {
  run_app( '--target' => 1, 'install', );

  is max_version() => 1, "db created";
};

subtest "upgrade to v2" => sub {
  run_app( '--target' => 2, 'upgrade', );

  is max_version() => 2, "db upgraded to v2";
};

subtest "upgrade to latest" => sub {
  run_app( 'upgrade', );

  is max_version() => 3, "db upgraded to v3";
};

done_testing;

### utility functions

sub max_version {
  my $sth = $dbh->prepare('SELECT max(id) FROM dbix_class_deploymenthandler_versions');
  $sth->execute;
  $sth->fetchrow;
}

sub run_app {
  @ARGV = (
    '--connection_name' => 'dbi:SQLite:' . $db,
    '--schema'          => 'MySchema',
    '--script_dir'      => 't/corpus/ddl',
    '--include'         => 't/corpus/lib',
    @_,
  );
  App::DH->new_with_options->run;
}

