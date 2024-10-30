package Astro::FITS::HdrTrans;

=head1 NAME

Astro::FITS::HdrTrans - Translate FITS headers to standardised form

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans qw/ translate_from_FITS
                                translate_to_FITS /;

  %generic_headers = translate_from_FITS(\%FITS_headers,
                                     frameset => $frameset);

  %FITS_headers = translate_to_FITS(\%generic_headers);

  @headers = Astro::FITS::HdrTrans->generic_headers();
  @classes = Astro::FITS::HdrTrans->translation_classes();

=head1 DESCRIPTION

Converts information contained in instrument-specific FITS headers to
and from generic headers. A list of generic headers are given at the end
of the module documentation.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use vars qw/ $VERSION $DEBUG @ISA /;

use Exporter 'import';
our @EXPORT_OK = qw( translate_from_FITS translate_to_FITS );

$VERSION = '1.66';
$DEBUG   = 0;

# The reference list of classes we can try This list should be
# extended whenever new translation tables are added.  They should
# have a corresponding Astro::FITS::HdrTrans:: module available Note
# that there are more perl modules in the distribution than are listed
# here. This is because some perl modules provide a base set of
# translations shared by multiple instruments.

my @REF_CLASS_LIST = qw/ ACSIS IRCAM CGS4New CGS4Old UIST UFTI RxH3
                         JCMT_GSD JCMT_GSD_DB MICHELLE SCUBA SCUBA2 UKIRTDB WFCAM IRIS2 SOFI
                         ISAAC NACO INGRID GMOS SPEX NIRI ClassicCam CURVE LCOSBIG_CC
                         LCOSBIG_1m0 LCOSBIG_0m4 LCOSBIG_0m8 LCOSINISTRO_1m0
                         LCOFLOYDS LCOMEROPE LCOSPECTRAL LCOFLI_1m0/;

# This is the actual list that is currently supported. It should always
# default to the reference list
my @local_class_list = @REF_CLASS_LIST;

=head1 CLASS METHODS

Some class methods are available

=over 4

=item B<generic_headers>

Returns a list of all the generic headers that can in principal be
used for header translation. Note that not all the instruments support
all the headers.

 @hdrs = Astro::FITS::HdrTrans->generic_headers();

=cut

