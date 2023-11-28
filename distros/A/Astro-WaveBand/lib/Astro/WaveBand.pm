package Astro::WaveBand;

=head1 NAME

Astro::WaveBand - Transparently work in waveband, wavelength or filter

=head1 SYNOPSIS

  use Astro::WaveBand;

  $w = new Astro::WaveBand( Filter => $filter );
  $w = new Astro::WaveBand( Wavelength => $wavelength );

  $w = new Astro::WaveBand( Wavelength => $wavelength,
                            Instrument => 'CGS4' );

  $filter = $w->filter;
  $wave   = $w->wavelength;
  $band   = $w->waveband;    # radio, xray, submm
  $freq   = $w->frequency;
  $wnum   = $w->wavenumber;

  $natural= $w->natural;
  $natural = "$w";

  $w->natural_unit("wavelength");

  if( $w1 > $w2 ) { ... }
  if( $w1 == $w2 ) { ... }

=head1 DESCRIPTION

Class to transparently deal with the conversion between filters,
wavelength, frequency and other methods of specifying a location
in the electro-magentic spectrum.

The class tries to determine the natural form of the numbers such that
a request for a summary of the object when it contains 2.2 microns
would return the filter name but would return the wavelength if it was
not a standard filter. In ambiguous cases an instrument name is
required to decide what to return. In really ambiguous cases the user
can specify the unit in which to display the numbers on
stringification.

Used mainly as a way of storing a single number in a database table
but using logic to determine the number that an observer is most likely
to understand.

Numerical comparison operators can be used to compare two C<Astro::WaveBand>
objects. When checking equality, the "natural" and "instrument" methods are
used, so if two C<Astro::WaveBand> objects return the same value from those
methods, they are considered to be equal. When checking other comparisons
such as greater than, the wavelength is used.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

# Register an Astro::WaveBand warning category
use warnings::register;

# CVS version: $Revision$
our $VERSION = '0.11';

# Overloading
use overload '""' => "natural",
             '==' => "equals",
             '!=' => "not_equals",
             '<=>' => "compare",
             'fallback' => 1;

# Constants

# Speed of light in m/s
use constant CLIGHT => 299792458;

# list of instruments specific to a telescope
my %TELESCOPE = (
               UKIRT => [ "CGS4", "IRCAM", "UFTI", "UIST", "MICHELLE", "WFCAM" ],
               JCMT => [ "SCUBA", "SCUBA-2",
                         "RXA3", "RXA3M", "RXB3", "RXW", "ACSIS", "DAS",
                         "HARP", "ALAIHI", "UU", "AWEOWEO", "KUNTUR" ] );

