#!/usr/local/bin/perl

# $Id$

use strict;
use warnings;
use Data::Dumper;

my $tree = {};

foreach my $line (<DATA>) {
    my @data = split /\t/, $line;
    
    my $zipcode = $data[0];
    
    if ($zipcode !~ m/^\d{4}$/) {
        next;
    }
    my @digits = split(//, $zipcode, 4);
        
    $tree->{$digits[0]}->{$digits[1]}->{$digits[2]}->{$digits[3]} = '';
}

print Dumper $tree;

#foreach my $k (keys %{$tree}) {
    _traverse($tree);
#}

no strict 'refs';

sub _traverse {
    my $tree = shift;

    my ($k) = keys (%{$tree});

    if (ref $k eq 'HASH') {
        _traverse($k);
    } else {
        print $k;
        _traverse($tree->{$k});
    }
}

exit 0;

__DATA__

Postnr.	Bynavn			Gade	Firma	Provins	Land	
0555	Scanning		Data Scanning A/S, "Læs Ind"-service	True	1	
0555	Scanning		Data Scanning A/S, "Læs Ind"-service	False	1	
0800	Høje Taastrup	Girostrøget 1	BG-Bank A/S	True	1	
0877	Valby	Vigerslev Allé 18	Aller Press (konkurrencer)	False	1	
0900	København C		Københavns Postcenter + erhvervskunder	False	1	
0910	København C	Ufrankerede svarforsendelser 		False	1	
0929	København C	Ufrankerede svarforsendelser		False	1	
