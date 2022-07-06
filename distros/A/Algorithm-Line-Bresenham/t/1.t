#!/usr/bin/perl
use Test::More tests => 9;

BEGIN { use_ok( 'Algorithm::Line::Bresenham', qw(line circle quad_bezier ellipse_rect polyline) ); }

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
	[[3,3],[2,4],[1,3],[2,2]], 
	[circle(2,3,1)],
	'circle');
is_deeply ( 
	[[2,3],[3,4],[4,4],[4,4],[5,4],[6,4],[7,3]], 
	[quad_bezier(2,3,4,5,7,3)],
	'quad_bezier');
is_deeply ( 
	[[6,4],[2,4],[2,3],[6,3],[5,4],[3,4],[3,3],[5,3],[4,4],[4,4],[4,3],[4,3]], 
	[ellipse_rect(2,3,6,4)],
	'ellipse_rect');
is_deeply ( 
	[[2,3],[3,3],[4,4],[5,4],[6,4],[6,5],[5,6],[5,7]], 
	[polyline(2,3,6,4,5,7)],
	'polyline');
	
__END__
$Data::Dumper::Indent = 0;
print Data::Dumper->Dump([[polyline(2,3,6,4,5,7)]]);
print Data::Dumper->Dump([[polyline(55,10,60,15,55,20,60,25,55,30,60,35)]]);;
