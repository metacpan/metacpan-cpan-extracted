#!perl

use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

my $mm = Data::ModeMerge->new;

dies_ok(sub {$mm->check_prefix([])}, 'invalid 1');
dies_ok(sub {$mm->check_prefix({})}, 'invalid 2');

ok(!$mm->check_prefix( 'a'), 'no prefix');
is( $mm->check_prefix('*a'), 'NORMAL', 'NORMAL');

dies_ok(sub {$mm->check_prefix_on_hash(1 )}, 'oh invalid 1');
dies_ok(sub {$mm->check_prefix_on_hash([])}, 'oh invalid 2');

ok(!$mm->check_prefix_on_hash({}), 'oh 1');
ok(!$mm->check_prefix_on_hash({a=>1,   b =>2}), 'oh 2');
ok( $mm->check_prefix_on_hash({a=>1, "+b"=>2}), 'oh 3');

$mm->config->disable_modes(['ADD']);
ok(!$mm->check_prefix('+a'), 'disable 1');
ok( $mm->check_prefix('.a'), 'disable 2');
ok(!$mm->check_prefix_on_hash({a=>1, '+b'=>2}), 'oh disable 1');
ok( $mm->check_prefix_on_hash({a=>1, '.b'=>2}), 'oh disable 2');
