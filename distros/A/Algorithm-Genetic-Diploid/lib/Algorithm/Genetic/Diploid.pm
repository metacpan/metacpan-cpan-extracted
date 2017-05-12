package Algorithm::Genetic::Diploid;
use strict;
use Algorithm::Genetic::Diploid::Logger;
use Algorithm::Genetic::Diploid::Base;
use Algorithm::Genetic::Diploid::Chromosome;
use Algorithm::Genetic::Diploid::Experiment;
use Algorithm::Genetic::Diploid::Gene;
use Algorithm::Genetic::Diploid::Individual;
use Algorithm::Genetic::Diploid::Population;
use Algorithm::Genetic::Diploid::Factory;

our $AUTOLOAD;
our $VERSION = '0.3';

=head1 NAME

Algorithm::Genetic::Diploid - Extensible implementation of a diploid genetic algorithm

=head1 DESCRIPTION

This utility package can be used as the sole import (i.e. just 
C<use Algorithm::Genetic::Diploid;>) to load all the required packages at once. It also
provides static factory methods to create instances of these packages, e.g. C<create_gene>
and so on.

=cut

sub AUTOLOAD {
	my ( $self, %args ) = @_;
	my $method = $AUTOLOAD;
	$method =~ s/.+://;
	if ( $method =~ /^create_(\s+)$/ ) {
		my $class = $1;
		my $package = 'Algorithm::Genetic::Diploid::' . ucfirst $class;
		return $package->new(%args);
	}
}

1;
