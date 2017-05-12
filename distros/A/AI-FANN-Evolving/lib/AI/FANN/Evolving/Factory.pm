package AI::FANN::Evolving::Factory;
use strict;
use Algorithm::Genetic::Diploid;
use base 'Algorithm::Genetic::Diploid::Factory';

our $AUTOLOAD;

my %defaults = (
	'experiment' => 'AI::FANN::Evolving::Experiment',
	'chromosome' => 'AI::FANN::Evolving::Chromosome',
	'gene'       => 'AI::FANN::Evolving::Gene',
	'traindata'  => 'AI::FANN::Evolving::TrainData',
);

=head1 NAME

AI::FANN::Evolving::Factory - creator of objects

=head1 METHODS

=over

=item new

Constructor takes named arguments. Key is a short name (e.g. 'traindata'), value is a 
fully qualified package name (e.g. L<AI::FANN::TrainData>) from which to instantiate 
objects identified by the short name.

=back

=cut

sub new { shift->SUPER::new(%defaults,@_) }

1;