#!/usr/bin/perl -w

use lib '..','../blib/lib','../blib/arch';
use SCF;

my $obj = SCF->new(shift || '../test.scf');

1;

for (my $i = 0; $i<$obj->bases_length; $i++){
  my $peak = $obj->index($i);
  print sprintf("%s (%02d) %02d %02d %02d %02d | %5d | %04d %04d %04d %04d\n",
		$obj->base($i),
		$obj->score($i),
		$obj->base_score('A',$i),
		$obj->base_score('C',$i),
		$obj->base_score('G',$i),
		$obj->base_score('T',$i),
		$peak,
		$obj->sample('A',$peak),
		$obj->sample('C',$peak),
		$obj->sample('G',$peak),
		$obj->sample('T',$peak)
	       );
}
print "\n";