# Continuum Filters are keyed by instrument
# although if an instrument is not specified the filters
# hash will be searched for a match if none is available in
# GENERIC
my %FILTERS = (
	       GENERIC => {
			   U => 0.365,
			   B => 0.44,
			   V => 0.55,
			   R => 0.70,
			   I => 0.90,
			   J => 1.25,
			   H => 1.65,
			   K => 2.2,
			   L => 3.45,
			   M => 4.7,
			   N =>10.2,
			   Q =>20.0,
			   up => 0.355,
			   gp => 0.470,
			   rp => 0.620,
			   ip => 0.750,
			   zp => 0.880,
			   Pu => 0.355,
			   Pg => 0.470,
			   Pr => 0.620,
			   Pi => 0.750,
			   Pz => 0.880,
			   Y  => 1.020,   # this will get incorrectly classed as infrared
			   w  => 0.608,
			   SO => 0.600,
			  },
	       WFCAM => {
			 "Z"     => 0.83,
			 "Y"     => 0.97,
			 "J"     => 1.17,
			 "H"     => 1.49,
			 "K"     => 2.03,
			 "1-0S1" => 2.111,
			 "BGamma"=> 2.155,
       "1.205nbJ" => 1.205,
                   "1.619nbH" => 1.619,
                         "1.644FeII" => 1.631,
			 "Blank" => 0,
			 },
	       IRCAM => {
			 "J98" =>     "1.250" ,
			 "H98" =>     "1.635" ,
			 "K98" =>     "2.150" ,
			 "Lp98" =>    "3.6"   ,
			 "Mp98" =>    "4.800" ,
			 "2.1c" =>    "2.100" ,
			 "2.122S1" => "2.122" ,
			 "BrG" =>     "2.0"   ,
			 "2.2c" =>    "2.200" ,
			 "2.248S1" => "2.248" ,
			 "3.6nbLp" => "3.6"   ,
			 "4.0c" =>    "4.000" ,
			 "BrA" =>     "4.0"   ,
			 "Ice" =>     "3.1"   ,
			 "Dust" =>    "3.28"  ,
			 "3.4nbL" =>  "3.4"   ,
			 "3.5mbL" =>  "3.5"   ,
			},
	       UFTI => {
                  "Y_MK" => "1.022",
			"I" =>     "0.9"  ,
			"Z" =>     "1.033",
			"J98" =>   "1.250",
			"H98" =>   "1.635",
			"K98" =>   "2.150",
			"Kprime" =>"2.120",
			"1.644" => "1.644",
                        '1.69CH4_l' => '1.690',
			"1.57" =>  "1.57" ,
			"2.122" => "2.122",
                  "2.122MK" => "2.122",
			"BrG" =>   "2.166",
			"BrGz" =>  "2.173",
			"2.248S(1)" => "2.248",
			"2.27" =>  "2.270",
			"Blank" => "-2.222",# -ve version of OT wavelength
			"Mask"  => "-2.32", # ditto
		       },
	       UIST => {
#			"K-target"  => 1.64, # old
                  "Y_MK" => 1.022,
                  "ZMK" => 1.033,
			"Hartmann"  => 1.64,
			"J98"       => 1.25,
			"H98"       => 1.64,
                        "1.57"      => 1.573,
			"1.66"      => 1.664, # old
			"1.58CH4_s" => 1.604,
			"1.69CH4_l" => 1.674,
			"1.644Fe"   => 1.643, #
			"K98"       => 2.20,
			"Kshort"    => 2.159,
			"Klong"     => 2.227,
			"2.122S(1)" => 2.121, #
			"2.122MK"   => 2.127,
			"2.248S(1)" => 2.248,
			"2.248MK"   => 2.263,
			"BrG"       => 2.166,
			"2.27"      => 2.274,
			"2.32CO"    => 2.324, # old
			"2.42CO"    => 2.425,
			"3.05ice"   => 3.048,
			"Dust"      => 3.278,
			"3.30PAH"   => 3.286,
			"3.4nbL"    => 3.415,
			"3.5mbL"    => 3.489,
			"3.6nbLp"   => 3.593,
			"3.99"      => 3.990,
			"BrA"       => 4.053,
			"Lp98"      => 3.77,
			"Mp98"      => 4.69,
		       },
	       MICHELLE => {
			    "F105B53" => 10.5,
			    "F79B10" =>   7.9,
			    "F88B10" =>   8.8,
			    "F97B10" =>   9.7,
			    "F103B10" => 10.3,
			    "F116B9" =>  11.6,
			    "F125B9" =>  12.5,
			    "F107B4" =>  10.7,
			    "F122B3" =>  12.2,
			    "F128B2" =>  12.8,
			    "F209B42" => 20.9,
			    "F185B9" =>  18.5,
			    "NBlock" =>  10.6,
			    "QBlock" =>  20.9,
			    "F22B15" =>   2.2,
			    "F34B9" =>    3.4,
			    "F47B5" =>    4.7,
			   },
	       SCUBA => {
			 "850W" => 863,
			 "450W" => 443,
			 "450N" => 442,
			 "850N" => 862,
			 "750N" => 741,
			 "350N" => 344,
			 "P2000" => 2000,
			 "P1350" => 1350,
			 "P1100" => 1100,
			 # This is a kluge until the class can
			 # be extended to support multiple wavelength
			 # instruments.
			 "850S:PHOT" => 1100,
			 "450W:850W" => 443,
			 "450N:850N" => 442,
			 "350N:750N" => 344,
			},
	       'SCUBA-2' => {
			     850 => 863, # guesses
			     450 => 445,
			    },
	      );

