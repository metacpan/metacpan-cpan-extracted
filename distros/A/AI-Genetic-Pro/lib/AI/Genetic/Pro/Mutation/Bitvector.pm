package AI::Genetic::Pro::Mutation::Bitvector;

use warnings;
use strict;
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
			if($rand < 0.16 and $#{$chromosomes->[$idx]} > 1){
				pop @{$chromosomes->[$idx]};
			}elsif($rand < 0.32 and $#{$chromosomes->[$idx]} > 1){
				shift @{$chromosomes->[$idx]};
			}elsif($rand < 0.48 and $#{$chromosomes->[$idx]} < $#$_translations){
				push @{$chromosomes->[$idx]}, rand > 0.5 ? 0 : 1;
			}elsif($rand < 0.64 and $#{$chromosomes->[$idx]} < $#$_translations){
				unshift @{$chromosomes->[$idx]}, rand > 0.5 ? 0 : 1;
			}elsif($rand < 0.8){
				tied(@{$chromosomes->[$idx]})->reverse;
			}else{
				my $id = int rand @{$chromosomes->[$idx]};
				$chromosomes->[$idx]->[$id] = $chromosomes->[$idx]->[$id] ? 0 : 1;
			}
		}else{
			my $id = int rand @{$chromosomes->[$idx]};
			$chromosomes->[$idx]->[$id] = $chromosomes->[$idx]->[$id] ? 0 : 1;	
		}
		# we need to change fitness
		$_fitness->{$idx} = $fitness->($ga, $chromosomes->[$idx]);
	}
	
	return 1;
}
#=======================================================================
# too slow; mutation is too dangerous in this solution
sub run0 {
	my ($self, $ga) = @_;

	my $mutation = $ga->mutation; # this is declared here just for speed
	foreach my $chromosome (@{$ga->{chromosomes}}){
		if(rand() < $mutation){ tied(@$chromosome)->reverse; }
		else{
			for(0..$#$chromosome){
				next if rand > $mutation;
				$chromosome->[$_] = $chromosome->[$_] ? 0 : 1;
			}
		}
	}
	
	return 1;
}
#=======================================================================
1;
