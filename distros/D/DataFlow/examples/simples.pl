#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use DataFlow;

my $flow = DataFlow->new( [ sub { uc }, sub { scalar reverse }, ] );

$flow->input('batatas');
$flow->input('potatoes');
$flow->input('kartoshky');
$flow->input(@ARGV) if @ARGV;
$, = "\n";
say $flow->flush;

