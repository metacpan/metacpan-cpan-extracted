use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;
use Test::More qw(no_plan);
use Clone qw(clone);
use Struct::Compare;
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
        -cache           => 0,                # cache results
        -history         => 0,                # remember best results
        -preserve        => 0,                # remember the bests
        -variable_length => 0,                # turn variable length OFF
);

# init population of 32-bit vectors
$ga->init(BITS);

my $population = [ ];
for my $chromosome(@{$ga->chromosomes}){
	push @$population, clone($chromosome);
}

my @data;
for(0..BITS){
	my @chromosome;
	push @chromosome, rand() < 0.5 ? 1 : 0 for 1..BITS;
	push @data, \@chromosome;
}

push @$population, @data;
$ga->inject(\@data);

my $OK = 1;
for(0..$#$population){
	my @tmp0 = @{$population->[$_]};
	my @tmp1 = @{$ga->chromosomes->[$_]};
	unless(compare(\@tmp0, \@tmp1)){
		$OK = 0;
		last;
	}
}

ok($OK);

