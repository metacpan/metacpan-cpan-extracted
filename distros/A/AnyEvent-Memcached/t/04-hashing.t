#!/usr/bin/env perl

use common::sense 2;
use Test::NoWarnings;
use Test::More tests => 35+1;
use lib::abs "../lib";
use AnyEvent::Memcached::Hash;
use AnyEvent::Memcached::Buckets;

my $bucks = AnyEvent::Memcached::Buckets->new( servers => [
	"node-x",
	"node-y",
	"node-z", 
	"socket",
	[ "node-z", 3 ]
]);

my $hasher = AnyEvent::Memcached::Hash->new(
	buckets => $bucks,
);

# Basic tests
is_deeply $hasher->hashes('a'), { 'node-z' => ['a'] }, 'hashes a';
is_deeply $hasher->hashes('b'), { 'node-z' => ['b'] }, 'hashes b';
is_deeply $hasher->hashes('c'), { 'node-z' => ['c'] }, 'hashes c';
is_deeply $hasher->hashes('d'), { 'node-z' => ['d'] }, 'hashes d';
is_deeply $hasher->hashes('e'), { 'node-z' => ['e'] }, 'hashes e';
is_deeply $hasher->hashes('f'), { 'node-z' => ['f'] }, 'hashes f';
is_deeply $hasher->hashes('g'), { 'node-z' => ['g'] }, 'hashes g';
is_deeply $hasher->hashes('h'), { 'node-x' => ['h'] }, 'hashes h';
is_deeply $hasher->hashes('i'), { 'node-z' => ['i'] }, 'hashes i';
is_deeply $hasher->hashes('j'), { 'node-x' => ['j'] }, 'hashes j';
is_deeply $hasher->hashes('k'), { 'node-z' => ['k'] }, 'hashes k';
is_deeply $hasher->hashes('l'), { 'socket' => ['l'] }, 'hashes l';
is_deeply $hasher->hashes('m'), { 'node-z' => ['m'] }, 'hashes m';
is_deeply $hasher->hashes('n'), { 'node-z' => ['n'] }, 'hashes n';
is_deeply $hasher->hashes('o'), { 'node-z' => ['o'] }, 'hashes o';
is_deeply $hasher->hashes('p'), { 'node-y' => ['p'] }, 'hashes p';
is_deeply $hasher->hashes('q'), { 'node-z' => ['q'] }, 'hashes q';
is_deeply $hasher->hashes('r'), { 'node-x' => ['r'] }, 'hashes r';
is_deeply $hasher->hashes('s'), { 'socket' => ['s'] }, 'hashes s';
is_deeply $hasher->hashes('t'), { 'node-x' => ['t'] }, 'hashes t';
is_deeply $hasher->hashes('u'), { 'node-z' => ['u'] }, 'hashes u';
is_deeply $hasher->hashes('v'), { 'socket' => ['v'] }, 'hashes v';
is_deeply $hasher->hashes('w'), { 'node-y' => ['w'] }, 'hashes w';
is_deeply $hasher->hashes('x'), { 'node-z' => ['x'] }, 'hashes x';
is_deeply $hasher->hashes('y'), { 'node-z' => ['y'] }, 'hashes y';
is_deeply $hasher->hashes('z'), { 'node-x' => ['z'] }, 'hashes z';

# Test many keys
is_deeply $hasher->hashes([qw(h p q v)]), {
	'node-x' => ['h'],
	'node-y' => ['p'],
	'node-z' => ['q'],
	'socket' => ['v'],
}, 'hashes [h p q v]';

# Test complex keys with predefined hash value
is_deeply $hasher->hashes([[0 => 'a0']]), { 'node-x' => ['a0'] }, 'hashes [[0,a0]]';
is_deeply $hasher->hashes([[1 => 'a1']]), { 'node-y' => ['a1'] }, 'hashes [[1,a1]]';
is_deeply $hasher->hashes([[2 => 'a2']]), { 'node-z' => ['a2'] }, 'hashes [[2,a2]]';
is_deeply $hasher->hashes([[3 => 'a3']]), { 'socket' => ['a3'] }, 'hashes [[3,a3]]';
is_deeply $hasher->hashes([[4 => 'a4']]), { 'node-z' => ['a4'] }, 'hashes [[4,a4]]';
is_deeply $hasher->hashes([[5 => 'a5']]), { 'node-z' => ['a5'] }, 'hashes [[5,a5]]';
is_deeply $hasher->hashes([[6 => 'a6']]), { 'node-z' => ['a6'] }, 'hashes [[6,a6]]';

# Test many complex keys
is_deeply
	$hasher->hashes([
		[ 0 => 'a' ], [ 1 => 'b' ], [ 2 => 'c' ], [ 3 => 'd' ]
	]), {
		'node-x' => ['a'],
		'node-y' => ['b'],
		'node-z' => ['c'],
		'socket' => ['d'],
	},
	'hashes [[1],[2],[3],[4]]'
;
