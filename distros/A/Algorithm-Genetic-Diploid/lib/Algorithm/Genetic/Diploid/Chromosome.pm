package Algorithm::Genetic::Diploid::Chromosome;
use strict;
use Algorithm::Genetic::Diploid::Base;
use base 'Algorithm::Genetic::Diploid::Base';

my $log = __PACKAGE__->logger;

=head1 NAME

Algorithm::Genetic::Diploid::Chromosome - one of a pair of homologous chromosomes

=head1 METHODS

=over

=item new

Constructor takes named arguments. Creates a default list of genes and chromosome number.

=cut

sub new {	
	shift->SUPER::new(
		'genes'  => [],
		'number' => 1,
		@_,
	);
}

=item genes

Sets and gets list of genes on the chromosome

=cut

sub genes {
	my $self = shift;
	if ( @_ ) {
		$log->debug("assigning new genes: @_");
		$self->{'genes'} = \@_;
	}
	return @{ $self->{'genes'} };
}

=item number

Sets and gets chromosome number, i.e. in humans that would be 1..22, X, Y

=cut

sub number {
	my $self = shift;
	$self->{'number'} = shift if @_;
	return $self->{'number'};
}

=item recombine

Exchanges genes with homologous chromosome (the argument to this method).

=cut

sub recombine {
	my ( $self, $other ) = @_;
	my @g1 = $self->genes;
	my @g2 = $other->genes;
	for my $i ( 0 .. $#g1 ) {
		if ( $self->experiment->crossover_rate > rand(1) ) {
			( $g1[$i], $g2[$i] ) = ( $g2[$i]->mutate, $g1[$i]->mutate );
		}
	}
	$self->genes(@g1);
	$other->genes(@g2);
}

=back

=cut

1;