package AI::Genetic::Pro::Selection::Roulette;

use warnings;
use strict;
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
use List::Util qw(sum min);
use List::MoreUtils qw(first_index);
use Carp 'croak';

#=======================================================================
sub new { bless \$_[0], $_[0]; }
#=======================================================================
sub run {
	my ($self, $ga) = @_;
	
	my ($fitness) = ($ga->_fitness);
	my (@parents, @elders);
	#-------------------------------------------------------------------
	my $count = $#{$ga->chromosomes};
	my $const = min values %$fitness;
	$const = $const < 0 ? abs($const) : 0;
	my $total = sum( map { $_ < 0 ? $_ + $const : $_ } values %$fitness);
	$total ||= 1;
	
	# elders
	for my $idx (0..$count){
		push @elders, $idx for 1..int((($fitness->{$idx} + $const) / $total) * $count);
	}
	
	if((my $add = $count - scalar @elders) > 0){
		my $idx = $elders[rand @elders];
		push @elders, int rand($count) for 0..$add;
	}
	
	croak "You must set a crossover probability to use the Roulette strategy"
		unless defined($ga->crossover);
	croak "You must set a number of parents to use the Roulette strategy"
		unless defined($ga->parents);

	# parents
	for(0..$count){
		if(rand > $ga->crossover){
			push @parents, pack 'I*', $elders[ rand @elders ]
		}else{
			my @group;
			push @group, $elders[ rand @elders ] for 1..$ga->parents;
			push @parents, pack 'I*', @group;
		}
	}

	#-------------------------------------------------------------------
	return \@parents;
}
#=======================================================================

1;
