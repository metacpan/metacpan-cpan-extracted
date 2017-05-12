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

my @Win0 = @Win; $Win0[-1] = 0;
my @Win1 = @Win; $Win1[-2] = 0;
my @Win2 = @Win; $Win2[-1] = 0; $Win2[-2] = 0;

$ga->inject( [ \@Win, \@Win0, \@Win1, \@Win2 ] );
$ga->evolve(1);

my $count = 0;
for my $w (\@Win, \@Win0, \@Win1, \@Win2){
	my $s = $ga->as_string($w);
	foreach my $c (@{$ga->chromosomes}){
		if($ga->as_string($c) eq $s){
			$count++;
			last;
		}
	}
}

ok($count == 4);
