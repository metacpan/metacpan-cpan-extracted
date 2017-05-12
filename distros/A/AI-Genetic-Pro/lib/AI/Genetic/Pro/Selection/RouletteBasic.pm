package AI::Genetic::Pro::Selection::RouletteBasic;

use warnings;
use strict;
use List::Util qw(min);
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
use List::MoreUtils qw(first_index);
use Carp 'croak';
#=======================================================================
sub new { bless \$_[0], $_[0]; }
#=======================================================================
sub run {
	my ($self, $ga) = @_;
	
	my ($fitness, $chromosomes) = ($ga->_fitness, $ga->chromosomes);
	croak "You must set a number of parents to use the RouletteBasic strategy"
		unless defined($ga->parents);
	my $parents = $ga->parents;
	my (@parents, @wheel);
	my $const = min values %$fitness;
	$const = $const < 0 ? abs($const) : 0;
	my $total = 0;
	#-------------------------------------------------------------------
	foreach my $key (keys %$fitness){
		$total += $fitness->{$key} + $const;
		push @wheel, [ $key, $total ];
	}
	
	for(0..$#$chromosomes){
		my @group;
		for(1..$parents){
			my $rand = rand($total);
			my $idx = first_index { $_->[1] > $rand } @wheel;
			if($idx == 0){ $idx = 1 }
			elsif($idx == -1 ) { $idx = scalar @wheel; }
			push @group, $wheel[$idx-1]->[0];
		}
		push @parents, pack 'I*', @group;
	}
	
	#-------------------------------------------------------------------
	return \@parents;
}
#=======================================================================

1;
