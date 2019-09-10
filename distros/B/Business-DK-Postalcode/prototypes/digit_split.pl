#!/usr/bin/perl -w

use strict;

my $zipcode = '1234';

my @digits = split(//, $zipcode, 4);

use Data::Dumper;
print STDERR Dumper \@digits;