# Instruments that have natural units
my %NATURAL = (
	       WFCAM => 'filter',
 	       CGS4 => 'wavelength',
	       SCUBA => 'filter',
	       'SCUBA-2' => 'filter',
	       UFTI => 'filter',
	       IRCAM => 'filter',
	       MICHELLE => 'filter',
	       ACSIS => 'frequency',
	       DAS => 'frequency',
	       RXA3 => 'frequency',
	       RXA3M => 'frequency',
	       RXB3 => 'frequency',
	       RXW => 'frequency',
	       RXWB => 'frequency',
	       RXWC => 'frequency',
	       RXWD => 'frequency',
	       RXWD2 => 'frequency',
               HARP => 'frequency',
               ALAIHI => 'frequency',
               UU => 'frequency',
               AWEOWEO => 'frequency',
               KUNTUR => 'frequency',
	       UIST => 'filter',
	      );


=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::WaveBand> object.

  $w = new Astro::WaveBand( Filter => $filter );

Allowed keys for constructor are one of:

  Filter     - filter name
  Wavelength - wavelength in microns
  Frequency  - frequency in Hertz
  Wavenumber - wavenumber in cm^-1

plus optionally:

  Instrument - name of associated instrument

In the future there may be a C<Units> key to allow the units to be
supplied in alternative forms.

If a mandatory key is missing or there is more than one
mandatory key the constructor will fail and return C<undef>.
Additionally a warning (of class C<Astro::WaveBand>) will
be issued.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  # Check the hash contains one of the following
  my @keys = qw/ Filter Wavelength Frequency Wavenumber /;
  my $found = 0;
  for my $key (@keys) {
    $found++ if exists $args{$key};
  }

  if ($found == 0) {
    warnings::warn("Missing a mandatory key")
	if warnings::enabled();
    return undef;
  } elsif ($found > 1) {
    warnings::warn("More than one mandatory key")
	if warnings::enabled();
    return undef;
  }

  my $w = bless { Cache => {} }, $class;

  # Now insert the information into the object
  # Do Instrument first since we may need it to convert
  # filter to wavelength
  if (exists $args{Instrument}) {
    $w->instrument( $args{Instrument});
  }

  for my $key (keys %args) {
    my $method = lc($key);
    next if $method eq  'instrument';
    if ($w->can($method)) {
      $w->$method( $args{$key});
    }
  }

  # We are now done so just return the object
  return $w;
}

=back

=head2 Accessor methods

All the accessor methods associated with conversions will
automatically convert to the correct format on demand and will cache
it for later. If a new value is provided all caches will be cleared.

All input values are converted to microns internally (since a
single base unit should be chosen to simplify internal conversions).

=over 4

=item B<wavelength>

Wavelength in microns.

  $wav =  $w->wavelength;
  $w->wavelength(450.0);

=cut

sub wavelength {
  my $self = shift;
  if (@_) {
    my $value = shift;
    $self->_store_in_cache('wavelength' => $value);
  } else {
    return $self->_fetch_from_cache( 'wavelength' );
  }
  return;
}

=item B<frequency>

Frequency in Hertz.

  $frequency = $w->frequency;
  $w->frequency(345E9);

=cut

sub frequency {
  my $self = shift;
  if (@_) {
    my $value = shift;

    # store value and wavelength in cache
    $self->_cache_value_and_wav( 'frequency', $value);

  } else {
    # Read value from the cache
    return $self->_read_value_with_convert( "frequency" );

  }

  return;
}

=item B<wavenumber>

Wavenumber (reciprocal of wavelength) in inverse centimetres.

  $value = $w->wavenumber;
  $w->wavenumber(1500);

=cut

sub wavenumber {
  my $self = shift;
  if (@_) {
    my $value = shift;

    # store value and wavelength in cache
    $self->_cache_value_and_wav( 'wavenumber', $value);

  } else {
    # Read value from the cache
    return $self->_read_value_with_convert( "wavenumber" );

  }

  return;
}

=item B<filter>

Set or retrieve filter name.

Returns C<undef> if the filter can not be determined. If the filter
name can not be translated to a wavelength it will not be possible
to do any conversions to other forms.

=cut

