package Astro::Coords::Elements;


=head1 NAME

Astro::Coords::Elements - Specify astronomical coordinates using orbital elements

=head1 SYNOPSIS

  $c = new Astro::Coords::Elements( elements => \%elements );

=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
specified as orbital elements.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.19';

# Need working palPlante
use Astro::PAL 0.95 ();
use Astro::Coords::Angle;
use Time::Piece qw/ :override /;

use base qw/ Astro::Coords /;

use overload '""' => "stringify";

=head1 METHODS


=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Elements( elements => \%elements );
  $c = new Astro::Coords::Elements( elements => \@array );

Returns undef on error.

The elements can be specified either by using a reference to an array
returned by the C<array()> method of another elements object or in a
reference to a hash containing the following keys:

suitable for the major planets:

 EPOCH 		 =  epoch of elements t0 (TT MJD)
 ORBINC          =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  longitude of perihelion  [$\varpi$] (radians)
 AORQ 		 =  mean distance a (AU)
 E 		 =  eccentricity e
 AORL 		 =  mean longitude L (radians)
 DM 		 =  daily motion n (radians)

suitable for minor planets:


 EPOCH 		 =  epoch of elements t0 (TT MJD)
 ORBINC        	 =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  argument of perihelion  [$\omega$] (radians)
 AORQ 		 =  mean distance a (AU)
 E 		 =  eccentricity e
 AORL 		 =  mean anomaly M (radians)

suitable for comets:


 EPOCH 		 =  epoch of elements t0 (TT MJD)
 ORBINC        	 =  inclination i (radians)
 ANODE 		 =  longitude of the ascending node  [$\Omega$] (radians)
 PERIH 		 =  argument of perihelion  [$\omega$] (radians)
 AORQ 		 =  perihelion distance q (AU)
 E 		 =  eccentricity e
 EPOCHPERIH      =  epoch of perihelion T (TT MJD)

See the documentation to palPlante() and palPertel() for more information.
Keys must be upper case.

For comets if the only one epoch is specified it is assumed that the
epochs are identical. This may cause problems if the epochs are not
really close to each other.

In order to better match normal usage, EPOCH can also be specified
as a string of the form 'YYYY mmm D.frac' (e.g. '1997 Apr 1.567').
(no decimal place after the month). This is the format used by JPL.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %opts = @_;

  # "elements" key must be defined and point to a reference
  return undef unless (exists $opts{elements} && ref($opts{elements}));

  # We allow use of an array reference or a hash
  # The array ref is converted to a hash
  my %elements;
  if (ref($opts{elements}) eq 'HASH') {
    %elements = %{ $opts{elements} };
  } elsif (ref($opts{elements}) eq 'ARRAY' &&
	   $opts{elements}->[0] eq 'ELEMENTS') {

    my $i = 3;
    for my $key (qw/ EPOCH ORBINC ANODE PERIH AORQ E AORL /) {
      $elements{$key} = $opts{elements}->[$i];
      $i++;
    }
    # assign EPOCHPERIH
    if (!defined $elements{AORL} && defined $opts{elements}->[$i]) {
      $elements{EPOCHPERIH} = $opts{elements}->[$i];
    } else {
      $elements{DM} = $opts{elements}->[$i];
    }

  } else {
    return undef;
  }

  # Sanity check
  for (qw/ ORBINC ANODE PERIH AORQ E/) {
    #return undef unless exists $elements{$_};
    croak "Must supply element $_ to constructor"
      unless exists $elements{$_};
  }

  # Fix up EPOCHs if it has been specified as a string
  for my $key (qw/ EPOCH EPOCHPERIH / ) {
    next unless exists $elements{$key};
    my $epoch = $elements{$key};

    # if we are missing one of the EPOCHs that is okay
    # so just skip
    if (! defined $epoch) {
      # and delete it from the hash as if it was never supplied
      # this avoids complications later
      delete $elements{$key};
      next;
    }

    if ($epoch =~ /^\d+\.\d+$/ || $epoch =~ /^\d+$/) {
      # an MJD so do not modify
    } elsif ($epoch =~ /\d\d\d\d \w\w\w \d+\.\d+/) {
      # has letters in it so try to parse
      # Split on decimal point
      my ($date, $frac) = split(/\./,$epoch,2);
      $frac = "0.". $frac; # preserve as decimal fraction
      my $format = '%Y %b %d';
      #print "EPOCH : $epoch and $date and $frac\n";
      my $obj = Time::Piece->strptime($date, $format);
      my $tzoffset = $obj->tzoffset;
      $tzoffset = $tzoffset->seconds if defined $tzoffset;
      $obj = gmtime($obj->epoch() + $tzoffset);

      # get the MJD and add on the fraction
      my $mjd = $obj->mjd() + $frac;
      $elements{$key} = $mjd;
      #print "MJD: $mjd\n";

    } else {
      # do not understand the format so return undef
      warn "Unable to recognize format for elements $key [$epoch]";
      return undef;
    }

    # Convert JD to MJD
    if ($elements{$key} > 2400000.5) {
      $elements{$key} -= 2400000.5;
    }

  }

  # but complain if we do not have one of them
  croak "Must supply one of EPOCH or EPOCHPERIH - both were undefined"
    if (!exists $elements{EPOCH} &&
	!exists $elements{EPOCHPERIH});

  # create the object
  bless { elements => \%elements, name => $opts{name} }, $class;

}



