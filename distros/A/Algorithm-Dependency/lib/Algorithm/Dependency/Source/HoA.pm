package Algorithm::Dependency::Source::HoA;

=pod

=head1 NAME

Algorithm::Dependency::Source::HoA - Source for a HASH of ARRAYs

=head1 SYNOPSIS

  # The basic data structure
  my $deps = {
      foo => [ 'bar', 'baz' ],
      bar => [],
      baz => [ 'bar' ],
      };
  
  # Create the source from it
  my $Source = Algorithm::Dependency::Source::HoA->new( $deps );

=head1 DESCRIPTION

C<Algorithm::Dependency::Source::HoA> implements a
L<source|Algorithm::Dependency::Source> where the items names are provided
in the most simple form, a reference to a C<HASH> of C<ARRAY> references.

=head1 METHODS

This documents the methods differing from the ordinary
L<Algorithm::Dependency::Source> methods.

=cut

use 5.005;
use strict;
use Algorithm::Dependency::Source ();
use Params::Util qw{_HASH _ARRAY0};

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.110';
	@ISA     = 'Algorithm::Dependency::Source';
}





#####################################################################
# Constructor

=pod

=head2 new $filename

When constructing a new C<Algorithm::Dependency::Source::HoA> object, an
argument should be provided of a reference to a HASH of ARRAY references,
containing the names of other HASH elements.

Returns the object, or C<undef> if the structure is not correct.

=cut

sub new {
	my $class = shift;
	my $hash  = _HASH(shift) or return undef;
	foreach my $deps ( values %$hash ) {
		_ARRAY0($deps) or return undef;
	}

	# Get the basic source object
	my $self = $class->SUPER::new() or return undef;

	# Add our arguments
	$self->{hash} = $hash;

	$self;
}





#####################################################################
# Private Methods

sub _load_item_list {
	my $self = shift;

	# Build the item objects from the data
	my $hash  = $self->{hash};
	my @items = map {
		Algorithm::Dependency::Item->new( $_, @{$hash->{$_}} )
		or return undef;
		} keys %$hash;

	\@items;
}

1;

=pod

=head1 SUPPORT

To file a bug against this module, use the CPAN bug tracking system

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Dependency>

For other comments, contact the author.

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 SEE ALSO

L<Algorithm::Dependency>, L<Algorithm::Dependency::Source>

=head1 COPYRIGHT

Copyright 2003 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
