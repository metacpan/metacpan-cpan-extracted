package Algorithm::Dependency::Source::HoA;
# ABSTRACT: Source for a HASH of ARRAYs

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod   # The basic data structure
#pod   my $deps = {
#pod       foo => [ 'bar', 'baz' ],
#pod       bar => [],
#pod       baz => [ 'bar' ],
#pod       };
#pod   
#pod   # Create the source from it
#pod   my $Source = Algorithm::Dependency::Source::HoA->new( $deps );
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<Algorithm::Dependency::Source::HoA> implements a
#pod L<source|Algorithm::Dependency::Source> where the items names are provided
#pod in the most simple form, a reference to a C<HASH> of C<ARRAY> references.
#pod
#pod =head1 METHODS
#pod
#pod This documents the methods differing from the ordinary
#pod L<Algorithm::Dependency::Source> methods.
#pod
#pod =cut

use 5.005;
use strict;
use Algorithm::Dependency::Source ();
use Params::Util qw{_HASH _ARRAY0};

our $VERSION = '1.112';
our @ISA     = 'Algorithm::Dependency::Source';


#####################################################################
# Constructor

#pod =pod
#pod
#pod =head2 new $filename
#pod
#pod When constructing a new C<Algorithm::Dependency::Source::HoA> object, an
#pod argument should be provided of a reference to a HASH of ARRAY references,
#pod containing the names of other HASH elements.
#pod
#pod Returns the object, or C<undef> if the structure is not correct.
#pod
#pod =cut

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Dependency::Source::HoA - Source for a HASH of ARRAYs

=head1 VERSION

version 1.112

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

=head2 new $filename

When constructing a new C<Algorithm::Dependency::Source::HoA> object, an
argument should be provided of a reference to a HASH of ARRAY references,
containing the names of other HASH elements.

Returns the object, or C<undef> if the structure is not correct.

=head1 SEE ALSO

L<Algorithm::Dependency>, L<Algorithm::Dependency::Source>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Dependency>
(or L<bug-Algorithm-Dependency@rt.cpan.org|mailto:bug-Algorithm-Dependency@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
