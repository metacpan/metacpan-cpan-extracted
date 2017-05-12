#!/usr/bin/perl -W
# 
# This example will read every files given in argument then
# dump the whole thing on the screen. Useful for debugging. 
# 
use strict;
use Config::Natural;

print STDERR "Gimme some files!!\n" and exit unless @ARGV;

my $data = new Config::Natural;

for (@ARGV) { $data->read_source($_) }

print $data->dump_param;