sub filter {
  my $self = shift;
  if (@_) {
    my $value = shift;

    # store value and wavelength in cache
    $self->_cache_value_and_wav( 'filter', $value);

  } else {
    # Read value from the cache
    return $self->_read_value_with_convert( "filter" );

  }

  return;

}


=item B<instrument>

Name of associated instrument.

  $inst = $w->instrument;
  $w->instrument( 'SCUBA' );

Used to aid in the choice of natural unit.

=cut

sub instrument {
  my $self = shift;
  if (@_) { $self->{Instrument} = uc(shift); }
  return $self->{Instrument};
}

=item B<natural_unit>

Override the natural unit to be used for stringification. If this
value is not set the class will determine the unit of choice by
looking at the instrument name and then by taking an informed guess.

  $w->natural_unit('filter');

=cut

sub natural_unit {
  my $self = shift;
  if (@_) { $self->{NaturalUnit} = shift; }
  return $self->{NaturalUnit};
}


=back

=head2 General Methods

=over 4

=item B<waveband>

Return the name of the waveband associated with the object.

Returns C<undef> if none can be determined.

 $band = $w->waveband;

=cut

sub waveband {
  my $self = shift;

  my $lambda = $self->wavelength;
  return undef unless defined $lambda;

  my $band;
  if ($lambda >= 10000 ) {  # > 1cm
    $band = 'radio';
  } elsif ($lambda < 10000 and $lambda >= 1000) {
    $band = 'mm';
  } elsif ($lambda < 1000 and $lambda >= 100) {
    $band = 'submm';
  } elsif ($lambda < 100 and $lambda >= 1) {
    $band = 'infrared';
  } elsif ($lambda < 1 and $lambda >= 0.3) {
    $band = 'optical';
  } elsif ($lambda < 0.3 and $lambda >= 0.01) {
    $band = 'ultraviolet';
  } elsif ($lambda < 0.01 and $lambda >= 0.00001) {
    $band = 'x-ray';
  } elsif ($lambda < 0.00001) {
    $band = 'gamma-ray';
  }

  return $band;
}

=item B<natural>

Return the contents of the object in its most natural form.  For
example, with UFTI the filter name will be returned whereas with ACSIS
the frequency will be returned. The choice of unit is chosen using 
the supplied default unit (see C<natural_unit>) or the instrument name.
If none of these is specified filter will be used and if no match is
present wavelength in microns.

  $value = $w->natural;

Returns C<undef> if the value can not be determined.

This method is called automatically when the object is stringified.
Note that you will not know the unit that was chosen a priori.

=cut

sub natural {
  my $self = shift;

  # First see if the default unit is set
  my $unit = $self->natural_unit;

  unless (defined $unit) {
    # Check the instrument
    my $inst = $self->instrument;
    if ($inst and exists $NATURAL{$inst}) {
      $unit = $NATURAL{$inst};
    }
  }

  # Guess at filter if we have no choice
  $unit = 'filter' unless defined $unit;

  # retrieve the value
  my $value;
  if ($self->can($unit)) {
    $value = $self->$unit();
  }

  # All else fails... try wavelength
  $value = $self->wavelength() unless defined $value;

  return $value;
}

=item B<compare>

Compares two C<Astro::WaveBand> objects.

  if( $wb1->compare( $wb2 ) ) { ... }

This method will return -1 if, in the above example, $wb1 is of
a shorter wavelength than $wb2, 0 if the wavelengths are equal,
and +1 if $wb1 is of a longer wavelength than $wb2. Please note
that for strict waveband equality the C<equals> method should be
used, as that method uses the C<natural> method to check if two
wavebands are identical.

This method is overloaded with the standard numerical comparison
operators, so to check if one waveband is shorter than another
you would do

  if( $wb1 < $wb2 ) { ... }

and it will work as you expect. This method does not overload
the == operator; see the C<compare> method for that.

=cut

sub compare {
  my ( $object1, $object2, $was_reversed ) = @_;
  ( $object1, $object2 ) = ( $object2, $object1 ) if $was_reversed;

  return $object1->wavelength <=> $object2->wavelength;
}

=item B<equals>

Compares two C<Astro::WaveBand> objects for equality.

  if( $wb1->equals( $wb2 ) ) { ... }