my @generic_headers = qw(
                          AIRMASS_START
                          AIRMASS_END
                          ALTITUDE
                          AMBIENT_TEMPERATURE
                          AZIMUTH_START
                          AZIMUTH_END
                          BACKEND
                          BACKEND_SECTIONS
                          BANDWIDTH_MODE
                          BOLOMETERS
                          CAMERA
                          CAMERA_NUMBER
                          CHOP_ANGLE
                          CHOP_COORDINATE_SYSTEM
                          CHOP_FREQUENCY
                          CHOP_THROW
                          CONFIGURATION_INDEX
                          COORDINATE_SYSTEM
                          COORDINATE_UNITS
                          COORDINATE_TYPE
                          CYCLE_LENGTH
                          DATA_UNITS
                          DEC_BASE
                          DEC_SCALE
                          DEC_SCALE_UNITS
                          DEC_TELESCOPE_OFFSET
                          DETECTOR_BIAS
                          DETECTOR_INDEX
                          DETECTOR_READ_TYPE
                          DOME_OPEN
                          DR_GROUP
                          DR_RECIPE
                          ELEVATION_START
                          ELEVATION_END
                          EPOCH
                          EQUINOX
                          EXPOSURE_TIME
                          FILE_FORMAT
                          FILENAME
                          FILTER
                          FRONTEND
                          FOURIER_TRANSFORM_SPECTROMETER
                          GAIN
                          GALACTIC_LATITUDE
                          GALACTIC_LONGITUDE
                          GRATING_DISPERSION
                          GRATING_NAME
                          GRATING_ORDER
                          GRATING_WAVELENGTH
                          HUMIDITY
                          INSTRUMENT
                          INST_DHS
                          LATITUDE
                          LONGITUDE
                          MSBID
                          MSB_TRANSACTION_ID
                          NSCAN_POSITIONS
                          NUMBER_OF_COADDS
                          NUMBER_OF_CYCLES
                          NUMBER_OF_DETECTORS
                          NUMBER_OF_EXPOSURES
                          NUMBER_OF_FREQUENCIES
                          NUMBER_OF_JITTER_POSITIONS
                          NUMBER_OF_MICROSTEP_POSITIONS
                          NUMBER_OF_OFFSETS
                          NUMBER_OF_READS
                          NUMBER_OF_SUBFRAMES
                          NUMBER_OF_SUBSCANS
                          OBJECT
                          OBSERVATION_ID
                          OBSERVATION_ID_SUBSYSTEM
                          OBSERVATION_MODE
                          OBSERVATION_NUMBER
                          OBSERVATION_TYPE
                          OBSERVED_SIDEBAND
                          POLARIMETER
                          POLARIMETRY
                          PROJECT
                          RA_BASE
                          RA_SCALE
                          RA_SCALE_UNITS
                          RA_TELESCOPE_OFFSET
                          RECEIVER_TEMPERATURE
                          REFERENCE_LOCATION
                          REMOTE
                          REST_FREQUENCY
                          ROTATION
                          SAMPLE_MODE
                          SAMPLING
                          SCAN_INCREMENT
                          SCAN_PATTERN
                          SEEING
                          SHIFT_TYPE
                          SIDEBAND_MODE
                          SLIT_ANGLE
                          SLIT_NAME
                          SLIT_WIDTH
                          SPECIES
                          SPECTRUM_NUMBER
                          SPEED_GAIN
                          STANDARD
                          SUBSYSTEM_NUMBER
                          SUBSYSTEM_IDKEY
                          SURVEY
                          SWITCH_MODE
                          SYSTEM_TEMPERATURE
                          SYSTEM_VELOCITY
                          TAI_UTC_CORRECTION
                          TAU
                          TELESCOPE
                          TILE_NUMBER
                          TRACKING_SIDEBAND
                          TRANSITION
                          USER_AZIMUTH_CORRECTION
                          USER_ELEVATION_CORRECTION
                          UTDATE
                          UTEND
                          UTSTART
                          UT1_UTC_CORRECTION
                          VELOCITY
                          VELOCITY_REFERENCE_FRAME
                          VELOCITY_TYPE
                          WAVEPLATE_ANGLE
                          WIND_BLIND
                          XBINNING
                          YBINNING
                          X_APERTURE
                          Y_APERTURE
                          X_BASE
                          Y_BASE
                          X_OFFSET
                          Y_OFFSET
                          X_REFERENCE_PIXEL
                          Y_REFERENCE_PIXEL
                          X_REQUESTED
                          Y_REQUESTED
                          X_SCALE
                          Y_SCALE
                          X_DIM
                          Y_DIM
                          X_LOWER_BOUND
                          X_UPPER_BOUND
                          Y_LOWER_BOUND
                          Y_UPPER_BOUND
                          ZENITH_DISTANCE_START
                          ZENITH_DISTANCE_END
                       );

sub generic_headers {
  my $class = shift;
  return @generic_headers;
}

=item B<translation_classes>

Return the names of all the translation classes that will be
tried when translating a FITS header.

 @classes = Astro::FITS::HdrTrans->translation_classes();

If arguments are supplied, the list of translation classes is
set to the supplied values.

 Astro::FITS::HdrTrans->translation_classes( @new );

=cut

sub translation_classes {
  my $class = shift;
  if (@_) {
    @local_class_list = @_;
  }
  return @local_class_list;
}

=item B<reset_translation_classes>

Revert back to the reference list of translation classes.

  Astro::FITS::HdrTrans->reset_translation_classes;

Useful if the list has been modified for a specific translation.

=cut

sub reset_classes {
  my $class = shift;
  @local_class_list = @REF_CLASS_LIST;
}

=item B<push_class>

Allows additional classes to be pushed on the list of valid
translation classes.

  Astro::FITS::HdrTrans->push_class( $class );

The class[es] can be specified either as a list or a reference to
an array.

=cut

sub push_class {
  my $class = shift;
  my @new = @_;

  # check for array ref
  @new = ( ref($new[0]) ? @{ $new[0] } : @new );
  push(@local_class_list, @new);
  return @local_class_list;
}

=back

=head1 FUNCTIONS

The following functions are available. They can be exported but are
not exported by default.

=over 4

=item B<translate_from_FITS>

Converts a hash containing instrument-specific FITS headers into a hash
containing generic headers.

  %generic_headers = translate_from_FITS(\%FITS_headers,
                                         class => \@classes,
                                         prefix => 'ORAC_',
                                         frameset => $frameset,
                                        );

