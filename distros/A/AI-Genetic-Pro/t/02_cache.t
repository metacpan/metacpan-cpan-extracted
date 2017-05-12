use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;
use Test::More qw(no_plan);
use Time::HiRes;
use AI::Genetic::Pro;

use constant BITS => 32;

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

my $ga = AI::Genetic::Pro->new(        
        -fitness         => \&fitness,        # fitness function
        -terminate       => sub { return; },  # terminate function
        -type            => 'bitvector',      # type of chromosomes
        -population      => 10,               # population
        -crossover       => 0.9,              # probab. of crossover
        -mutation        => 0.05,             # probab. of mutation
        -parents         => 2,                # number  of parents
        -selection       => [ 'Roulette' ],   # selection strategy
        -strategy        => [ 'Points', 2 ],  # crossover strategy
        -cache           => 0,                # cache results
        -history         => 0,                # remember best results
        -preserve        => 0,                # remember the bests
        -variable_length => 0,                # turn variable length OFF
);

# init population of 32-bit vectors
$ga->init(BITS);
$ga->chromosomes( [ ] );
$ga->inject( [ [ qw( 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) ] ] );
my $start = [Time::HiRes::gettimeofday()];
$ga->as_value($ga->chromosomes->[0]) for 0..10000;
my $time0 =Time::HiRes::tv_interval($start);


$ga = AI::Genetic::Pro->new(        
        -fitness         => \&fitness,        # fitness function
        -terminate       => sub { return; },  # terminate function
        -type            => 'bitvector',      # type of chromosomes
        -population      => 10,               # population
        -crossover       => 0.9,              # probab. of crossover
        -mutation        => 0.05,             # probab. of mutation
        -parents         => 2,                # number  of parents
        -selection       => [ 'Roulette' ],   # selection strategy
        -strategy        => [ 'Points', 2 ],  # crossover strategy
        -cache           => 1,                # cache results
        -history         => 0,                # remember best results
        -preserve        => 0,                # remember the bests
        -variable_length => 0,                # turn variable length OFF
);

# init population of 32-bit vectors
$ga->init(BITS);
$ga->chromosomes( [ ] );
$ga->inject( [ [ qw( 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) ] ] );
$start = [Time::HiRes::gettimeofday()];
$ga->as_value($ga->chromosomes->[0]) for 0..10000;
my $time1 =Time::HiRes::tv_interval($start);

ok( $time0 >= $time1 );