This method will return 1 if, in the above example, both
C<Astro::WaveBand> objects return the same value from the
C<natural> method AND for the C<instrument> method (if it
is defined for both objects) , and 0 of they return different values.

This method is overloaded using the == operator, so

  if( $wb1 == $wb2 ) { ... }

is functionally the same as the first example.

=cut

sub equals {
  my $self = shift;
  my $comp = shift;

  if( defined( $self->instrument ) && defined( $comp->instrument ) ) {
    return ( ( $self->natural eq $comp->natural ) &&
             ( $self->instrument eq $comp->instrument ) );
  } else {
    return ( $self->natural eq $comp->natural );
  }
}

=item B<not_equals>

Compares two C<Astro::WaveBand> objects for inequality.

  if( $wb1->not_equals( $wb2 ) ) { ... }

This method will return 1 if, in the above example, either the
C<natural> method or the C<instrument> method return different
values. If the instrument is undefined for either object, then
the C<natural> method will be used.

This method is overloaded using the != operator, so

  if( $wb1 != $wb2 ) { ... }

is functionally the same as the first example.

=cut

sub not_equals {
  my $self = shift;
  my $comp = shift;

  if( ! defined( $self->instrument ) || ! defined( $comp->instrument ) ) {
    return ( $self->natural ne $comp->natural );
  } else {
    return ( ( $self->natural ne $comp->natural ) ||
             ( $self->instrument ne $comp->instrument ) );
  }
}

=back

=begin __PRIVATE_METHODS__

=head2 Private Methods

=over 4

=item B<_cache>

Retrieve the hash reference associated with the cache (in a scalar
context) or the contents of the hash (in a list context).

 $ref = $w->cache;
 %cache = $w->cache;

=cut

sub _cache {
  my $self = shift;
  if (wantarray) {
    return %{ $self->{Cache} };
  } else {
    return $self->{Cache};
  }
}

=item B<_store_in_cache>

Store values in the cache associated with particular types.

  $w->_store_in_cache( "filter" => "K",
		       "frequency" => 1.4E14,
		     );

If the cache already contains a value for this entry the cache
is cleared prior to storing it (unless it contains the same value)
on the assumption that the cache is no longer consistent.

More than one key can be supplied. All keys are tested for prior
existence before inserting the new ones.

=cut

sub _store_in_cache {
  my $self = shift;
  my %entries = @_;

  # Get the cache
  my $cache = $self->_cache;

  # First check to see whether we have any entries in the
  # cache that clash
  for my $key (keys %entries) {

    # No worries if it is not there
    next unless exists $cache->{$key};

    # Check to see if the value is the same as is already present
    # Use a string comparison for filter
    if ($key eq 'filter') {
      next if $cache->{$key} eq $entries{$key};
    } else {
      # Number
      next if $cache->{$key} == $entries{$key};
    }

    # Now we have a key that exists but its value is
    # different. Clear the cache and exit the loop.
    # This means the loop never really reaches the end
    # of the block...
    $self->_clear_cache;

    last;
  }

  # Now insert the values
  for my $key (keys %entries) {
    $cache->{$key} = $entries{$key};
  }

  # finished
  return;
}

=item B<_clear_cache>

Empty the cache.

=cut

sub _clear_cache {
  my $self = shift;
  %{ $self->_cache } = ();
  return;
}

=item B<_fetch_from_cache>

Retrieve an item from the cache. Returns C<undef> if the item is
not stored in the cache.

  $filter = $w->_fetch_from_cache( "filter" );

Could be combined into a single method with C<_store_in_cache> but
separated for simplicity.

=cut

sub _fetch_from_cache {
  my $self = shift;
  return undef unless @_;

  my $key = shift;
  return undef unless $key;
  $key = lc($key); # level playing field

  # Return the value from the cache if it exists
  my $cache = $self->_cache;
  return $cache->{$key} if exists $cache->{$key};

  return undef;
}

=item B<_cache_value_and_wav>

Cache the supplied value, converting it to the internal format
if necessary.

  $w->_cache_value_and_wav( 'frequency', $frequency );

