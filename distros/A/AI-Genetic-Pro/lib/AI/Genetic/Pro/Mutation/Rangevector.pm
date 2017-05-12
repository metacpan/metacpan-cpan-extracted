package AI::Genetic::Pro::Mutation::Rangevector;

use warnings;
use strict;
use List::MoreUtils qw(first_index);
use Math::Random qw(random_uniform_integer);
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
			}elsif($rand < 0.8 and $range < scalar @{$_translations}){
				if($rand < 0.6 and $ga->variable_length > 1 and not $chromosomes->[$idx]->[0]){
					$chromosomes->[$idx]->[ $min - 1 ] = random_uniform_integer(1, @{$_translations->[ $min - 1 ]}[1..2]);
				}elsif(exists $_translations->[scalar @{$chromosomes->[$idx]}]){
					push @{$chromosomes->[$idx]}, random_uniform_integer(1, @{$_translations->[scalar @{$chromosomes->[$idx]}]}[1..2]);	
				}
			}else{
				my $id = $min + int rand($range - 1);
				$chromosomes->[$idx]->[$id] = random_uniform_integer(1, @{$_translations->[$id]}[1..2]);	
			}
		}else{
			my $id = int rand @{$chromosomes->[$idx]};
			$chromosomes->[$idx]->[$id] = random_uniform_integer(1, @{$_translations->[$id]}[1..2]);	
		}
		
		# we need to change fitness
		$_fitness->{$idx} = $fitness->($ga, $chromosomes->[$idx]);
	}
	
	return 1;
}
#=======================================================================
sub run0 {
	my ($self, $ga) = @_;

	# this is declared here just for speed
	my $mutation = $ga->mutation;
	
	# main loop
	foreach my $chromosome (@{$ga->{chromosomes}}){
		next if rand() <= $mutation;
		
		if($ga->variable_length){
			my $rand = rand();
			if($rand < 0.33 and $#$chromosome > 1){
				pop @$chromosome;
			}elsif($rand < 0.66 and $#$chromosome < $#{$ga->_translations}){
				push @$chromosome, random_uniform_integer(1, @{$ga->_translations->[scalar @$chromosome]});
			}else{
				my $idx = int rand @$chromosome;
				$chromosome->[$idx] = random_uniform_integer(1, @{$ga->_translations->[$idx]});	
			}
		}else{
			my $idx = int rand @$chromosome;
			$chromosome->[$idx] = random_uniform_integer(1, @{$ga->_translations->[$idx]});		
		}
	}
	
	return 1;
}
#=======================================================================
1;