=back

=head2 Accessor Methods

=over 4

=item B<elements>

Returns the hash containing the elements.

  %el = $c->elements;

=cut

sub elements {
  my $self = shift;
  return %{ $self->{elements}};
}

=back

=head1 General Methods

=over 4

=item B<array>

Return back 11 element array with first element containing the
string "ELEMENTS", the next two elements as undef and up to 8
following elements containing the orbital elements in the order
presented in the documentation of the constructor.

This method returns a standardised set of elements across all
types of coordinates.

Note that for JFORM=3 (Comet) case the epoch of perihelion
is stored as the 8th element (the epoch of the elements is still
returned as the first element) [corresponding to array index 10].
This usage of the final element can be determined by noting that
the element before it (AORL) will be undefined in the case of JFORM=3.
If AORL is defined then the Epoch of perihelion will not be written
even if it is defined.

=cut

sub array {
  my $self = shift;
  my %el = $self->elements;

  # use EPOCHPERIH if EPOCH is not defined
  my $epoch = $el{EPOCH};
  $epoch = $el{EPOCHPERIH} unless $epoch;

  # the 8th element can be the EPOCHPERIH or DM field
  # dependent on the element type.
  my $lastel;
  if (defined $el{EPOCHPERIH} && !defined $el{DM}
      && !defined $el{AORL}) {
    $lastel = $el{EPOCHPERIH};
  } else {
    $lastel = $el{DM};
  }

  return ( $self->type, undef, undef,
	   $epoch, $el{ORBINC}, $el{ANODE}, $el{PERIH},
	   $el{AORQ}, $el{E}, $el{AORL}, $lastel);
}

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "ELEMENTS".

This is used to aid construction of summary tables when using
mixed coordinates.

It could be done using isa relationships.

=cut

sub type {
  return "ELEMENTS";
}

=item B<stringify>

Stringify overload. Returns comma-separated list of
the elements.

=cut

sub stringify {
  my $self = shift;
  my %el = $self->elements;
  my $str = join(",", map { (defined $_ ? $_ : 'UNDEF' ) } values %el);
  return $str;
}

=item B<summary>

Return a one line summary of the coordinates.
In the future will accept arguments to control output.

  $summary = $c->summary();

=cut

sub summary {
  my $self = shift;
  my $name = $self->name;
  $name = '' unless defined $name;
  return sprintf("%-16s  %-12s  %-11s ELEMENTS",$name,'','');
}

=item B<apparent>

Return the apparent RA and Dec (as two C<Astro::Coords::Angle>
objects) for the current coordinates and time. Includes perterbation
corrections to convert the elements to the required epoch.

Returns empty list on error.

=cut

