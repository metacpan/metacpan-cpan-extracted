#!/usr/bin/perl -w


use lib '..','../blib/lib','../blib/arch';
use strict;
use SCF;

die "Usage : ./write_test.pl [file to read] [file to write]\n" 
	unless defined $ARGV[1];

my $obj = SCF->new($ARGV[0]);

for (0...$obj->bases_length-1){
  $obj->base($_, "A");
}
$obj->write($ARGV[1]) or die "Cannot write to $ARGV[1]\n";
warn "Wrote all A's into $ARGV[1]\n";
