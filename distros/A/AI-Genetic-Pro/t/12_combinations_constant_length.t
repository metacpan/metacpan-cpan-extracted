use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;
use Test::More qw(no_plan);
use AI::Genetic::Pro;

my @Win = 'a'..'h';
my $Win = calc( \@Win );

sub calc {
	my ($ar) = @_;
	my $counter = 0;
	for(0..$#Win){
		$counter++ if $ar->[$_] and $ar->[$_] eq $Win[$_];
	}
	return $counter;
}

sub fitness {
	my ($ga, $chromosome) = @_;
	return calc(scalar $ga->as_array($chromosome));
}

sub terminate {
    my ($ga) = @_;
	return 1 if $Win == $ga->as_value($ga->getFittest);
	return;
}

my $ga = AI::Genetic::Pro->new(        
        -fitness         => \&fitness,        # fitness function
        -terminate       => \&terminate,      # terminate function
        -type            => 'combination',    # type of chromosomes
        -population      => 100,              # population
        -crossover       => 0.9,              # probab. of crossover
        -mutation        => 0.05,             # probab. of mutation
        -parents         => 2,                # number  of parents
        -selection       => [ 'Roulette' ],   # selection strategy
        -strategy        => [ 'PMX' ],        # crossover strategy
        -cache           => 1,                # cache results
        -history         => 0,                # remember best results
        -preserve        => 0,                # remember the bests
        -variable_length => 0,                # turn variable length OFF
);


$ga->init( [ 'a'..'h' ] );

my @data = (
	[qw( a c b d e g f h )],
	[qw( a b d c e f h g )],
	[qw( a c b d f e g h )],
	[qw( h b c d e f g a )],
);

push @data, @data for 1..scalar(@Win);
$ga->inject(\@data);

# evolve 1000 generations
$ga->evolve(1000);
ok($Win == $ga->as_value($ga->getFittest));

