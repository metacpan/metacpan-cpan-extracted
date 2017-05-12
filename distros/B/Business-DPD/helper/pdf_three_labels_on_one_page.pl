#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use PDF::Reuse;
use PDF::Reuse::Barcode;

my $out = shift @ARGV;
my @include = @ARGV[0,1,2];

prFile($out);

my $base_y=20;
my $int = 270;

foreach my $inc (@include) {
    prForm({
        file =>$inc,
        page => 1,
        x    => 500,
        rotate => 90,
        y    => $base_y
    });
    $base_y+=$int;
}

prEnd();

