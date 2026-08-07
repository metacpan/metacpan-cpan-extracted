#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    plan skip_all => 'set DBIX_LOOP_PG_DSN to run the Pg parity tests'
        unless $ENV{DBIX_LOOP_PG_DSN};
    plan skip_all => 'DBD::Pg required' unless eval { require DBD::Pg; 1 };
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
}
use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;
use BackendParity;

my $ad = DBIx::Loop::Loop::IOAsync->new;
my $db = DBIx::Loop->connect(
    $ENV{DBIX_LOOP_PG_DSN},
    $ENV{DBIX_LOOP_PG_USER} || '', $ENV{DBIX_LOOP_PG_PASS} || '',
    { RaiseError => 1, PrintError => 0 },
    loop => $ad,
);
is($db->capability, 'native', 'runs on the native backend');
BackendParity::run($db, $ad,
    name   => 'native/Pg',
    create => 'CREATE TEMPORARY TABLE p (id INT PRIMARY KEY, name TEXT, n INT)',
);
$db->disconnect;
done_testing();
