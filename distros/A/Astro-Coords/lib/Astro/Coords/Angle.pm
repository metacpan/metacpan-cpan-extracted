package Astro::Coords::Angle;

=head1 NAME

Astro::Coords::Angle - Representation of an angle

=head1 SYNOPSIS

  use Astro::Coords::Angle;

  $ang = new Astro::Coords::Angle( 45.5, units => 'deg' );
  $ang = new Astro::Coords::Angle( "45:30:00", units => 'sexagesimal' );

  $rad = $ang->radians;
  $deg = $ang->degrees;
  $asec = $ang->arcsec;
  $amin = $ang->arcmin;
  $string = $ang->string;

=head1 DESCRIPTION

Helper class for C<Astro::Coords> to represent an angle. Methods are
provided for parsing angles in sexagesimal format and for returning
angles in any desired format.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Scalar::Util qw/ looks_like_number /;
use Astro::PAL;

# Overloading
use overload
  '""' => "stringify",
  '0+' => "numify",
  fallback => 1;

# Package Global variables
our $VERSION = '0.22';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Construct a new C<Angle> object. Must be called with an angle as first
argument. Optional hash arguments can be supplied to specify, for example,
the units of the supplied angle.

  $ang = new Astro::Coords::Angle( $angle,
                                   units => "degrees" );

Supported options are:

  units      - units of the supplied string or number
  range      - restricted range of the angle

Supported units are:

 sexagesimal - A string of format either dd:mm:ss or "dd mm ss"
               "dms" separators are also supported.
 degrees     - decimal degrees
 radians     - radians
 arcsec      - arc seconds (abbreviated form is 'as')
 arcmin      - arc minutes (abbreviated form is 'am')

The units can be abbreviated to the first 3 characters.

If the units are not supplied the default is to assume "sexagesimal"
if the supplied string contains spaces or colons or the characters
"d", "m" or "s", "degrees" if the supplied number is greater than 2*PI
(6.28), and "radians" for all other values. Negative angles are supported.

The options for range are documented in the C<range> method.

If the angle can not be decoded (if a string), the constructor will fail.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  croak "Constructor for object of class $class must be called with an argument" unless @_;

  # first argument is the angle
  my $input_ang = shift;

  # optional hash, only read it if we have an even number of
  # remaining arguments
  my %args;
  if (@_) {
    if (scalar(@_) % 2 == 0) {
      %args = @_;
    } else {
      warnings::warnif("An odd number of Optional arguments were supplied to constructor");
    }
  }

  # Now need to convert this to radians (the internal representation)
  # Allow for inheritance
  my $rad = $class->_cvt_torad($input_ang, $args{units});

  croak "Unable to decode supplied angle (".
    (defined $input_ang ? "'$input_ang'" : "<undef>").")"
      unless defined $rad;

  # Create the object
  my $ang = bless {
                   ANGLE => $rad,
                   RANGE => 'NONE',
                   NDP => undef,  # number of decimal places
                   DELIM => undef, # string delimiter
                  }, $class;

  # If a range was specified, normalise the angle
  $ang->range( $args{range} ) if exists $args{range};

  # And return the object
  return $ang;
}

=back

=head2 Accessor Methods

=over 4

=item B<radians>

Return the angle in radians.

 $rad = $ang->radians;

=cut

sub radians {
  my $self = shift;
  return $self->{ANGLE};
}

# undocumented since we do not want a public way of changing the
# angle
sub _setRadians {
  my $self = shift;
  my $rad = shift;
  croak "Angle must be defined" unless defined $rad;
  $self->{ANGLE} = $rad;
}

=item B<degrees>

Return the angle in decimal degrees.

 $deg = $ang->degrees;

=cut

sub degrees {
  my $self = shift;
  my $rad = $self->radians;
  return $rad * Astro::PAL::DR2D;
}

=item B<str_ndp>

