#!perl -w

use strict;
use Benchmark qw(:all);
use Data::Util qw(anon_scalar);

use FindBin qw($Bin);
use lib $Bin;
use Common;

signeture 'Data::Util' => \&anon_scalar;

cmpthese timethese -1 => {
	anon_scalar => sub{
		for(1 .. 10){
			my $ref = anon_scalar();
		}
	},
	'\do{my $tmp}' => sub{
		for(1 .. 10){
			my $ref = \do{ my $tmp };
		}
	},
};

print "\nwith an argument\n";
cmpthese timethese -1 => {
	anon_scalar => sub{
		for(1 .. 10){
			my $ref = anon_scalar(10);
		}
	},
	'\do{my $tmp}' => sub{
		for(1 .. 10){
			my $ref = \do{ my $tmp = 10 };
		}
	},
};
