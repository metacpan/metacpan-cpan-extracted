use strict;
use warnings;

use Test::More;

use DBIx::Migration;

eval { require Test::PostgreSQL };
plan skip_all => 'Test::PostgresSQL required' unless $@ eq '';

my $pgsql = eval { Test::PostgreSQL->new() } or do {
  no warnings 'once';
  plan skip_all => $Test::PostgreSQL::errstr;
};

plan tests => 8;

my $m = DBIx::Migration->new;
$m->dsn( $pgsql->dsn );
$m->dir( './t/sql/' );

is( $m->version, undef );

$m->migrate( 1 );
is( $m->version, 1 );

$m->migrate( 2 );
is( $m->version, 2 );

$m->migrate( 1 );
is( $m->version, 1 );

$m->migrate( 0 );
is( $m->version, 0 );

$m->migrate( 2 );
is( $m->version, 2 );

$m->migrate( 0 );
is( $m->version, 0 );

my $m2 = DBIx::Migration->new( { dbh => $m->dbh, dir => './t/sql/' } );

is( $m2->version, 0 );
