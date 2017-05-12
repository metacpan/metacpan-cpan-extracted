#!/usr/bin/env perl
use strict;

my $a =  do { local $/; <ARGV> };

my $tst = $ENV{TEST_FILE};
open my $fh, ">$tst";
print $fh $a;
close $fh;
