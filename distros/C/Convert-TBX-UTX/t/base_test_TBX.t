#!usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use Path::Tiny;

my $convertTBX_test = path("$Bin/UTX-TBX", "convertTBX.t");

system( qq("$^X" -Ilib "$convertTBX_test") );