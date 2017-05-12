package Algorithm::Genetic::Diploid::Factory;
use strict;

our $AUTOLOAD;

my %defaults = (
	'experiment' => 'Algorithm::Genetic::Diploid::Experiment',	
	'population' => 'Algorithm::Genetic::Diploid::Population',
	'individual' => 'Algorithm::Genetic::Diploid::Individual',
	'chromosome' => 'Algorithm::Genetic::Diploid::Chromosome',
	'gene'       => 'Algorithm::Genetic::Diploid::Gene',
);

=head1 NAME

Algorithm::Genetic::Diploid::Factory - creator of objects

=head1 METHODS

=over

=item new

Constructor takes named arguments. Key is a short name (e.g. 'gene'), value is a fully
qualified package name from which to instantiate objects identified by the short name.

=cut

sub new {
	my $class = shift;
	my %self = ( %defaults, @_ );
	for my $class ( values %self ) {
		if ( not $::{ $class . '::' } ) {
			eval "require $class";
			if ( $@ ) {
				die $@;
			}
		}
	}
	return bless \%self, $class;
}

=item create

Given a short hand name, instantiates an object whose package name is associated with
that short name.

=cut

sub create {
	my ( $self, $thing, @args ) = @_;
	return $self->{$thing}->new(@args);
}

=item create_experiment

Instantiates a L<Algorithm::Genetic::Diploid::Experiment> object, or subclass thereof.

=item create_population

Instantiates a L<Algorithm::Genetic::Diploid::Population> object, or subclass thereof.

=item create_individual

Instantiates a L<Algorithm::Genetic::Diploid::Individual> object, or subclass thereof.

=item create_chromosome

Instantiates a L<Algorithm::Genetic::Diploid::Chromosome> object, or subclass thereof.

=item create_gene

Instantiates a L<Algorithm::Genetic::Diploid::Gene> object, or subclass thereof.

=back

=cut

sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.+://;
	if ( $method =~ /^create_(.+)$/ ) {
		my $thing = $1;
		$self->create( $thing, @_ );
	}
}

1;