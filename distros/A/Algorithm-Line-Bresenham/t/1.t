#!/usr/bin/perl
use Test::More tests => 7;

BEGIN { use_ok( 'Algorithm::Line::Bresenham', qw(line) ); }

use Data::Dumper;

is_deeply ( 
	[[0,0], [1,1], [2,2]], 
	[line(0,0,2,2)],
	'up-right' );
is_deeply ( 
	[[2,2], [1,1], [0,0]], 
	[line(2,2,0,0)],
	'down-left'); 
is_deeply ( 
	[[2,0], [1,1], [0,2]], 
	[line(2,0,0,2)],
	'down-right'); 
is_deeply ( 
	[[0,0], [1,0], [2,0]], 
	[line(0,0,2,0)],
	'flat'); 
is_deeply ( 
	[[0,0], [1,1], [2,2], [2,3], [3,4]], 
	[line(0,0,3,4)],
);
is_deeply ( 
	[[0,0], [2,2], [4,4]], 
	[line(0,0,2,2, sub { [$_[0] * 2, $_[1] * 2] }) ],
	'callback');

