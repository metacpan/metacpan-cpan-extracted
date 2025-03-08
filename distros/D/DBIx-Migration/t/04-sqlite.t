use strict;
use warnings;

use Test::More import => [ qw( is is_deeply like note ok plan subtest ) ];
use Test::Fatal qw( dies_ok exception );

use Path::Tiny qw( cwd tempdir );

eval { require DBD::SQLite };
plan $@ eq '' ? ( tests => 17 ) : ( skip_all => 'DBD::SQLite required' );

require DBIx::Migration;

subtest 'wrong dsn' => sub {
  plan tests => 2;

  like
    exception { DBIx::Migration->new( dsn => 'dbi:SQLite:dbname=' . cwd->child( qw( t missing test.db ) ) )->version },
    qr/unable to open database file/, 'calling version() throws exception';

  like exception {
    DBIx::Migration->new(
      dsn => 'dbi:SQLite:dbname=' . cwd->child( qw( t missing test.db ) ),
      dir => cwd->child( qw( t sql basic ) )
    )->migrate
  }, qr/unable to open database file/, 'calling migrate() throws exception';
};

my $tempdir = tempdir( CLEANUP => 1 );
my $m       = DBIx::Migration->new( tracking_table => 'dbix-migration', dsn => 'dbi:SQLite:dbname=' . $tempdir->child( 'test.db' ) );
note 'dsn: ', $m->dsn;

my $tracking_table = $m->tracking_table;
is $m->version, undef, "\"$tracking_table\" table does not exist == migrate() not called yet";
ok $m->dbh->{ Active }, '"dbh" should be an active database handle';

dies_ok { $m->migrate( 0 ) } '"dir" not set';
$m->dir( cwd->child( qw( t sql basic ) ) );

ok $m->migrate( 0 ),
  "initially (if the \"$tracking_table\" table does not exist yet) a database is at version 0";

subtest "privious migrate() has triggered the \"$tracking_table\" table creation" => sub {
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

my $m1 = DBIx::Migration->new( tracking_table => $m->tracking_table, dbh => $m->dbh, dir => $m->dir );

is $m1->version, 0, "\"$tracking_table\" table exists and its \"version\" value is 0";

ok !$m1->migrate( 3 ), 'return false because sql up migration file is missing';

$tempdir = tempdir( CLEANUP => 1 );
my $m2 = DBIx::Migration->new(
  dsn => 'dbi:SQLite:dbname=' . $tempdir->child( 'test.db' ),
  dir => cwd->child( qw( t sql rollback ) )
);

$tracking_table = $m2->tracking_table;
dies_ok { $m2->migrate } 'second migration section is broken';
is_deeply [ $m2->dbh->tables( '%', '%', '%', 'TABLE' ) ], [],
  "check tables: creation of \"$tracking_table\" table was rolled back too!";
