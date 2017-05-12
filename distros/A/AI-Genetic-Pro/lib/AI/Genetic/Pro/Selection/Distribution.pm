package AI::Genetic::Pro::Selection::Distribution;

use warnings;
use strict;
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
#use AI::Genetic::Pro::Array::PackTemplate;
use Math::Random qw(
	random_uniform_integer 
	random_normal 
	random_beta
	random_binomial
	random_chi_square
	random_exponential
	random_poisson
);
use Carp 'croak';
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
	
	my ($fitness, $chromosomes) = ($ga->_fitness, $ga->chromosomes);
	croak "You must set a number of parents to use the Distribution strategy"
		unless defined($ga->parents);
	my $parents = $ga->parents;
	my @parents;
	my $high = scalar @$chromosomes;
	#-------------------------------------------------------------------
	if($self->{type} eq q/uniform/){
		push @parents, 
			pack 'I*', random_uniform_integer($parents, 0, $#$chromosomes) 
				for 0..$#$chromosomes;
	}elsif($self->{type} eq q/normal/){
		my $av = defined $self->{params}->[0] ? $self->{params}->[0] : $#$chromosomes/2;
		my $sd = defined $self->{params}->[1] ? $self->{params}->[1] : $#$chromosomes;
		push @parents, 
			pack 'I*', map { int $_ % $high } random_normal($parents, $av, $sd)  
				for 0..$#$chromosomes;
	}elsif($self->{type} eq q/beta/){
		my $aa = defined $self->{params}->[0] ? $self->{params}->[0] : $parents;
		my $bb = defined $self->{params}->[1] ? $self->{params}->[1] : $parents;
		push @parents, 
			pack 'I*', map { int($_ * $high) } random_beta($parents, $aa, $bb)
				for 0..$#$chromosomes;
	}elsif($self->{type} eq q/binomial/){
		push @parents, 
			pack 'I*', random_binomial($parents, $#$chromosomes, rand) 
				for 0..$#$chromosomes;
	}elsif($self->{type} eq q/chi_square/){
		my $df = defined $self->{params}->[0] ? $self->{params}->[0] : $#$chromosomes;
		push @parents,
			pack 'I*', map { int $_ % $high } random_chi_square($parents, $df)
				for 0..$#$chromosomes;
	}elsif($self->{type} eq q/exponential/){
		my $av = defined $self->{params}->[0] ? $self->{params}->[0] : $#$chromosomes/2;
		push @parents, 
			pack 'I*', map { int $_ % $high } random_exponential($parents, $av)  
				for 0..$#$chromosomes;
	}elsif($self->{type} eq q/poisson/){
		my $mu = defined $self->{params}->[0] ? $self->{params}->[0] : $#$chromosomes/2;
		push @parents,
			pack 'I*', map { int $_ % $high } random_poisson($parents, $mu)
				for 0..$#$chromosomes;
	}else{
		die qq/Unknown distribution "$self->{type}" in "selection"!\n/;
	}
	
	#-------------------------------------------------------------------
	return \@parents;
}
#=======================================================================

1;
