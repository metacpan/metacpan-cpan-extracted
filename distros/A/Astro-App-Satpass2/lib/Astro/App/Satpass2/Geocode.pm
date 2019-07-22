package Astro::App::Satpass2::Geocode;

use 5.008;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2::Copier };

use Astro::App::Satpass2::Utils qw{
    instance
    load_package
    @CARP_NOT
};
use Astro::App::Satpass2::Warner;

our $VERSION = '0.040';

sub new {
    my ( $class, %args ) = @_;
    $class = ref $class || $class;

    my $self = {};

    bless $self, $class;

    $self->warner( delete $args{warner} );

    __PACKAGE__ eq $class
	and $self->wail(
	"Class $class may not be instantiated directly",
    );

    my $geocoder_class = $class->GEOCODER_CLASS();
    load_package( $geocoder_class )
	or $self->wail(
	"Unable to load $geocoder_class",
    );

    $self->geocoder( delete $args{geocoder} );

    $self->init( %args );

    return $self;
}

sub attribute_names {
    my ( $self ) = @_;
    return ( qw{ geocoder }, $self->SUPER::attribute_names() );
}

sub geocode {
    my ( $self ) = @_;
    $self->wail(
	"The @{[ ref $self ]} class does not support geocoding. Use a subclass"
    );
    return;	# wail() does not return, but Perl::Critic does not
		# know this.
}

sub geocoder {
    my ( $self, @args ) = @_;

    if ( @args ) {
	my $geocoder = shift @args;
	my $geocoder_class = $self->GEOCODER_CLASS();
	defined $geocoder
	    or $geocoder = $geocoder_class->new();
	ref $geocoder
	    or $geocoder = $geocoder->new();
	instance( $geocoder, $geocoder_class )
	    or $self->wail(
	    "Argument 'geocoder' must be an instance of $geocoder_class"
	);
	$self->{geocoder} = $geocoder;
	return $self;
    } else {
	return $self->{geocoder};
    }
}

sub __geocode_failure {
    my ( $self ) = @_;
    my $geocoder = $self->geocoder();
    my $resp = $geocoder->response()
	or $self->wail( 'No HTTP response found' );
    $resp->is_success()
	and $self->wail( 'No match found for location' );
    $self->wail( $resp->status_line() );
    return;	# wail() does not return, but Perl::Critic does not know
		# this.
}

__PACKAGE__->create_attribute_methods();

1;

__END__

=head1 NAME

Astro::App::Satpass2::Geocode - Abstract geocoding wrapper class.

=head1 SYNOPSIS

 # Assuming Astro::App::Satpass2::Geocode::OSM is a
 # subclass of this class,
 
 use Astro::App::Satpass2::Geocode::OSM;
 use YAML;
 
 my $geocoder = Astro::App::Satpass2::Geocode::OSM->new();
 print Dump( $geocoder->geocode(
     '1600 Pennsylvania Ave, Washington DC'
 ) );

=head1 DESCRIPTION

This class is an abstract wrapper for C<Astro::App::Satpass2> geocoding
functionality. It may not be instantiated directly.

The purpose of the wrapper is to provide a consistent interface to the
various C<Geo::Coder::*> modules that provide geocoding services.

This class is a subclass of
L<Astro::App::Satpass2::Copier|Astro::App::Satpass2::Copier>.

=head1 METHODS

This class supports the following public methods in addition to those
provided by its superclass:

=head2 new

 # Assuming Astro::App::Satpass2::Geocode::OSM is a subclass
 # of this class,
 my $geocoder = Astro::App::Satpass2::Geocode::OSM->new();

This static method instantiates a new geocoder object. It may not be
called on this class.

This method takes arguments as name/value pairs. The supported arguments
are L<geocoder|/geocoder> and
L<warner|Astro::App::Satpass2::Copier/warner>, which correspond to the
same-named mutators.

=head2 geocode

 my @rslt = $geocoder->geocode(
     '1600 Pennsylvania Ave, Washington DC',
 );

This method B<must> be overridden by any subclass. The subclass
B<must not> call C<< $self->SUPER::geocode >>.

This method geocodes the given location, using the underlying geocoder
object, and returns any results found. The result is an array of hash
references, each hash representing one location. The hashes must have
the following keys:

=over

=item description

This is a description of the location. It is expected to be an address
derived from the information returned by the geocoder.

=item latitude

This is the latitude of the location, in degrees, with south latitude
negative.

=item longitude

This is the longitude of the location, in degrees, with west longitude
negative.

=back

=head2 geocoder

 $geocoder->geocoder(
     Geo::Coder::OSM->new(),
 );
 my $gc = $geocoder->geocoder();

This method is an accessor/mutator to the underlying geocoder object.

If called with no arguments, it simply returns the underlying geocoder
object.

If called with arguments, it sets the geocoder object. The argument must
be either C<undef>, a class name, or an object. If a class name, the
class is instantiated. If C<undef>, the default class is instantiated.
In any event, the object must be a subclass of the default class.

=head2 GEOCODER_CLASS

 say 'Geocoder class is ', $geocoder->GEOCODER_CLASS;

This method B<must> be overridden by any subclass. It B<may> be
implemented by C<< use constant >>. The override B<must> support being
called as either a static or a normal method.

This method specifies the name of the underlying geocoder class.

=head2 GEOCODER_SITE

 say 'Geocoder site is ', $geocoder->GEOCODER_SITE;

This method B<must> be overridden by any subclass. It B<may> be
implemented by C<< use constant >>. The override B<must> support being
called as either a static or a normal method.

This method specifies the URL of the web site providing the service. It
is intended to be used to probe the web site for availability.

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
