package Astro::App::Satpass2::Wrap::Array;

use 5.008;

use strict;
use warnings;

use Astro::App::Satpass2::Utils qw{ ARRAY_REF @CARP_NOT };

our $VERSION = '0.040';

sub new {
    my ( $class, $array ) = @_;
    ref $class and $class = ref $class;
    if ( ARRAY_REF ne ref $array ) {
	require Carp;
	Carp::croak( 'Argument must be an array reference' );
    }
    return bless $array, $class;
}

sub dereference {
    my ( $self ) = @_;
    return @{ $self };
}

1;

__END__

=head1 NAME

Astro::App::Satpass2::Wrap::Array - Wrap an array reference.

=head1 SYNOPSIS

 use Astro::App::Satpass2::Wrap::Array;

 my @array = qw{ foo bar baz };
 my $wrap = Astro::App::Satpass2::Wrap::Array->new( \@array );
 foreach ( $wrap->dereference() ) {
     say;
 }

=head1 DESCRIPTION

This class is private to the C<Astro-App-Satpass2> package. It can be
changed or revoked without notice. All documentation is for the benefit
of the author.

This class exists to mark arguments to C<Template-Toolkit> that, when
passed back through to other code, need to be dereferenced before use.

Well, honestly, it exists because I can't figure out how to get
C<Template-Toolkit> to do this on its own, and having all the relevant
C<Astro-App-Satpass2> methods simply expand all array references has too
many undesirable side effects. So what I intend to do is bless arguments
that are to be expanded into this class.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $wrap = Astro::App::Satpass2::Wrap::Array->new( \@foo );

This method instantiates the object. The array reference is required,
and that array reference is blessed into this class.

=head2 dereference

 my @array = $wrap->dereference();

This method returns the elements in the original array.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
