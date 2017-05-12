#!perl

use strict;
use warnings;
use Test::More tests => 9;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

my $mm = new Data::ModeMerge;

ok(!$mm->_in(undef, [undef]), "undef");

ok( $mm->_in(1, [1,2,3]), "scalar 1");
ok(!$mm->_in(4, [1,2,3]), "scalar 2");

ok( $mm->_in([], [[]]), "array 1");
ok( $mm->_in([1], [[1], [2]]), "array 2");
ok(!$mm->_in([1], [[2], {1=>2}]), "array 3");

ok( $mm->_in({}, [{}]), "hash 1");
ok( $mm->_in({a=>1}, [{a=>1}, {a=>2}]), "hash 2");
ok(!$mm->_in({a=>1}, [{a=>2}, {b=>1}, {1=>"a"}, "a", 1, ["a", 1]]), "hash 3");
