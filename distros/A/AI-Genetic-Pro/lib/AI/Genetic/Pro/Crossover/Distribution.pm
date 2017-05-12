package AI::Genetic::Pro::Crossover::Distribution;

use warnings;
use strict;
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
use Math::Random qw(
	random_uniform_integer 
	random_normal 
	random_beta
	random_binomial
	random_chi_square
	random_exponential
	random_poisson
);
use List::MoreUtils qw(first_index);
#=======================================================================
sub new { 
	my ($class, $type, @params) = @_;
	bless { 
			type 	=> $type,
			params	=> \@params,
		}, $class; 
}
#=======================================================================
sub run {
	my ($self, $ga) = @_;
	
	my ($chromosomes, $parents, $crossover) = ($ga->chromosomes, $ga->_parents, $ga->crossover);
	my ($fitness, $_fitness) = ($ga->fitness, $ga->_fitness);
	my $high  = scalar @{$chromosomes->[0]};
	my @children;
	#-------------------------------------------------------------------
	while(my $elders = shift @$parents){
		my @elders = unpack 'I*', $elders;
		
		unless(scalar @elders){
			$_fitness->{scalar(@children)} = $fitness->($ga, $chromosomes->[$elders[0]]);
			push @children, $chromosomes->[$elders[0]];
			next;
		}
		
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		my $len = scalar @elders;
		my @seq;
		if($self->{type} eq q/uniform/){
			@seq = random_uniform_integer($high, 0, $#elders);
		}elsif($self->{type} eq q/normal/){
			my $av = defined $self->{params}->[0] ? $self->{params}->[0] : $len/2;
			my $sd = defined $self->{params}->[1] ? $self->{params}->[1] : $len;
			@seq = map { $_ % $len } random_normal($high, $av, $sd);
		}elsif($self->{type} eq q/beta/){
			my $aa = defined $self->{params}->[0] ? $self->{params}->[0] : $len;
			my $bb = defined $self->{params}->[1] ? $self->{params}->[1] : $len;
			@seq = map { int($_ * $len) } random_beta($high, $aa, $bb);
		}elsif($self->{type} eq q/binomial/){
			@seq = random_binomial($high, $#elders, rand);
		}elsif($self->{type} eq q/chi_square/){
			my $df = defined $self->{params}->[0] ? $self->{params}->[0] : $len;
			@seq = map { $_ % $len } random_chi_square($high, $df);
		}elsif($self->{type} eq q/exponential/){
			my $av = defined $self->{params}->[0] ? $self->{params}->[0] : $len/2;
			@seq = map { $_ % $len } random_exponential($high, $av);
		}elsif($self->{type} eq q/poisson/){
			my $mu = defined $self->{params}->[0] ? $self->{params}->[0] : $len/2;
			@seq = map { $_ % $len } random_poisson($high, $mu) ;
		}else{
			die qq/Unknown distribution "$self->{type}" in "crossover"!\n/;
		}
		
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		my ($min, $max) = (0, $#{$chromosomes->[0]} - 1);
		if($ga->variable_length){
			for my $el(@elders){
				my $idx = first_index { $_ } @{$chromosomes->[$el]};
				$min = $idx if $idx > $min;
				$max = $#{$chromosomes->[$el]} if $#{$chromosomes->[$el]} < $max;
			}
		}
		
		$elders[0] = $chromosome->[$elders[0]]->clone;
		for(0..$#seq){
			next if not $seq[$_] or $_ < $min or $_ > $max;
			$elders[0]->[$_] = $chromosomes->[$elders[$seq[$_]]]->[$_];
		}
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		
		push @children, $elders[ 0 ];
	}
	#-------------------------------------------------------------------
	
	return \@children;
}
#=======================================================================
1;
