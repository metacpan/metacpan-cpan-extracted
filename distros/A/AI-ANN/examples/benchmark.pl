#!/usr/bin/perl
use strict;
use warnings;
use Benchmark qw(:all);
use AI::ANN::Neuron;

my %data = (id => 1, inputs => [ 4*rand()-2, 4*rand()-2, 4*rand()-2,
								 4*rand()-2, 4*rand()-2 ],
					 neurons => [ 4*rand()-2, 4*rand()-2, 4*rand()-2, 
								  4*rand()-2, 4*rand()-2 ]);
my $object1 = new AI::ANN::Neuron ( %data, inline_c => 0 );
my $object2 = new AI::ANN::Neuron ( %data, inline_c => 1 );
my @data = ( [ 4*rand()-2, 4*rand()-2, 4*rand()-2, 4*rand()-2, 4*rand()-2 ],
			 [ 4*rand()-2, 4*rand()-2, 4*rand()-2, 4*rand()-2, 4*rand()-2 ]);
cmpthese( -1, { 'pure_perl' => sub{$object1->execute(@data)},
				'inline_c'  => sub{$object2->execute(@data)} });

use Math::Libm qw(erf M_PI);
use Inline C => <<'END_C';
#include <math.h>
double afunc[4001];	
double dafunc[4001];
void generate_globals() {
	int i;
	for (i=0;i<=4000;i++) {
		afunc[i] = 2 * (erf(i/1000.0-2));
		dafunc[i] = 4 / sqrt(M_PI) * pow(exp(-1 * ((i/1000.0-2))), 2);
	}
}
double afunc_c (float input) {
	return afunc[(int) floor((input)*1000)+2000];
}
double dafunc_c (float input) {
	return dafunc[(int) floor((input)*1000)+2000];
}
END_C

timethis(-1, 'generate_globals()');

sub afunc_pp {
	return 2 * erf(int((shift)*1000)/1000);
}
sub dafunc_pp {
	return 4 / sqrt(M_PI) * exp( -1 * ((int((shift)*1000)/1000) ** 2) );
}

cmpthese( -1, { 'afunc_c'  => sub{afunc_c(4*rand()-2)},
				'afunc_pp' => sub{afunc_pp(4*rand()-2)} });

cmpthese( -1, { 'dafunc_c'  => sub{dafunc_c(4*rand()-2)},
				'dafunc_pp' => sub{dafunc_pp(4*rand()-2)} });

