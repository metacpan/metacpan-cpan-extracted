package Algorithm::Dependency::MapReduce;

=pod

=head1 NAME

Algorithm::Dependency::MapReduce - A Map/Reduce implementation for Alg:Dep graphs

=head1 SYNOPSIS

  
=head1 DESCRIPTION

=cut

use 5.006;
use strict;
use warnings;
use Carp                  ();
use Params::Util          qw{ _CODE };
use Algorithm::Dependency ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.03';
	@ISA     = 'Algorithm::Dependency';
}

sub new {
	my $class = shift;
	my %args  = @_;

	# Check params
	unless ( _CODE($args{'map'}) ) {
		Carp::croak("The 'map' param is not a CODE reference");
	}
	unless ( _CODE($args{'reduce'}) ) {
		Carp::croak("The 'reduce' param is not a CODE reference");
	}

	# Hand off to the parent constructor
	my $self = $class->SUPER::new(@_);

	# Add the extra attributes
	$self->{'map'}    = $args{'map'};
	$self->{'reduce'} = $args{'reduce'};

	return $self;
}

sub mapreduce {
	my $self = shift;

	# Fetch the dependencies for the provided params
	my $schedule = $self->schedule(@_);

	# Handle the special cases
	if ( @$schedule == 0 ) {
		# Empty list
		return undef;
	}
	if ( @$schedule == 1 ) {
		# Single element, just map it and return
		return $self->{'map'}->( $self, $schedule->[0] );
	}

	# Map the first two elements and prime the reduction
	my $result = $self->{'reduce'}->( $self,
		scalar($self->{'map'}->( $self, shift(@$schedule) )),
		scalar($self->{'map'}->( $self, shift(@$schedule) )),
	);

	# Process the remaining elements
	while ( @$schedule ) {
		$result = $self->{'reduce'}->( $self,
			$result,
			scalar($self->{'map'}->( $self, shift(@$schedule) )),
		);	
	}

	return $result;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Dependency-MapReduce>

For general comments, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Algorithm::Dependency>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
