package Algorithm::Genetic::Diploid::Population;
use strict;
use List::Util qw'sum shuffle';
use Algorithm::Genetic::Diploid::Base;
use base 'Algorithm::Genetic::Diploid::Base';

my $log = __PACKAGE__->logger;

=head1 NAME

Algorithm::Genetic::Diploid::Population - A population of individuals that turns over

=head1 METHODS

=over

=item new

Constructor takes named arguments, creates a default, empty list of individuals

=cut

sub new {
	shift->SUPER::new(
		'individuals' => [],
		@_,
	);
}

=item individuals

Getter and setter for the list of individuals

=cut

sub individuals {
	my $self = shift;
	if ( @_ ) {
		$self->{'individuals'} = \@_;
		$log->debug("assigning ".scalar(@_)." individuals to population");
	}
	return @{ $self->{'individuals'} };
}

=item turnover

Moves the population on to the next generation, i.e.
1. compute fitness of all individuals
2. mate up to reproduction rate in proportion to fitness

=cut

sub turnover {
	my ( $self, $gen, $env, $optimum ) = @_;
	my $log = $self->logger;
	$log->debug("going to breed generation $gen against optimum $optimum");
	
	# sort all individuals by fitness, creates array refs 
	# where 0 element is Individual, 1 element is its fitness
	my @fittest = sort { $a->[1] <=> $b->[1] } 
	               map { [ $_, $_->fitness($optimum,$env) ] } 
	               $self->individuals;
	$log->debug("sorted current generation by fitness");
	$log->info("*** fittest at generation $gen: ".$fittest[0]->[0]->phenotype($env));
	               
	# get the highest index of Individual 
	# that still gets to reproduce
	my $maxidx = int( $self->experiment->reproduction_rate * $#fittest );
	$log->debug("individuals up to index $maxidx will breed");
	
	# take the slice of Individuals that get to reproduce
	my @breeders = @fittest[ 0 .. $maxidx ];
	$log->debug("number of breeders: ".scalar(@breeders));
	
	# compute the total fitness, to know how much each breeder gets to
	# contribute to the next generation
	my $total_fitness = sum map { $_->[1] } @breeders;
	$log->debug("total fitness is $total_fitness");
	
	# compute the population size, which we need to divide up over the
	# breeders in proportion of their fitness relative to total fitness
	my $popsize = scalar $self->individuals;
	$log->debug("population size will be $popsize");
	
	# here we make breeding pairs
	my @children;
	ORGY: while( @children < $popsize ) {
		for my $i ( 0 .. $#breeders ) {
			my $quotum_i = $breeders[$i]->[1] / $total_fitness * $popsize * 2;
			for my $j ( 0 .. $#breeders ) {
				my $quotum_j = $breeders[$j]->[1] / $total_fitness * $popsize * 2;
				my $count_i  = $breeders[$i]->[0]->child_count;
				my $count_j  = $breeders[$j]->[0]->child_count;
				if ( $count_i < $quotum_i && $count_j < $quotum_j ) {
					push @children, $breeders[$i]->[0]->breed($breeders[$j]->[0]);
					$log->debug("bred child ".scalar(@children)." by pairing $i and $j");
					last ORGY if @children == $popsize;
				}				
			}
		}
	}
	
	my %genes = map { $_->id => 1 } map { $_->genes } map { $_->chromosomes } @children;
	$log->debug("generation $gen has ".scalar(keys(%genes))." distinct genes");
	
	# now the population consists of the children
	$self->individuals(@children);
	return @{ $fittest[0] };
}

=back

=cut

1;
