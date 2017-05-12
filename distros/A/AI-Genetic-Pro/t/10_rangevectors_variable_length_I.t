use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;
use Test::More qw(no_plan);
use AI::Genetic::Pro;

use constant SIZE =>  8;
use constant MIN  => -4;
use constant MAX  =>  4;

my @Win; 
push @Win, MAX for 1..SIZE;
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
        -type            => 'rangevector',    # type of chromosomes
        -population      => 100,              # population
        -crossover       => 0.9,              # probab. of crossover
        -mutation        => 0.05,             # probab. of mutation
        -parents         => 2,                # number  of parents
        -selection       => [ 'Roulette' ],   # selection strategy
        -strategy        => [ 'Points', 2 ],  # crossover strategy
        -cache           => 1,                # cache results
        -history         => 0,                # remember best results
        -preserve        => 0,                # remember the bests
        -variable_length => 1,                # turn variable length OFF
);


my @data;
push @data, [ MIN, MAX ] for 1..SIZE;
$ga->init(\@data);

@data = (
	[qw( 4 0 4 0 4 0 4 0 )],
	[qw( 0 4 0 4 0 4 0 4 )],
	[qw( 4 4 0 0 4 4 0 0 )],
	[qw( 4 4 4 4 0 0 0 0 )],
	[qw( 0 0 0 0 4 4 4 4 )],
);
push @data, @data for 1..SIZE;
$ga->inject(\@data);

# evolve 1000 generations
$ga->evolve(1000);
ok($Win == $ga->as_value($ga->getFittest));

