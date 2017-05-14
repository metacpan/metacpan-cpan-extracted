#!/usr/bin/perl -w

use strict;
use lib ('.');
use Clip;
use Tk;
use Tk::Canvas;

my $top 	= MainWindow->new();
my $can = $top->Canvas( -width => 500, -height=> 500 )->form();
my $clip = new Clip ( 10, 10, 400, 400, $can, 'Clip' );
$clip->clipdraw ( 20, 20, 390, 390 );
MainLoop;
