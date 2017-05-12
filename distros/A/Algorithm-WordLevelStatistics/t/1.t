#! /usr/bin/env perl

use strict;
use Test;

BEGIN { plan tests => 5 };
use Algorithm::WordLevelStatistics;
ok(1); # If we made it this far, we're loaded.

my $wls = Algorithm::WordLevelStatistics->new();
ok $wls;

my %spectra = ();

open IN, "<","t/Relativity.test" or die "cannot open Relativity.test: $!";
my $idx = 0;
while(<IN>) {
  chomp;
  next if(m/^\s*$/); #skip blank lines

  foreach my $w ( split /\W/, lc( $_ ) ) {
    next if($w =~ m/^\s*$/);
    push @{ $spectra{$w} }, $idx++;
  }
}
close IN;

my $ws = $wls->compute_spectra( \%spectra );
my @sw = sort { $ws->{$b}->{C} <=> $ws->{$a}->{C} } keys( %{ $ws } );

ok $sw[0], 'universe';
ok $sw[1], 'x';
ok $sw[2], 'field';

# -*- mode: perl -*-
