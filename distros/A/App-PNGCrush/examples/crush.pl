#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib lib);
use App::PNGCrush;

die "Usage: perl crush.pl <pic_to_crush>"
    unless @ARGV;

my $Pic = shift;

my $crush = App::PNGCrush->new;

# this let's use best compression and remove a few chunks
$crush->set_options(
    qw( -d OUT_DIR -brute 1 ),
    remove  => [ qw( gAMA cHRM sRGB iCCP ) ],
);

my $out_ref = $crush->run( $Pic )
    or die "Error: " . $crush->error;

print "Size reduction: $out_ref->{size}%\nIDAT reduction:"
         . " $out_ref->{idat}%\n"
         . "(I saved output in OUT_DIR)\n";