If the wavelength can not be determind the cache is cleared
and the supplied value is inserted (but without wavelength
information)..

=cut

sub _cache_value_and_wav {
  my $self = shift;

  my $category = shift;
  my $value = shift;
  return unless defined $value;

  # Convert to the internal format (wavelength)
  my $internal = $self->_convert_from( $category, $value );

  # Store all defined values into cache
  my %store;
  $store{$category} = $value;
  $store{wavelength} = $internal if defined $internal;

  # Clear cache if wavelength is not to be supplied
  $self->_clear_cache() unless defined $internal;

  $self->_store_in_cache( %store );

  return;
}

=item B<_read_value_with_convert>

Read a value from the cache, converting it to the required units
as necessary.

 $value = $w->_read_value_with_convert( 'frequency' );

Returns C<undef> if no value has been stored in the object.

=cut

sub _read_value_with_convert {
  my $self = shift;
  my $category = lc(shift);

  my $value = $self->_fetch_from_cache( $category );

  # Convert it if necessary
  unless ($value) {

    # Convert it from the default value (if set)
    $value = $self->_convert_to( $category );

    # Cache it if necessary
    $self->_store_in_cache( $category => $value )
      if $value;
  }

  return $value;
}

=item B<_convert_to>

Convert the value stored internally as the default format to the
required format. This simplifies the conversion routines since 
there is only a single format to convert from and to.

  $value = $w->_convert_to( 'frequency' );

Returns the converted value or undef on error. The internal format
(wavelength) is read directly from the cache.

=cut

sub _convert_to {
  my $self = shift;
  my $category = shift;

  my $lambda = $self->_fetch_from_cache( 'wavelength' );
  return undef unless defined $lambda;

  # Check all types
  my $output;
  if ($category eq 'wavelength') {
    $output = $lambda;
  } elsif ($category eq 'frequency') {
    # Microns
    $output = CLIGHT / ( $lambda * 1.0E-6);
  } elsif ($category eq 'wavenumber') {
    # Inverse cm
    $output = 1.0 / ( $lambda / 10_000);
  } elsif ($category eq 'filter') {

    # This is slightly harder since we know the value but
    # not the key. Go through each hash looking for a matching
    # key. If we know the instrument we start looking there
    # Else we have to look through GENERIC followed by all the
    # remaining instruments

    my $instrument = $self->instrument;
    my @search = ('GENERIC', keys %FILTERS);
    unshift(@search, $instrument) if defined $instrument;

    # There will be a precision issue here so we convert
    # the base wavelegnth to use 8 significant figures
    $lambda = sprintf("%8e", $lambda);

  OUTER: foreach my $inst (@search) {
      next unless exists $FILTERS{$inst};
      my $hash = $FILTERS{$inst};
      for my $key (keys %{ $hash }) {
        # Make sure we use the same rounding scheme on the values
        # returned from the hash, so we don't have to worry about
        # rounding issues fouling things up (like saying 8.3e-1 !=
        # 0.83).
        if (sprintf("%8e", $hash->{$key} ) eq $lambda) {
          $output = $key;
          last OUTER;
        }
      }
    }
  }

  return $output;
}

=item B<_convert_from>

Convert from the supplied values to the internal format (wavelength).

  $value = $w->_convert_from( 'frequency', $frequency );

Returns the converted value. Returns C<undef> if the conversion
is not possible.

=cut

sub _convert_from {
  my $self = shift;

  my $category = lc(shift);
  my $value = shift;
  return undef unless defined $value;

  # Go through each type
  my $output;
  if ($category eq 'wavelength') {
    $output = $value;
  } elsif ($category eq 'frequency') {

    # Convert frequency to wavelength 
    # converting from metres to microns
    $output = CLIGHT / ($value * 1.0E-6);

  } elsif ($category eq 'wavenumber') {
    # 1 / cm then convert cm to microns
    $output = (1.0 / $value) * 10_000;

  } elsif ($category eq 'filter') {
    # Convert filter to wavelength
    # Need to walk through %FILTERS first for a 
    # instrument match and then for a generic match
    my $instrument = $self->instrument;
    my @search = ('GENERIC');
    unshift(@search, $instrument) if defined $instrument;

    foreach my $name (@search) {

      # First look for a match in %FILTERS
      if (exists $FILTERS{$name}) {
	# Now look for the filter itself
	if (exists $FILTERS{$name}{$value}) {
	  $output = $FILTERS{$name}{$value};
	  last;
	}
      }
    }
  }

  return $output;
}

