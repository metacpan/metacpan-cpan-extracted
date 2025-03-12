use strict;
use warnings;

use Test::More import => [ qw( is is_deeply like note ok plan subtest ) ];
use Test::Fatal qw( dies_ok exception );

use DBI        ();
use Path::Tiny qw( cwd tempdir );

eval { require DBD::SQLite };
plan $@ eq '' ? ( tests => 16 ) : ( skip_all => 'DBD::SQLite required' );

require DBIx::Migration;

my $tempdir = tempdir( CLEANUP => 1 );
my $dsn     = 'dbi:SQLite:dbname=' . $tempdir->child( 'test.db' );
note 'dsn: ', $dsn;

my $m              = DBIx::Migration->new( dbh => DBI->connect( $dsn ) );
my $tracking_table = $m->tracking_table;

sub default_dbh_attribute_assertion {
  my ( $dbh ) = @_;
  plan tests => 3;

  ok not( $dbh->{ RaiseError } ), 'will not raise error';
  ok $dbh->{ PrintError },        'will print error';
  ok $dbh->{ AutoCommit },        'will automatically commit';
}

subtest 'default "dbh" attributes before version() call' => \&default_dbh_attribute_assertion, $m->dbh;

is $m->version, undef, '"dbix_migration" table does not exist == migrate() not called yet';

subtest 'default "dbh" attributes after version() call' => \&default_dbh_attribute_assertion, $m->dbh;

dies_ok { $m->migrate( 0 ) } '"dir" not set';
$m->dir( cwd->child( qw( t sql basic ) ) );

ok $m->migrate( 0 ), 'initially (if the "dbix_migration" table does not exist yet) a database is at version 0';

subtest 'privious migrate() has triggered the "dbix_migration" table creation' => sub {
  plan tests => 2;

  is $m->version, 0, 'check version';
  is_deeply [ $m->dbh->tables( '%', '%', '%', 'TABLE' ) ], [ "\"main\".\"$tracking_table\"" ], 'check tables';
};

sub migrate_to_version_assertion {
  my ( $version ) = @_;
  plan tests => 2;

  ok $m->migrate( $version ), 'migrate';
  is $m->version, $version, 'check version';
}

my $target_version = 1;
subtest "migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;

$target_version = 2;
subtest "migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;

$target_version = 1;
subtest "migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;

$target_version = 0;
subtest "migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;

$target_version = 2;
ok $m->migrate, 'migrate to latest version';
is $m->version, $target_version, 'check version';

$target_version = 0;
subtest "migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;

$tempdir = tempdir( CLEANUP => 1 );
$dsn     = 'dbi:SQLite:dbname=' . $tempdir->child( 'test.db' );
note 'dsn: ', $dsn;
my $m1 = DBIx::Migration->new(
  dbh => DBI->connect( $dsn ),
  dir => cwd->child( qw( t sql rollback ) )
);

subtest 'default "dbh" attributes' => \&default_dbh_attribute_assertion, $m->dbh;

dies_ok { $m1->migrate } 'second migration section is broken';
is_deeply [ $m1->dbh->tables( '%', '%', '%', 'TABLE' ) ], [ "\"main\".\"$tracking_table\"" ],
  "check tables: creation of \"$tracking_table\" wasn't rolled back";
