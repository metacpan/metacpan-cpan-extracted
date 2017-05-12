package AI::Genetic::Pro::Mutation::Listvector;

use warnings;
use strict;
use List::MoreUtils qw(first_index);
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
#=======================================================================
sub new { bless \$_[0], $_[0]; }
#=======================================================================
sub run {
	my ($self, $ga) = @_;

	# this is declared here just for speed
	my $mutation = $ga->mutation;
	my $chromosomes = $ga->chromosomes;
	my $_translations = $ga->_translations;
	my ($fitness, $_fitness) = ($ga->fitness, $ga->_fitness);
	
	# main loop
	for my $idx (0..$#$chromosomes){
		next if rand() >= $mutation;

		if($ga->variable_length){
			my $rand = rand();
			my $min = first_index { $_ } @{$chromosomes->[$idx]};
			my $range = $#{$chromosomes->[$idx]} - $min + 1;
		
			if($rand < 0.4 and $range > 2){
				if($rand < 0.2 and $ga->variable_length > 1){ $chromosomes->[$idx]->[$min] = 0; }
				else{ pop @{$chromosomes->[$idx]};	}
			}elsif($rand < 0.8 and $range < $#$_translations){
				if($rand < 0.6 and $ga->variable_length > 1 and not $chromosomes->[$idx]->[0]){
					$chromosomes->[$idx]->[ $min - 1 ] = 1 + int rand $#{$_translations->[ $min - 1 ]};
				}elsif(exists $_translations->[scalar @{$chromosomes->[$idx]}]){
					push @{$chromosomes->[$idx]}, 1 + int rand $#{$_translations->[scalar @{$chromosomes->[$idx]}]};
				}
			}else{
				my $id = $min + int rand($range - 1);
				$chromosomes->[$idx]->[$id] = 1 + int rand $#{$_translations->[$id]};
			}
		}else{
			my $id = int rand @{$chromosomes->[$idx]};
			$chromosomes->[$idx]->[$id] = 1 + int rand $#{$_translations->[$id]};
		}
		
		# we need to change fitness
		$_fitness->{$idx} = $fitness->($ga, $chromosomes->[$idx]);
	}
	
	return 1;
}
#=======================================================================
1;
