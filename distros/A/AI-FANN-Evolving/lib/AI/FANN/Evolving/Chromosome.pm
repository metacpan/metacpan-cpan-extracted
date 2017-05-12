package AI::FANN::Evolving::Chromosome;
use strict;
use AI::FANN::Evolving;
use AI::FANN::Evolving::Experiment;
use Algorithm::Genetic::Diploid;
use base 'Algorithm::Genetic::Diploid::Chromosome';

my $log = __PACKAGE__->logger;

=head1 NAME

AI::FANN::Evolving::Chromosome - chromosome of an evolving, diploid AI

=head1 METHODS

=over

=item recombine

Recombines properties of the AI during meiosis in proportion to the crossover_rate

=cut

sub recombine {
	$log->debug("recombining chromosomes");
	# get the genes and columns for the two chromosomes
	my ( $chr1, $chr2 ) = @_;
	my ( $gen1 ) = map { $_->mutate } $chr1->genes;
	my ( $gen2 ) = map { $_->mutate } $chr2->genes;	
	my ( $ann1, $ann2 ) = ( $gen1->ann, $gen2->ann );
	$ann1->recombine($ann2,$chr1->experiment->crossover_rate);
	
	# assign the genes to the chromosomes (this because they are clones
	# so we can't use the old object reference)
	$chr1->genes($gen1);
	$chr2->genes($gen2);	
}

=item clone

Clones the object

=back

=cut

sub clone {
	my $self = shift;
	my @genes = $self->genes;
	my $self_clone = $self->SUPER::clone;
	$self_clone->genes( map { $_->clone } @genes );
	return $self_clone;
}

1;
