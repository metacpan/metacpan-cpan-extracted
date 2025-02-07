use strict;
use warnings;

#https://estuary.dev/postgresql-triggers/

use File::Spec::Functions qw( catdir curdir );

use lib catdir( curdir, qw( t lib ) );

use Test::More import => [ qw( is note ok plan subtest ) ];
use Test::PgTAP import => [ qw( tables_are ) ];

use DBI                     qw();
use DBI::Const::GetInfoType qw( %GetInfoType );

eval { require Test::PostgreSQL };
plan skip_all => 'Test::PostgresSQL required' unless $@ eq '';

my $pgsql = eval { Test::PostgreSQL->new() } or do {
  no warnings 'once';
  plan skip_all => $Test::PostgreSQL::errstr;
};
note 'dsn: ', $pgsql->dsn;
local $Test::PgTAP::Dbh = DBI->connect( $pgsql->dsn );

plan tests => 3;

require DBIx::Migration;

my $m = DBIx::Migration->new( { dsn => $pgsql->dsn, dir => catdir( curdir, qw( t sql trigger ) ), debug => 0 } );

sub migrate_to_version_assertion {
  my ( $version ) = @_;
  plan tests => 2;

  ok $m->migrate( $version ), 'Migrate';
  is $m->version, $version, 'Check version';
}

my $target_version = 1;
subtest "Migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;

# these are the same assertions that should test tables_are
tables_are 'public', [ qw( dbix_migration products ) ], 'Check tables';
tables_are [ qw( dbix_migration products ) ];
