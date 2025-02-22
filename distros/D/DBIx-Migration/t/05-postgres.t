use strict;
use warnings;

use Path::Tiny qw( cwd );

use lib cwd->child( qw( t lib ) )->stringify;

use Test::More import => [ qw( is note ok plan subtest ) ];
use Test::Fatal qw( dies_ok );
use Test::PgTAP import => [ qw( tables_are ) ];

eval { require Test::PostgreSQL };
plan skip_all => 'Test::PostgreSQL required' unless $@ eq '';

my $pgsql = eval { Test::PostgreSQL->new } or do {
  no warnings 'once';
  plan skip_all => $Test::PostgreSQL::errstr;
};
note 'dsn: ', $pgsql->dsn;
local $Test::PgTAP::Dbh = DBI->connect( $pgsql->dsn );

plan tests => 14;

require DBIx::Migration;

my $m = DBIx::Migration->new( dsn => $pgsql->dsn );

is $m->version, undef, '"dbix_migration" table does not exist == migrate() not called yet';
ok $m->dbh->{ Active }, '"dbh" should be an active database handle';

dies_ok { $m->migrate( 0 ) } '"dir" not set';
$m->dir( cwd->child( qw( t sql basic ) ) );

ok $m->migrate( 0 ), 'initially (if the "dbix_migration" table does not exist yet) a database is at version 0';

subtest 'privious migrate() has triggered the "dbix_migration" table creation' => sub {
  plan tests => 2;

  is $m->version, 0, 'check version';
  tables_are [ 'public.dbix_migration' ], 'check tables';
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

my $m1 = DBIx::Migration->new( dbh => $m->dbh, dir => $m->dir );

is $m1->version, 0, '"dbix_migration" table exists and its "version" value is 0';

ok !$m1->migrate( 3 ), 'sql up migration file is missing';
