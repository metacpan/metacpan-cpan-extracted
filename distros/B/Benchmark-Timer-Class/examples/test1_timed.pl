#!/usr/local/bin/perl
use Benchmark::Timer::Class;
use TestC;
use Data::Dumper;
use strict;
my $tc_original = new TestC;
my $tc = new Benchmark::Timer::Class($tc_original);
my $one_var  = $tc->load1();
my (@two_vars) = $tc->load2();
$one_var  = $tc->load1();
@two_vars = $tc->load2();
$tc->report();
