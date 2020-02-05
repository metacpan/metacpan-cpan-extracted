#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::Peek;

my %hash = (1, 100, 2, 150, 30, 25, 200, 12, 4, 4);

is (DDsort (0), 0, "Sort type 0");
my $out = DDumper \%hash;
like ($out, qr{\b200\s+=>\s+12\b}, "Unsorted"); # Random order

sub dsort {
    my ($sk, $exp) = @_;
    ok (DDsort ($sk),	"Sort type $sk");
    $out = DDumper \%hash;
    $out =~ s{\s+}{ }g;
    $out =~ s{\s+$}{};
    is ($out, $exp, "Sorted by $sk");
    } # dsort

dsort (1   => "{ 1 => 100, 2 => 150, 200 => 12, 30 => 25, 4 => 4 }");
dsort (R   => "{ 4 => 4, 30 => 25, 200 => 12, 2 => 150, 1 => 100 }");
dsort (N   => "{ 1 => 100, 2 => 150, 4 => 4, 30 => 25, 200 => 12 }");
dsort (NR  => "{ 200 => 12, 30 => 25, 4 => 4, 2 => 150, 1 => 100 }");
dsort (V   => "{ 1 => 100, 200 => 12, 2 => 150, 30 => 25, 4 => 4 }");
dsort (VR  => "{ 4 => 4, 30 => 25, 2 => 150, 200 => 12, 1 => 100 }");
dsort (VNR => "{ 2 => 150, 1 => 100, 30 => 25, 200 => 12, 4 => 4 }");

done_testing;

1;
