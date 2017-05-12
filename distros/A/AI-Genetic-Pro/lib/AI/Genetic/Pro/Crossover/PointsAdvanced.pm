package AI::Genetic::Pro::Crossover::PointsAdvanced;

use warnings;
use strict;
use List::MoreUtils qw(first_index);
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
#use AI::Genetic::Pro::Array::PackTemplate;
#=======================================================================
sub new { bless { points => $_[1] ? $_[1] : 1 }, $_[0]; }
#=======================================================================
sub run {
	my ($self, $ga) = @_;
	
	my ($chromosomes, $parents, $crossover) = ($ga->chromosomes, $ga->_parents, $ga->crossover);
	my ($fitness, $_fitness) = ($ga->fitness, $ga->_fitness);
	#-------------------------------------------------------------------
	while(my $elders = shift @$parents){
		my @elders = unpack 'I*', $elders;

		unless(scalar @elders){
			push @$chromosomes, $chromosomes->[$elders[0]];
			next;
		}
	
		my ($min, $max) = (0, $#{$chromosomes->[0]} - 1);
		if($ga->variable_length){
			for my $el(@elders){
				my $idx = first_index { $_ } @{$chromosomes->[$el]};
				$min = $idx if $idx > $min;
				$max = $#{$chromosomes->[$el]} if $#{$chromosomes->[$el]} < $max;
			}
		}
		
		my @points;
		if($min < $max and $max - $min > 2){
			my $range = $max - $min;
			@points = map { $min + int(rand $range) } 1..$self->{points};
		}

		@elders = map { $chromosomes->[$_]->clone } @elders;
		for my $pt(@points){
			@elders = sort {
						splice @$b, 0, $pt, splice( @$a, 0, $pt, @$b[0..$pt-1] );
						0;
							} @elders;
		}
		
		push @$chromosomes, @elders;
	}
	#-------------------------------------------------------------------
	# wybieranie potomkow ze zbioru starych i nowych osobnikow
	@$chromosomes = sort { $fitness->($ga, $a) <=> $fitness->($ga, $b) } @$chromosomes;
	splice @$chromosomes, 0, scalar(@$chromosomes) - $ga->population;
	%$_fitness = map { $_ => $fitness->($ga, $chromosomes->[$_]) } 0..$#$chromosomes;
	#-------------------------------------------------------------------
	return $chromosomes;
}
#=======================================================================
1;
