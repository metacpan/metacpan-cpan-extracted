#!/usr/bin/perl -w

use lib '..','../blib/lib','../blib/arch';
use strict;
use SCF;

die "Usage : ./write_test.pl [file to read] [file to write]\n" 
	unless defined $ARGV[1];

my %scf;
tie %scf, 'SCF', $ARGV[0];

for (0...$scf{bases_length}-1){
  $scf{bases}[$_] = "A";
  $scf{index}[$_] = 10;
}
(tied %scf)->write($ARGV[1]) or die "Cannot write to $ARGV[1]\n";
warn "Wrote all A's into $ARGV[1]\n";