This method takes a reference to a hash containing untranslated headers,
and a hash reference containing the following optional keys:

=over 8

=item *

class - A reference to a list of subclasses to try to use for header
translations. This list overrides the default list. If left blank, the
default list will be used, as returned by the C<translation_classes>
method. This is sometimes required to break degeneracy when you know
you have a limited set of valid instruments.

=item *

frameset - An AST FrameSet describing the WCS. The WCS in this
FrameSet will override any WCS information contained in the FITS
headers.

=item *

prefix - A string prefix to add to the front of every translated header name.
For example, if this prefix is set to 'ORAC_', then the translated header
for the instrument value, whose key is normally 'INSTRUMENT', will have a
key named 'ORAC_INSTRUMENT'. The original keys will not be in the
returned hash. If left blank, no prefix will be added.

=back

This method returns a hash of generic headers. This function dies if
the header translation fails in any way.

=cut

sub translate_from_FITS {
  my $FITS_header = shift;
  my %options = @_;

  # translation classes
  my @classes;
  if ( exists( $options{class} ) &&
       defined( $options{class} ) &&
       ref( $options{class} ) eq 'ARRAY' ) {
    @classes = @{$options{class}};
  }

  my $prefix;
  if ( exists( $options{prefix} ) &&
       defined( $options{prefix} ) ) {
    $prefix = $options{prefix};
  }

  my $frameset;
  if ( exists( $options{frameset} ) &&
       defined( $options{frameset} ) ) {
    $frameset = $options{frameset};
  }

  # determine which class can be used for the translation
  my $class = determine_class( $FITS_header, \@classes, 1 );

  # we know this class is already loaded so do the translation
  return $class->translate_from_FITS( $FITS_header,
                                      prefix => $prefix,
                                      frameset => $frameset );

}

=item B<translate_to_FITS>

Converts a hash containing generic headers into one containing
instrument-specific FITS headers.

  %FITS_headers = translate_to_FITS(\%generic_headers,
                                    class => \@classes,
                                   );

This method takes a reference to a hash containing untranslated
headers, and a hash reference containing the following optional
keys:

=over 8

=item *

class - A reference to a list of subclasses to try to use for header
translations. This list overrides the default list. If left blank, the
default list will be used.

=item *

prefix - A string prefix to remove from the generic header key
before doing header translation. Why you would want to do this
is if you've used a prefix in the C<translate_from_FITS> call, and
want to translate back from the generic headers returned from
that method. If left blank, no prefix will be removed.

=back

This method returns a hash of instrument-specific headers.  This
function dies if the header translation fails in any way.

=cut

sub translate_to_FITS {
  my $generic_header = shift;
  my %options = @_;

  my @classes;
  if ( exists( $options{class} ) &&
       defined( $options{class} ) &&
       ref( $options{class} ) eq 'ARRAY' ) {
    @classes = @{$options{class}};
  }


  my $prefix;
  if ( exists( $options{prefix} ) &&
       defined( $options{prefix} ) ) {
    $prefix = $options{prefix};
  } else {
    $prefix = '';
  }

  # We need to strip off any prefix before figuring out what
  # class we need to use.
  my %stripped_header = clean_prefix( $generic_header, $prefix );

  # Check the UTSTART and UTEND headers to make sure they're
  # Time::Piece objects.
  for my $h (qw/ UTSTART UTEND / ) {
    if ( exists( $stripped_header{$h} ) &&
         defined( $stripped_header{$h} ) &&
         ! UNIVERSAL::isa( $stripped_header{$h}, "Time::Piece" ) ) {
      warnings::warnif( "Warning: $h generic header is not a Time::Piece object" );
    }
  }

  # determine which class can be used for the translation
  my $class = determine_class( \%stripped_header, \@classes, 0 );

  return $class->translate_to_FITS( \%stripped_header );

}

=item B<determine_class>

Determine which class should be used for the translation (either way).
It is given a reference to the header hash and a reference to an array
of classes which can be queried.

  $class = determine_class( \%hdr, \@classes, $fromfits );

The classes are loaded for each test. Failure to load indicates failure
to translate. If the classes are undefined, the default internal list
will be used.

The third argument is a boolean indicating whether the class is being
used to translate from FITS (true) or to FITS (false). This is used
for error message clarity.

