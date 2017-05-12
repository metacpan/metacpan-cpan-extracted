package Algorithm::Genetic::Diploid::Individual;
use strict;
use List::Util qw'sum shuffle';
use Algorithm::Genetic::Diploid::Base;
use base 'Algorithm::Genetic::Diploid::Base';

my $log = __PACKAGE__->logger;

=head1 NAME

Algorithm::Genetic::Diploid::Individual - an individual that reproduces sexually

=head1 METHODS

=over

=item new

Constructor takes named arguments, sets a default, empty list of chromosomes and
a default child count of zero

=cut

sub new {
	shift->SUPER::new(
		'chromosomes' => [],
		'child_count' => 0,
		@_,
	);
}

=item child_count

Getter for the number of children

=cut

sub child_count {
	shift->{'child_count'};
}

# private method to increment 
# child count after breeding
sub _increment_cc { shift->{'child_count'}++ }

=item chromosomes

Getter and setter for the list of chromosomes

=cut

sub chromosomes {
	my $self = shift;
	if ( @_ ) {
		$log->debug("assigning new chromosomes: @_");
		$self->{'chromosomes'} = \@_;
	}
	return @{ $self->{'chromosomes'} }
}

=item meiosis

Meiosis produces a gamete, i.e. n chromosomes that have mutated and recombined

=cut

sub meiosis {
	my $self = shift;
	
	# this is basically mitosis: cloning of chromosomes
	my @chro = map { $_->clone } $self->chromosomes;
	$log->debug("have cloned ".scalar(@chro)." chromosomes (meiosis II)");
	
	# create pairs of homologous chromosomes, i.e. metafase
	my @pairs;
	for my $i ( 0 .. $#chro - 1 ) {
		for my $j ( ( $i + 1 ) .. $#chro ) {
			if ( $chro[$i]->number == $chro[$j]->number ) {
				push @pairs, [ $chro[$i], $chro[$j] ];
			}	
		}
	}
	
	# recombination happens during metafase
	for my $pair ( @pairs ) {
		$pair->[0]->recombine( $pair->[1] );
	}
	
	# telofase: homologues segregate
	my @gamete = map { $_->[0] } map { [ shuffle @{ $_ } ] } @pairs;
	return @gamete;
}

=item breed

Produces a new individual by mating the invocant with the argument

=cut

sub breed {
	my ( $self, $mate ) = @_;
	$log->debug("going to breed $self with $mate");
	$self->_increment_cc;
	$mate->_increment_cc;
	__PACKAGE__->new( 
		'chromosomes' => [ $self->meiosis, $mate->meiosis ] 
	);
}

=item phenotype

Expresses all the genes and weights them to produce a phenotype

=cut

sub phenotype {
	my ( $self, $env ) = @_;
	$log->debug("computing phenotype in environment $env");
	if ( not defined $self->{'phenotype'} ) {
		my @genes = map { $_->genes } $self->chromosomes;
		my $total_weight = sum map { $_->weight } @genes;
		my $products = sum map { $_->weight * $_->express($env) } @genes;
		$self->{'phenotype'} = $products / $total_weight;
	}
	return $self->{'phenotype'};
}

=item fitness

The fitness is the difference between the optimum and the phenotype

=cut

sub fitness {
	my ( $self, $optimum, $env ) = @_;
	my $id = $self->id;
	my $phenotype = $self->phenotype( $env );
	my $diff = abs( $optimum - $phenotype );
	$log->debug("fitness of $id against optimum $optimum is $diff");
	return $diff;
}

=back

=cut

1;