Number of decimal places to use when stringifying the object.
Default is to use the global class value (see the C<NDP> class method).
Set to C<undef> to revert to the class setting.

  $ang->str_ndp( 4 );
  $ndp = $ang->str_ndp;

=cut

sub str_ndp {
  my $self = shift;
  if (@_) {
    $self->{NDP} = shift;
  }
  # A value has been requested. Do we have a local value
  # or should we return the default.
  if (defined $self->{NDP} ) {
    return $self->{NDP};
  } else {
    return $self->NDP;
  }
}

=item B<str_delim>

Delimiter to use between components when stringifying.
Default is to use the global class value (see the C<DELIM> class method).
Set to C<undef> to revert to the class setting.

  $ang->str_delim( ":" );
  $delim = $ang->str_delim;

=cut

sub str_delim {
  my $self = shift;
  if (@_) {
    $self->{DELIM} = shift;
  }
  # A value has been requested. Do we have a local value
  # or should we return the default.
  if (defined $self->{DELIM} ) {
    return $self->{DELIM};
  } else {
    return $self->DELIM;
  }
}

=item B<components>

Return an array of components that correspond to the sign, degrees,
arcminutes and arcseconds of the angle. The sign will be either a '+'
or '-' and is required to distinguish '+0' from '-0'.

  @comp = $ang->components;

The number of decimal places in the seconds will not be constrained by the
setting of C<str_ndp>, but is constrained by an optional argument:

  @comp = $ang->components( $ndp );

Default resolution is 5 decimal places.  The limit is 9 to avoid
overflowing the results from palDr2af or palDr2tf.

In scalar context, returns a reference to an array.

=cut

sub components {
  my $self = shift;
  my $res = shift; # internal api

  # Get the angle in radians
  my $rad = $self->radians;

  # Convert to components using PAL. COCO uses 4 dp for high
  # resolution.
  $res = 5 unless defined $res;

  # Limit $res to avoid overflowing results from palDr2af or palDr2tf.
  if ($res > 9) {
    warnings::warnif("Excess dp ($res) requested, limiting to 9");
    $res = 9;
  }

  my @dmsf = $self->_r2f( $res );

  # Combine the fraction with the seconds unless no decimal places
  my $frac = pop(@dmsf);
  $dmsf[-1] .= sprintf( ".%0$res"."d",$frac) unless $res == 0;

  #use Data::Dumper;
  #print Dumper(\@dmsf);

  if (wantarray) {
    return @dmsf;
  } else {
    return \@dmsf;
  }

}

=item B<string>

Return the angle as a string in sexagesimal format (e.g. 12:30:52.4).

  $string = $ang->string();

The form of this string depends on the C<str_delim> and C<str_ndp>
settings and on whether the angular range allows negative values (the
sign will be dropped if the range is known to be positive).

=cut

