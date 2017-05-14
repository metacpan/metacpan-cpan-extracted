#!/usr/bin/perl -w

use strict;
use Getopt::Std;

my $width = 500;
my $height = 500;
my $opt_w;
my $opt_h;

getopts( 'w:h:' );
if( $opt_w ) { $width = $opt_w ; }
if( $opt_h ) { $height = $opt_h ; }

print "$width:$height\n";

