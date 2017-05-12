#!/usr/local/bin/perl
use TestC;
use strict;
my $tc = new TestC;
my $one_var  = $tc->load1();
my (@two_vars) = $tc->load2();
$one_var  = $tc->load1();
@two_vars = $tc->load2();
