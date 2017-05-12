package AI::Genetic::Pro::Crossover::PMX;

use warnings;
use strict;
use List::MoreUtils qw(indexes);
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
#=======================================================================
sub new { bless \$_[0], $_[0]; }
#=======================================================================
sub dup {
    my ($ar) = @_;

    my %seen;
    my @dup = grep { if($seen{$_}){ 1 }else{ $seen{$_} = 1; 0} } @$ar;
    return \@dup if @dup;
    return;
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
					my @av = @{$a}[$points[0]..$points[1]-1];
					my @bv = splice @$b, $points[0], $points[1] - $points[0], @av;
					splice @$a, $points[0], $points[1] - $points[0], @bv;
					
					my %av; @av{@av} = @bv;
					my %bv; @bv{@bv} = @av;

					while(my $dup = dup($a)){
    					foreach my $val (@$dup){
        					my ($ind) = grep { $_ < $points[0] or $_ >= $points[1] } indexes { $_ == $val } @$a;
        					$a->[$ind] = $bv{$val};
    					}
					}

					while(my $dup = dup($b)){
    					foreach my $val (@$dup){
        					my ($ind) = grep { $_ < $points[0] or $_ >= $points[1] } indexes { $_ == $val } @$b;
        					$b->[$ind] = $av{$val};
    					}
					}
					
					0;
						} map { 
							$chromosomes->[$_]->clone
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