=back

=end __PRIVATE_METHODS__

=head2 Static functions

These functions enable the user to obtain an overview of
the supported filter, instrument and telescope combinations.

=over 4

=item B<has_filter>

Returns true if the a particular instrument has a particular filter,
otherwise returns C<undef>, e.g.

  if( Astro::WaveBand::has_filter( UIST => "Kprime" )  {
     ...
  }

if you pass a hash containing multiple instrument combinations,
all must be valid or the method will return undef.

=cut

sub has_filter {
   return undef unless @_;

   # grab instrument and filter list
   my %list = @_;

   my $counter = 0;
   foreach my $key ( sort keys %list ) {
      # if the filter exists in the filter list for that instrument,
      # increment the counter
     $counter++ if exists $FILTERS{$key}{$list{$key}};
   }

   # if the counter is the same size as the input list then all conditons
   # have been proved to be true...
   return undef unless scalar(keys %list) == $counter;
   return 1;
}

=item B<has_instrument>

Returns true if the a particular instrument exists for a particular
telescope, otherwise returns C<undef>, e.g.

  if( Astro::WaveBand::has_instrument( UKIRT => "UIST" )  {
     ...
  }

if you pass a hash containing multiple instrument combinations,
all must be valid or the method will return undef.

=cut

sub has_instrument {
   return undef unless @_;

   # grab instrument and filter list
   my %list = @_;

   my $counter = 0;
   foreach my $key ( sort keys %list ) {
      # if the filter exists in the filter list for that instrument,
      # increment the counter
      for my $i ( 0 ... $#{$TELESCOPE{$key}} ) {
         if ( $TELESCOPE{$key}->[$i] eq $list{$key} ) {
             $counter++;
             last;
         }
      }
   }

   # if the counter is the same size as the input list then all conditons
   # have been proved to be true...
   return undef unless scalar(keys %list) == $counter;
   return 1;
}


=item B<is_observable>

Returns true if the a particular telescope and filter combination is
avaialable, otherwise returns C<undef>, e.g.

  if( Astro::WaveBand::is_observable( UKIRT => 'Kprime' )  {
     ...
  }

=cut

sub is_observable {
   #my $self = shift;
   return undef unless @_;

   # grab instrument and filter list
   my %list = @_;

   my $counter = 0;
   foreach my $key ( sort keys %list ) {
      # if the filter exists in the filter list for that instrument,
      # increment the counter
      #print "TELESCOPE $key\n";
      for my $i ( 0 ... $#{$TELESCOPE{$key}} ) {

         #print "  INSTRUMENT ${$TELESCOPE{$key}}[$i]\n";
         #print "  \$list{\$key} = $list{$key}\n";
         my $instrument = ${$TELESCOPE{$key}}[$i];

         if ( ${$FILTERS{$instrument}}{$list{$key}} ) {
           $counter++;
           #print "$counter: $key\n";
           #print "   $list{$key}, $instrument, $list{$key}, ".
           #      "${$FILTERS{${$TELESCOPE{$key}}[$i]}}{$list{$key}}\n";
           last;
         }
      }
   }

   # if the counter is the same size as the input list then all conditons
   # have been proved to be true...
   return undef unless scalar(keys %list) == $counter;
   return 1;
}

=back

=head1 BUGS

Does not automatically convert metres to microns and GHz to Hz etc.

Can not handle filters that correspond to multiple wavelengths.
Currently SCUBA is the main issue. With a 450:850 filter this class
always returns the shortest wavelength (since that is the wavelength
that affects scheduling the most).

Should handle velocities and redshifts in order to disambiguate rest
frequencies and observed frequencies. Would also be nice if the class
could accept a molecule and transition, allowing the natural unit
to appear as something like: "CO 3-2 @ 30km/s LSR radio".

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>
Tim Lister E<lt>tlister@lcogt.netE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2003 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
