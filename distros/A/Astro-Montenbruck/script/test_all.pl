#!/usr/bin/env perl
################################################################################
# Run all tests from ../t directory
################################################################################
use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::Harness;

our $VERSION = 0.01;

my $root = "$Bin/../t";
opendir (my $dh, $root) || die "cannot open directory: $!";
runtests map {"$root/$_"} grep { -f "$root/$_" && /\.t$/ } readdir $dh;