sub apparent {
  my $self = shift;

  my ($ra_app,$dec_app) = $self->_cache_read( "RA_APP", "DEC_APP" );

  # not in cache so must calculate it
  if (!defined $ra_app || !defined $dec_app) {

    my $tel = $self->telescope;
    my $long = (defined $tel ? $tel->long : 0.0 );
    my $lat = (defined $tel ? $tel->lat : 0.0 );
    my %el = $self->elements;
    my $jform;
    if (exists $el{DM} and defined $el{DM}) {
      # major planets
      $jform = 1;
    } elsif (exists $el{AORL} and defined $el{AORL}) {
      # minor planets
      $jform = 2;
      $el{DM} = 0;
    } else {
      # comets
      $jform = 3;
      $el{DM} = 0;
      $el{AORL} = 0;
    }

    # synch epoch if need be
    if (!exists $el{EPOCH} || !exists $el{EPOCHPERIH}) {
      if (exists $el{EPOCH}) {
	$el{EPOCHPERIH} = $el{EPOCH};
      } else {
	$el{EPOCH} = $el{EPOCHPERIH};
      }
    }

    # First have to perturb the elements to the current epoch
    # if we have a minor planet or comet
    if ( $jform == 2 || $jform == 3) {
      # for now we do not have enough information for jform=3
      # so just assume the EPOCH is the same
#    use Data::Dumper;
#    print "Before perturbing: ". Dumper(\%el);
#    print "MJD ref : " . $self->_mjd_tt . " and jform = $jform\n";
      ($el{EPOCH},$el{ORBINC}, $el{ANODE},
       $el{PERIH},$el{AORQ},$el{E},$el{AORL},
       my $jstat) = Astro::PAL::palPertel($jform,$el{EPOCH},$self->_mjd_tt,
                                          $el{EPOCHPERIH},$el{ORBINC},$el{ANODE},
                                          $el{PERIH},$el{AORQ},$el{E},$el{AORL} );

#    print "After perturbing: " .Dumper(\%el);
      croak "Error perturbing elements for target ".
	(defined $self->name ? $self->name : '' )
	  ." [status=$jstat]"
	    if $jstat != 0;
    }


  # Print out the values
  #print "EPOCH:  $el{EPOCH}\n";
  #print "ORBINC: ". ($el{ORBINC}*Astro::PAL::DR2D) . "\n";
  #print "ANODE:  ". ($el{ANODE}*Astro::PAL::DR2D) . "\n";
  #print "PERIH : ". ($el{PERIH}*Astro::PAL::DR2D) . "\n";
  #print "AORQ:   $el{AORQ}\n";
  #print "E:      $el{E}\n";

    my ($ra, $dec, $dist, $j) = Astro::PAL::palPlante($self->_mjd_tt, $long, $lat, $jform,
                                                      $el{EPOCH}, $el{ORBINC}, $el{ANODE}, $el{PERIH},
                                                      $el{AORQ}, $el{E}, $el{AORL}, $el{DM} );

    croak "Error determining apparent RA/Dec for target ".
      (defined $self->name ? $self->name : '' )
	."[status=$j]" if $j != 0;

    # Convert to angle object
    $ra_app = new Astro::Coords::Angle::Hour($ra, units => 'rad', range => '2PI');
    $dec_app = new Astro::Coords::Angle($dec, units => 'rad');

    # Store in cache
    $self->_cache_write( "RA_APP" => $ra_app, "DEC_APP" => $dec_app );
  }

  return( $ra_app, $dec_app );
}

=item B<rv>

Radial velocity of the planet relative to the Earth geocentre.

=cut

sub rv {
  croak "Not yet implemented element radial velocities";
}

=item B<vdefn>

Velocity definition. Always 'RADIO'.

=cut

sub vdefn {
  return 'RADIO';
}

=item B<vframe>

Velocity reference frame. Always 'GEO'.

=cut

sub vframe {
  return 'GEO';
}

=item B<apply_offset>

Overrided method to warn if C<Astro::Coords::apply_offset> is
called on this subclass.

=cut

sub apply_offset {
  my $self = shift;
  warn "apply_offset: applying offset to orbital elements position for a specific time.\n";
  return $self->SUPER::apply_offset(@_);
}

=back

=head1 NOTES

Usually called via C<Astro::Coords>.

=head1 LINKS

Useful sources of orbital elements can be found at
http://ssd.jpl.nasa.gov and http://cfa-www.harvard.edu/iau/Ephemerides/

=head1 REQUIREMENTS

C<Astro::PAL> is used for all internal astrometric calculations.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

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