This function can be useful to allow a single header translation to be
calculated without requiring that all translation are performed. For example,

  $class = Astro::FITS::HdrTrans::determine_class( \%hdr, undef, 1 );
  $value = $class->to_OBSERVATION_ID( \%hdr, $frameset );

If the key _TRANSLATION_CLASS exists and this class allows translation
and no override classes have been specified, that class is returned
without checking all classes. This key is automatically filled in when
a translation from fits is executed.

=cut

sub determine_class {
  my $hdr = shift;
  my $classes = shift;
  my $fromfits = shift;

  # Default classes if empty or undef
  my @defclasses = __PACKAGE__->translation_classes;
  if (!defined $classes || !@$classes) {
    # see if we have an override
    if (exists $hdr->{_TRANSLATION_CLASS} && defined $hdr->{_TRANSLATION_CLASS}) {
      my $class = $hdr->{_TRANSLATION_CLASS};
      my $loaded = eval "require $class";
      if ($loaded) {
        if ($class->can("can_translate") && $class->can_translate($hdr) ) {
          return $class;
        }
      }
    }
    # did not have an override so use defaults
    $classes = \@defclasses;
  }

  # Determine the class name so we can use the appropriate subclass
  # for header translations. We're going to use the "can_translate" method
  # in each subclass listed in @$classes.
  my %result = ();
  my $base = "Astro::FITS::HdrTrans::";
  foreach my $subclass ( @$classes ) {

    my $class = $base.$subclass;

    print "Trying class $class\n" if $DEBUG;

    # Try a class and if it fails to load, skip
    eval "require $class";
    if ( $@ ) {
      print "Error loading class $class: $@\n" if $DEBUG;
    }
    next if ( $@ );
    if ( $class->can("can_translate") ) {
      if ( $class->can_translate( $hdr ) ) {
        print "Class $class matches\n" if $DEBUG;
        $result{$subclass}++;
      }
    } else {
      # What to do, what to do?
    }
  }

  if ( ( scalar keys %result ) > 1 ) {
    croak "Ambiguities in determining which header translations to use (".
      join(",",keys %result).")";
  }

  if ( ( scalar keys %result ) == 0 ) {
    # We couldn't figure out which one to use.
    croak "Unable to determine header translation subclass. No matches for these headers when trying to convert "
      . ($fromfits ? 'from' : 'to' )
        . " FITS using the following classes: ".join(", ",@$classes);
  }

  # The class we wanted is the only key in the hash
  my @matched = keys %result;
  my $class = $base . $matched[0];

  return $class;
}

=item B<clean_prefix>

If a prefix has been used and a targetted conversion is required (which will not understand
the prefix) the prefix must first be removed. This function will remove the preifx, only
returning headers that contained the prefix.

  %cleaned = clean_prefix( \%header, $prefix );

If prefix is an empty string or undefined, returns all headers.

=cut

sub clean_prefix {
  my $href = shift;
  my $prefix = shift;
  return %$href unless $prefix;

  my %stripped_header;
  while ( my ( $key, $value ) = each( %{$href} ) ) {
    if ($key eq '_TRANSLATION_CLASS') {
      # this should be retained
      $stripped_header{$key} = $value;
    } elsif ($key =~ /^$prefix/) {
      # only propagate keys that contain the prefix
      $key =~ s/^$prefix//;
      $stripped_header{$key} = $value;
    }
  }
  return %stripped_header;
}

=back

=head1 NOTES

Individual translations can be invoked explicitly if a class name is known.
The syntax for conversion from a FITS header to generic value is

  $result = $class->to_GENERIC_KEYWORD( \%header, $frameset );

Frameset information (Starlink::AST object) is optional.

The syntax for conversion from generic to FITS headers is:

  %fits = $class->from_GENERIC_KEYWORD( \%translated_hdr );

Note that the conversion to FITS can result in multiple header items
and can require more than a single generic translated header item.

If you are using a prefix, the general paradigm for converting a
translated header back to FITS is:

  my %cleaned = Astro::FITS::HdrTrans::clean_prefix( \%translated_hdr, $prefix );
  my $class = Astro::FITS::HdrTrans::determine_class( \%cleaned, undef, 0 );
  my %fits = $class->from_DR_RECIPE( \%cleaned );


=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Malcolm J. Currie E<lt>mjc@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2007-2009, 2013 Science and Technology Facilities Council.
Copyright (C) 2003-2007 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either Version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA  02111-1307, USA.

=cut

1;
