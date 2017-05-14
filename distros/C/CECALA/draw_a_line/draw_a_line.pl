#!/usr/bin/perl -w

use strict;

use Tk;
use Tk::Canvas;

my $top = MainWindow->new();
my $can = $top->Canvas( -width => 100, -height=> 100 )->pack();
$can->create( 'line'
		, $can->reqwidth()
		, 0
		, 0
		, $can->reqheight() 
	);
$can->create( 'line'
		, 0
		, 0
		, $can->reqwidth()
		, $can->reqheight() 
	);

MainLoop;
