use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin, $Bin.'../lib';
use Test::More qw(no_plan);
use AI::Genetic::Pro;

use constant BITS => 32;

my @Win; 
push @Win, 1 for 1..BITS;
my $Win = sum( \@Win );

sub sum {
	my ($ar) = @_;
	my $counter = 0;
	for(0..$#$ar){
		$counter += $ar->[$_] if $ar->[$_];
	}
	return $counter;
}

sub fitness {
	my ($ga, $chromosome) = @_;
	return sum(scalar $ga->as_array($chromosome));
}

sub terminate {
    my ($ga) = @_;
	return 1 if $Win == $ga->as_value($ga->getFittest);
	return;
}

my $ga = AI::Genetic::Pro->new(        
        -fitness         => \&fitness,        # fitness function
        -terminate       => \&terminate,      # terminate function
        -type            => 'bitvector',      # type of chromosomes
        -population      => 100,              # population
        -crossover       => 0.9,              # probab. of crossover
        -mutation        => 0.05,             # probab. of mutation
        -parents         => 2,                # number  of parents
        -selection       => [ 'Roulette' ],   # selection strategy
        -strategy        => [ 'Points', 2 ],  # crossover strategy
        -cache           => 1,                # cache results
        -history         => 0,                # remember best results
        -preserve        => 4,                # remember the bests
        -variable_length => 0,                # turn variable length OFF
);

# init population of 32-bit vectors
$ga->init(BITS);

$ga->inject( [ \@Win, \@Win, \@Win, \@Win ] );

# evolve 1000 generations
$ga->evolve(1);

my $count = 0;
for($ga->getFittest(4)){
	$count++ if $ga->as_value($_) == $Win; 
}

ok($count >= 4);
