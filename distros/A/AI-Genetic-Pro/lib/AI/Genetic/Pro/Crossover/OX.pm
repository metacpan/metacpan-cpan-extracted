package AI::Genetic::Pro::Crossover::OX;

use warnings;
use strict;
use List::MoreUtils qw(first_index);
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
#=======================================================================
sub new { bless \$_[0], $_[0]; }
#=======================================================================
sub save_fitness {
	my ($self, $ga, $idx) = @_;
	$ga->_fitness->{$idx} = $ga->fitness->($ga, $ga->chromosomes->[$idx]);
	return $ga->chromosomes->[$idx];
}
#=======================================================================
sub run {
	my ($self, $ga) = @_;
	
	my ($chromosomes, $parents, $crossover) = ($ga->chromosomes, $ga->_parents, $ga->crossover);
	my ($fitness, $_fitness) = ($ga->fitness, $ga->_fitness);
	my @children;
	#-------------------------------------------------------------------
	while(my $elders = shift @$parents){
		my @elders = unpack 'I*', $elders;
		
		unless(scalar @elders){
			push @children, $chromosomes->[$elders[0]];
			next;
		}
		
		my @points = sort { $a <=> $b } map { 1 + int(rand $#{$chromosomes->[0]}) } 0..1;
		
		@elders = sort {
					my @av = @{$a}[$points[0]..$points[1]];
					my @bv = @{$b}[$points[0]..$points[1]];
					
					for my $e(@av){
						splice(@$b, (first_index { $_ == $e } @$b), 1);
					}
					splice @$b, $points[0], 0, @av;
					
					for my $e(@bv){
						splice(@$a, (first_index { $_ == $e } @$a), 1);
					}
					splice @$a, $points[0], 0, @bv;
					0;
					
						} map { 
							$chromosomes->[$_]->clone;
								} @elders;
		
		
		my %elders = map { $_ => $fitness->($ga, $elders[$_]) } 0..$#elders;
		my $max = (sort { $elders{$a} <=> $elders{$b} } keys %elders)[-1];
		$_fitness->{scalar(@children)} = $elders{$max};
		
		push @children, $elders[$max];
	}
	#-------------------------------------------------------------------
	
	return \@children;
}
#=======================================================================
1;
