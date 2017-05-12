#!/usr/bin/perl -w

use strict;
use lib ('.');
use Clip2;

my $clip = new Clip2 ( 10, 10, 400, 400 );
my $rc = $clip->cliped ( -20, 20, 390, 390 );
print "Clipped retruned $rc\n";
$clip->setclipboundaries ( -21, 20, 400, 400 );
$rc = $clip->cliped ( -20, 20, 390, 390 );
print "Clipped retruned $rc\n";
