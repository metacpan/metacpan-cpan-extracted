#!/usr/bin/perl -w

use lib './','../blib/lib','../blib/arch';
use SCF;

my %scf;
tie %scf, 'SCF', (shift || '../test.scf');

for (my $i = 0; $i<$scf{bases_length}; $i++){
  my $peak = $scf{index}[$i];
  print sprintf("%s %02d %02d %02d %02d | %5d | %04d %04d %04d %04d\n",
		$scf{bases}[$i],
		$scf{A}[$i],
		$scf{C}[$i],
		$scf{G}[$i],
		$scf{T}[$i],
		$peak,
		$scf{samples}{A}[$peak],
		$scf{samples}{C}[$peak],
		$scf{samples}{G}[$peak],
		$scf{samples}{T}[$peak],
	       );
}

print "\n";
