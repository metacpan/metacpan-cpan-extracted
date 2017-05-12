package AI::Genetic::Pro::Mutation::Combination;

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
	my $inv = $mutation / 2;
	
	# main loop
	for my $idx (0..$#$chromosomes){
		
		my $rand = rand;
		
		if($rand < $inv) { tied(@{$chromosomes->[$idx]})->reverse; }
		elsif($rand < $mutation){
			my $el = int rand @{$chromosomes->[$idx]};
			my $new = int rand @{$_translations->[0]};
			next if $new == $chromosomes->[$idx]->[$el];
			
			my $id = first_index { $_ == $new } @{$chromosomes->[$idx]};
			$chromosomes->[$idx]->[$id] = $chromosomes->[$idx]->[$el] if defined $id and $id != -1;
			$chromosomes->[$idx]->[$el] = $new;
		}
		
		# we need to change fitness
		$_fitness->{$idx} = $fitness->($ga, $chromosomes->[$idx]);
	}
	
	return 1;
}
#=======================================================================
1;