sub string {
  my $self = shift;

  # Get the components
  my $ndp = $self->str_ndp;
  my @dms = $self->components( $ndp );

  # Play it safe, and split the fractional part into two strings.
  # if ndp > 0
  if ( $ndp > 0 ) {
    my ($sec, $frac) = split(/\./,$dms[-1]);
    $dms[-1] = $sec;
    push(@dms, $frac);
  }

  # Now build the string.

  # Clear the + sign, setting it to empty string if the angle can never
  # go negative.
  my $sign = shift(@dms);
  if ($sign eq '+') {
    if ($self->range eq '2PI') {
      $sign = '';
    } else {
      $sign = ' ';
    }
  }

  # Get the delimiter
  my $delim = $self->str_delim;

  # Build the format

  # fractional part will not require a decimal place
  # if ndp is 0. If ndp>0 the fraction is formatted
  my $fracfmt = ( $ndp == 0 ? '' : '.%s' );

  # starting with the numeric part. Gal longitude will want %03d and no sign.
  # RA will want no sign and %02d. Dec wants sign with %02d.

  my @fmts = ( '%02d', '%02d', '%02d'.$fracfmt);
  my $fmt;
  if (length($delim) == 1) {
    $fmt = join($delim, @fmts );
  } else {
    my @chars = split (//, $delim );
    for my $f (@fmts) {
      $fmt .= $f . shift(@chars);
    }
  }

  return $sign . sprintf( $fmt, @dms);

}

=item B<arcsec>

Return the angle in arcseconds.

 $asec = $ang->arcsec;

=cut

sub arcsec {
  my $self = shift;
  my $rad = $self->radians;
  return $rad * Astro::PAL::DR2AS;
}

=item B<arcmin>

Return the angle in arcminutes.

 $amin = $ang->arcmin;

=cut

sub arcmin {
  my $self = shift;
  my $asec = $self->arcsec;
  return $asec / 60.0;
}

=item B<range>

String describing the allowed range of the angle. Allowed values
are

  NONE         - no pre-determined range
  2PI          - 0 to 2*PI radians (0 to 360 degrees)
  PI           - -PI to +PI radians (-180 to 180 degrees)

Any other strings will be ignored (and a warning issued if appropriate).

When a new value is provided, the angle is normalised to this range.
Note that this is not always reversible (especially if reverting to
"NONE"). The range can also be specified to the constructor.

Default is not to normalize the angle.

=cut

sub range {
  my $self = shift;
  if (@_) {
    my $rng = shift;
    if (defined $rng) {
      # upper case
      $rng = uc($rng);

      # get the current value for the angle
      my $rad = $self->radians;

      # Now check validity of string and normalise
      if ($rng eq 'NONE') {
        # do nothing apart from store it
      } elsif ($rng eq '2PI') {
        $self->_setRadians( Astro::PAL::palDranrm( $rad ));
      } elsif ($rng eq 'PI') {
        $self->_setRadians( Astro::PAL::palDrange( $rad ));
      } else {
        warnings::warnif("Supplied range '$rng' not recognized");
        return;
      }
      # store it
      $self->{RANGE} = $rng;
    } else {
      warnings::warnif("Supplied range was not defined");
    }
  }
  return $self->{RANGE};
}

=item B<in_format>

Simple wrapper method to support the backwards compatibility interface
in C<Astro::Coords> when requesting an angle by using a string format rather
than an explicit method.

  $angle = $ang->in_format( 'sexagesimal' );

Supported formats are:

  radians       calls 'radians' method
  degrees       calls 'degrees' method
  sexagesimal   calls 'string' method
  array         calls 'components' method (returns 2 dp resolution)
  arcsec        calls 'arcsec' method
  arcmin        calls 'arcmin' method

The format can be abbreviated to the first 3 letters, or 'am' or 'as'
for arcmin and arcsec respectively. If no format is specified explicitly, the
object itself will be returned.

=cut

sub in_format {
  my $self = shift;
  my $format = shift;

  # No format (including empty string), return the object
  return $self unless $format;
  $format = lc($format);

  if ($format =~ /^d/) {
    return $self->degrees;
  } elsif ($format =~ /^s/) {
    return $self->string();
  } elsif ($format =~ /^r/) {
    return $self->radians();
  } elsif ($format =~ /^arcm/ || $format eq 'am') {
    return $self->arcmin;
  } elsif ($format =~ /^arcs/ || $format eq 'as') {
    return $self->arcsec;
  } elsif ($format =~ /^a/) {
    return $self->components($self->str_ndp);
  } else {
    warnings::warnif("Unsupported format '$format'. Returning radians.");
    return $self->radians;
  }
}

=item B<clone>

Create new cloned copy of this object.

  $clone = $ang->clone;

=cut

sub clone {
  my $self = shift;
  return bless { %$self }, ref $self;
}

=item B<negate>

Negate the sense of the angle, returning a new angle object.

  $neg = $ang->negate;

Not allowed if the range is defined as 0 to 2PI.

=cut

sub negate {
  my $self = shift;
  croak "Angle can not be negated since its range is 0 to 2PI"
    if $self->range eq '2PI';
  my $rad = $self->radians;
  return $self->new( $rad * -1.0, units => 'radians', range => $self->range );
}

=back

=head2 Overloading

The object is overloaded such that it stringifies via the C<string>
method, and returns the angle in radians in numify context.

=cut

sub stringify {
  my $self = shift;
  return $self->string();
}

sub numify {
  my $self = shift;
  return $self->radians();
}

=head2 Class Methods

The following methods control the default behaviour of the class.

=over 4

=item B<NDP>

The number of decimal places to use in the fractional part of
the number when stringifying (from either the C<string> method
or the C<components> method).

  Astro::Coords::Angle->NDP( 4 );

Default value is 2. If this is changed then
all instances will be affected on stringification unless the
C<str_ndp> attribute has been set explicitly for an instance.

If an undefined argument is supplied, the class will revert to its
initial state.

  Astro::Coords::Angle->NDP( undef );

=cut

{
  my $DEFAULT_NDP = 2;
  my $NDP = $DEFAULT_NDP;
  sub NDP {
    my $class = shift;
    if (@_) {
      my $arg = shift;
      if (defined $arg) {
        $NDP = $arg;
      } else {
        $NDP = $DEFAULT_NDP;
      }
    }
    return $NDP;
  }
}

=item B<DELIM>

Delimiter to use to separate components of a sexagesimal triplet when
the object is stringified. If this is changed then all instances will
be affected on stringification unless the C<str_delim> attribute has
been set explicitly for an instance.

Common values are a colon (12:52:45.4) or a space (12 52 45.4).  If
more than one character is present in the string, each character will
be used in turn as a delimiter in the string until either no more gaps
are present (or characters have been exhausted. In the former, if
there are more characters than gaps, the first character remaining in
the string will be appended, in the latter case, no more characters
will be printed.  For example, "dms" would result in '12d52m45.4s',
whereas 'dm' would result in '12d52m45.4'

  Astro::Coords::Angle->DELIM( ':' );

Default is ":". An undefined argument will result in the class reverting
to the default state.

=cut

{
  my $DEFAULT_DELIM = ":";
  my $DELIM = $DEFAULT_DELIM;
  sub DELIM {
    my $class = shift;
    if (@_) {
      my $arg = shift;
      if (defined $arg) {
        $DELIM = $arg;
      } else {
        $DELIM = $DEFAULT_DELIM;
      }
    }
    return $DELIM;
  }
}

=item B<to_radians>

Low level utility routine to convert an input value in specified format
to radians. This method uses the same code as the object constructor to parse
the supplied input argument but does not require the overhead of object
construction if the result is only to be used transiently.

  $rad = Astro::Coords::Angle->to_radians( $string, $format );

See the constructor documentation for the supported format strings.

=cut

sub to_radians {
  my $class = shift;
  # simply delegate to the internal routine. Could use it directly but it feels
  # better to leave options open for the moment
  $class->_cvt_torad( @_ );
}

=back

=begin __PRIVATE_METHODS__

=head2 Private Methods

These methods are not part of the API and should not be called directly.
They are documented for completeness.

=over 4

=item B<_cvt_torad>

Internal class method to convert an input string to the equivalent value in
radians. The following units are supported:

 sexagesimal - A string of format "dd:mm:ss.ss", "dd mm ss.ss"
               or even "-ddxmmyss.ss" (ie -5x53y28.5z)
 degrees     - decimal degrees
 radians     - radians
 arcsec      - arc seconds (abbreviated form is 'as')
 arcmin      - arc minutes (abbreviated form is 'am')

If units are not supplied, default is to call the C<_guess_units>
method.

  $radians = $angle->_cvt_torad( $angle, $units );

Warnings are issued if the string can not be parsed or the values are
out of range.

If the supplied angle is an Angle object itself, units are ignored and
the value is extracted directly from the object.

Returns C<undef> on error. Does not modify the internal state of the object.

=cut

sub _cvt_torad {
  my $self = shift;
  my $input = shift;
  my $units = shift;

  return undef unless defined $input;

  # do we have an object?
  # and can it implement the radians() method?
  if (UNIVERSAL::can( $input, 'radians')) {
    return $input->radians;
  }

  # Clean up the string
  $input =~ s/^\s+//g;
  $input =~ s/\s+$//g;

  # guess the units
  unless (defined $units) {
    $units = $self->_guess_units( $input );
    croak "No units supplied, and unable to guess any units either"
      unless defined $units;
  }

  # Now process the input - starting with strings
  my $output = 0;
  if ($units =~ /^s/) {

    # Since we can support aritrary delimiters on write,
    # we should be flexible on read. Slalib is very flexible
    # once the numbers are space separated, so remove all
    # non-numeric characters except + and - and replace with space
    # For now, remove all alphabetic characters and colon only

    # Need to clean up the string for PAL
    $input =~ s/[:[:alpha:]]/ /g;

    my $nstrt = 1;
    ($nstrt, $output, my $j) = Astro::PAL::palDafin( $input, $nstrt );
    $output = undef unless $j == 0;

    if ($j == -1) {
      warnings::warnif "In coordinate '$input' the degrees do not look right";
    } elsif ($j == -2) {
      warnings::warnif "In coordinate '$input' the minutes field is out of range";
    } elsif ($j == -3) {
      warnings::warnif "In coordinate '$input' the seconds field is out of range (0-59.9)";
    } elsif ($j == 1) {
      warnings::warnif "Unable to find plausible coordinate in string '$input'";
    }

  } elsif ($units =~ /^d/) {
    # Degrees decimal
    $output = $input * Astro::PAL::DD2R;

  } elsif ($units =~ /^arcs/ || $units eq 'as') {
    # Arcsec
    $output = $input * Astro::PAL::DAS2R;

  } elsif ($units =~ /^arcm/ || $units eq 'am') {
    # Arcmin
    $output = $input * Astro::PAL::DAS2R * 60 ;

  } else {
    # Already in radians
    $output = $input;
  }

  return $output;
}

=item B<_guess_units>

Given a string or number, tries to guess the units.  Default is to
assume "sexagesimal" if the supplied string does not look like a
number to perl, "degrees" if the supplied number is greater than 2*PI
(6.28), and "radians" for all other values.

  $units = $class->_guess_units( $input );

Returns undef if the input does not look at all plausible or is undef
itself.

Arcsec or arcmin can not be determined with this routine.

=cut

sub _guess_units {
  my $self = shift;
  my $input = shift;
  return undef if !defined $input;

  # Now if we have a space, colon or alphabetic character
  # then we have a real string and assume sexagesimal.
  # Use pre-defined character classes
  my $units;
  # if it does not look like a number choose sexagesimal
  if (!looks_like_number($input)) {
    $units = "sexagesimal";
  } elsif ($input > Astro::PAL::D2PI) {
    $units = "degrees";
  } else {
    $units = "radians";
  }

  return $units;
}

=item B<_r2f>

Routine to convert angle in radians to a formatted array
of numbers in order of sign, deg, min, sec, frac.

  @retval = $ang->_r2f( $ndp );

Note that the number of decimal places is an argument.

=cut

sub _r2f {
  my $self = shift;
  my $res = shift;

  warnings::warnif("More than 9 dp requested ($res), result from palDr2af likely to overflow in fractional part") if $res > 9;

  my ($sign, @dmsf) = Astro::PAL::palDr2af($res, $self->radians);
  return ($sign, @dmsf);
}

=back

=end __PRIVATE_METHODS__

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2004-2005 Tim Jenness. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;

