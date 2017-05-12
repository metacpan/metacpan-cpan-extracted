use strict;
use Test::More tests => 7;

use DBIx::Migration;
use DBI;

eval { require DBD::SQLite };
my $class = $@ ? 'SQLite2' : 'SQLite';

my $m = DBIx::Migration->new;
$m->dsn("dbi:$class:dbname=./t/sqlite_test");
$m->dir('./t/sql/');
is( $m->version, undef );

$m->migrate(1);
is( $m->version, 1 );

$m->migrate(2);
is( $m->version, 2 );

$m->migrate(1);
is( $m->version, 1 );

$m->migrate(0);
is( $m->version, 0 );

$m->migrate(2);
is( $m->version, 2 );

$m->migrate(0);
is( $m->version, 0 );

END {
    unlink './t/sqlite_test';
}
