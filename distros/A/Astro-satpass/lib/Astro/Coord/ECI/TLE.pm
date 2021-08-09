=head1 NAME

Astro::Coord::ECI::TLE - Compute satellite locations using NORAD orbit propagation models

=head1 SYNOPSIS

The following is a semi-brief script to calculate International Space
Station visibility. You will need to substitute your own location where
indicated.

 use Astro::SpaceTrack;
 use Astro::Coord::ECI;
 use Astro::Coord::ECI::TLE;
 use Astro::Coord::ECI::TLE::Set;
 use Astro::Coord::ECI::Utils qw{deg2rad rad2deg};
 
 # 1600 Pennsylvania Avenue, Washington DC, USA
 my $your_north_latitude_in_degrees = 38.898748;
 my $your_east_longitude_in_degrees = -77.037684;
 my $your_height_above_sea_level_in_meters = 16.68;
 
 # Create object representing the observers' location.
 # Note that the input to geodetic() is latitude north
 # and longitude west, in RADIANS, and height above sea
 # level in KILOMETERS.
 
 my $loc = Astro::Coord::ECI->geodetic (
    deg2rad ($your_north_latitude_in_degrees),
    deg2rad ($your_east_longitude_in_degrees),
    $your_height_above_sea_level_in_meters/1000);
 
 # Get the 'stations' catalog from Celestrak. This includes
 # all space stations and related bodies.
 # The data are all direct-fetched, so no password is
 # needed.
 
 my $st = Astro::SpaceTrack->new( direct => 1 );
 my $data = $st->celestrak( 'stations' );
 $data->is_success or die $data->status_line;
 
 # Parse the fetched data, yielding TLE objects. Aggregate
 # them into Set objects where this is warranted. We grep
 # the data because the Celestrak catalog we fetched
 # contains other stuff than the International Space
 # Station.
 
 my @sats = grep { '25544' eq $_->get( 'id' ) }
     Astro::Coord::ECI::TLE::Set->aggregate(
     Astro::Coord::ECI::TLE->parse( $data->content() ) );
 
 # We want passes for the next 7 days.
  
 my $start = time ();
 my $finish = $start + 7 * 86400;
 
 # Loop through our objects and predict passes. The
 # validate() step is usually not needed for data from
 # Space Track, but NASA's predicted elements for Space
 # Shuttle flights can be funky.
 
 my @passes;
 foreach my $tle (@sats) {
    $tle->validate($start, $finish) or next;
    push @passes, $tle->pass($loc, $start, $finish);
 }
 print <<eod;
      Date/Time          Satellite        Elevation  Azimuth Event
 eod
 foreach my $pass (sort {$a->{time} <=> $b->{time}} @passes) {
 
 #  The returned angles are in radians, so we need to
 #  convert back to degrees.
 #
 #  Note that unless Scalar::Util::dualvar works, the event output
 #  will be integers.
 
    print "\n";
 
    foreach my $event (@{$pass->{events}}) {
 	printf "%s %-15s %9.1f %9.1f %-5s\n",
 	    scalar localtime $event->{time},
 	    $event->{body}->get ('name'),
 	    rad2deg ($event->{elevation}),
 	    rad2deg ($event->{azimuth}),
 	    $event->{event};
    }
 }

=head1 NOTICE

Users of JSON functionality (if any!) should be aware of a potential
problem in the way L<JSON::XS|JSON::XS> encodes numbers. The problem
basically is that the locale leaks into the encoded JSON, and if the
locale uses commas for decimal points the encoded JSON can not be
decoded. As I understand the discussion on the associated Perl ticket
the problem has always been there, but changes introduced in Perl 5.19.8
made it more likely to manifest.

Unfortunately the nature of the JSON interface is such that I have no
control over the issue, since the workaround needs to be applied at the
point the JSON C<encode()> method is called. See test F<t/tle_json.t>
for the workaround that allows tests to pass in the affected locales.
The relevant L<JSON::XS|JSON::XS> ticket is
L<https://rt.cpan.org/Public/Bug/Display.html?id=93307>. The relevant Perl
ticket is L<https://github.com/perl/perl5/issues/13620>.

The C<pass_threshold> attribute has undergone a slight change in
functionality from version 0.046, in which it was introduced. In the new
functionality, if the C<visible> attribute is true, the satellite must
actually be visible above the threshold to be reported. This is actually
how the attribute would have worked when introduced if I had thought it
through clearly.

Use of the C<SATNAME> JSON attribute to represent the common name of the
satellite is deprecated in favor of the C<OBJECT_NAME> attribute, since
the latter is what Space Track uses in their TLE data. Beginning with
0.053_01, JSON output of TLEs will use the new name.

Beginning with release 0.056_01, loading JSON TLE data which specifies
C<SATNAME> produces a warning the first time it happens. As of version
0.061 there is a warning every time it happens. As of version 0.066
loading JSON TLE data which specifies C<SATNAME> is a fatal error. Six
months after this, all code referring to C<SATNAME> will be removed,
meaning that the key will be silently ignored.

=head1 DESCRIPTION

This module implements the orbital propagation models described in
"SPACETRACK REPORT NO. 3, Models for Propagation of NORAD Element Sets"
and "Revisiting Spacetrack Report #3." See the
L<ACKNOWLEDGMENTS|/ACKNOWLEDGMENTS> section for details on these
reports.

In other words, this module turns the two- or three-line element sets
available from such places as L<https://www.space-track.org/> or
L<http://celestrak.com/> into predictions of where the relevant orbiting
bodies will be. Additionally, the pass() method implements an actual
visibility prediction system.

The models implemented are:

  SGP - fairly simple, only useful for near-earth bodies;
  SGP4 - more complex, only useful for near-earth bodies;
  SDP4 - corresponds to SGP4, but for deep-space bodies;
  SGP8 - more complex still, only for near-earth bodies;
  SDP8 - corresponds to SGP8, but for deep-space bodies;
  SGP4R - updates and combines SGP4 and SDP4.

All the above models compute ECI coordinates in kilometers, and
velocities along the same axes in kilometers per second.

There are also some meta-models, with the smarts to run either a
near-earth model or the corresponding deep-space model depending on the
body the object represents:

  model - uses the preferred model (sgp4r);
  model4 - runs sgp4 or sdp4;
  model4r - runs sgp4r;
  model8 - runs sgp8 or sdp8.

In addition, I have on at least one occasion wanted to turn off the
automatic calculation of position when the time was set. That is
accomplished with this model:

  null - does nothing.

The models do not return the coordinates directly, they simply set the
coordinates represented by the object (by virtue of being a subclass of
L<Astro::Coord::ECI|Astro::Coord::ECI>) and return the object itself.
You can then call the appropriate inherited method to get the
coordinates of the body in whatever coordinate system is convenient. For
example, to find the latitude, longitude, and altitude of a body at a
given time, you do

  my ($lat, $long, $alt) = $body->model ($time)->geodetic;

Or, assuming the C<model> attribute is set the way you want
it, by

  my ($lat, $long, $alt) = $body->geodetic ($time);

It is also possible to run the desired model (as specified by the
C<model> attribute) simply by setting the time represented
by the object.

As of release 0.016, the recommended model to use is SGP4R, which was
added in that release. The SGP4R model, described in "Revisiting
Spacetrack Report #3"
(L<http://celestrak.com/publications/AIAA/2006-6753/>), combines SGP4
and SDP4, and updates them. For the details of the changes, see the
report.

Prior to release 0.016, the recommended model to use was either SGP4 or
SDP4, depending on whether the orbital elements are for a near-earth or
deep-space body. For the purpose of these models, any body with a period
of at least 225 minutes is considered to be a deep-space body.

The NORAD report claims accuracy of 5 or 6 places a day after the epoch
of an element set for the original FORTRAN IV, which used (mostly) 8
place single-precision calculations. Perl typically uses many more
places, but it does not follow that the models are correspondingly more
accurate when implemented in Perl. My understanding is that in general
(i.e. disregarding the characteristics of a particular implementation of
the models involved) the total error of the predictions (including error
in measuring the position of the satellite) runs from a few hundred
meters to as much as a kilometer.

I have no information on the accuracy claims of SGP4R.

This module is a computer-assisted translation of the FORTRAN reference
implementations in "SPACETRACK REPORT NO. 3" and "Revisiting Spacetrack
Report #3." That means, basically, that I ran the FORTRAN through a Perl
script that handled the translation of the assignment statements into
Perl, and then fixed up the logic by hand. Dominik Borkowski's SGP C-lib
was used as a reference implementation for testing purposes, because I
didn't have a Pascal compiler, and I have yet to get any model but SGP
to run correctly under g77.

=head2 Methods

The following methods should be considered public:

=over 4

=cut

package Astro::Coord::ECI::TLE;

use strict;
use warnings;

our $VERSION = '0.121';

use base qw{ Astro::Coord::ECI Exporter };

use Astro::Coord::ECI::Utils qw{ :params :ref :greg_time deg2rad distsq
    dynamical_delta embodies find_first_true fold_case
    format_space_track_json_time load_module looks_like_number max min
    mod2pi PI PIOVER2 rad2deg SECSPERDAY TWOPI thetag __default_station
    @CARP_NOT
    };

use Carp qw{carp croak confess};
use Data::Dumper;
use IO::File;
use POSIX qw{ ceil floor fmod strftime };
use Scalar::Util ();

BEGIN {
    local $@;
    eval {require Scalar::Util; Scalar::Util->import ('dualvar'); 1}
	or *dualvar = sub {$_[0]};
}

{	# Local symbol block.
    my @const = qw{
	PASS_EVENT_NONE
	PASS_EVENT_SHADOWED
	PASS_EVENT_LIT
	PASS_EVENT_DAY
	PASS_EVENT_RISE
	PASS_EVENT_MAX
	PASS_EVENT_SET
	PASS_EVENT_APPULSE
	PASS_EVENT_START
	PASS_EVENT_END
	PASS_EVENT_BRIGHTEST
	PASS_VARIANT_VISIBLE_EVENTS
	PASS_VARIANT_FAKE_MAX
	PASS_VARIANT_NO_ILLUMINATION
	PASS_VARIANT_START_END
	PASS_VARIANT_BRIGHTEST
	PASS_VARIANT_TRUNCATE
	PASS_VARIANT_NONE
	BODY_TYPE_UNKNOWN
	BODY_TYPE_DEBRIS
	BODY_TYPE_ROCKET_BODY
	BODY_TYPE_PAYLOAD
    };
    our @EXPORT_OK = @const;
    our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
	constants => \@const
    );
}

use constant RE_ALL_DIGITS	=> qr{ \A [0-9]+ \z }smx;

# The following constants are from section 12 (Users Guide, Constants,
# and Symbols) of SpaceTrack Report No. 3, Models for Propagation of
# NORAD Element Sets by Felix R. Hoots and Ronald L. Roehrich, December
# 1980, compiled by T. S. Kelso 31 December 1988. The FORTRAN variables
# in the original are defined without the "SGP_" prefix. Were there
# are duplicates (with one commented out), the commented-out version is
# the one in the NORAD report, and the replacement has greater
# precision. If there are two commented out, the second was a greater
# precision constant, and the third is (ultimately) calculated based
# on pi = atan2 (0, -1).

use constant SGP_CK2 => 5.413080E-4;
use constant SGP_CK4 => .62098875E-6;
use constant SGP_E6A => 1.0E-6;
use constant SGP_QOMS2T => 1.88027916E-9;
use constant SGP_S => 1.01222928;
## use constant SGP_TOTHRD => .66666667;
use constant SGP_TOTHRD => 2 / 3;
use constant SGP_XJ3 => -.253881E-5;
use constant SGP_XKE => .743669161E-1;
use constant SGP_XKMPER => 6378.135;	# Earth radius, KM.
use constant SGP_XMNPDA => 1440.0;	# Time units per day.
use constant SGP_XSCPMN => 60;		# Seconds per time unit.
use constant SGP_AE => 1.0;		# Distance units / earth radii.
## use constant SGP_DE2RA => .174532925E-1;	# radians/degree.
## use constant SGP_DE2RA => 0.0174532925199433;	# radians/degree.
use constant SGP_DE2RA => PI / 180;		# radians/degree.
## use constant SGP_PI => 3.14159265;	# Pi.
## use constant SGP_PI => 3.14159265358979;	# Pi.
use constant SGP_PI => PI;			# Pi.
## use constant SGP_PIO2 => 1.57079633;	# Pi/2.
## use constant SGP_PIO2 => 1.5707963267949;	# Pi/2.
use constant SGP_PIO2 => PIOVER2;		# Pi/2.
## use constant SGP_TWOPI => 6.2831853;	# 2 * Pi.
## use constant SGP_TWOPI => 6.28318530717959;	# 2 * Pi.
use constant SGP_TWOPI => TWOPI;		# 2 * Pi.
## use constant SGP_X3PIO2 => 4.71238898;	# 3 * Pi / 2.
## use constant SGP_X3PIO2 => 4.71238898038469;	# 3 * Pi / 2.
use constant SGP_X3PIO2 => 3 * PIOVER2;

use constant SGP_RHO => .15696615;

# FORTRAN variable glossary, read from same source, and stated in
# terms of the output produced by the parse method.
#
# EPOCH => epoch
# XNDT20 => firstderivative
# XNDD60 => secondderivative
# BSTAR => bstardrag
# XINCL => inclination
# XNODE0 => ascendingnode
# E0 => eccentricity
# OMEGA0 => argumentofperigee
# XM0 => meananomaly
# XNO => meanmotion

#	List all the legitimate attributes for the purposes of the
#	get and set methods. Possible values of the hash are:
#	    undef => read-only attribute
#	    0 => no model re-initializing necessary
#	    1 => at least one model needs re-initializing
#	    code reference - the reference is called with the
#		object unmodified, with the arguments
#		being the object, the name of the attribute,
#		and the new value of the attribute. The code
#		must make the needed changes to the attribute, and
#		return 0 or 1, interpreted as above.

my %attrib = (
    backdate => 0,
    effective => sub {
	my ($self, $name, $value) = @_;
	if ( defined $value && ! looks_like_number( $value ) ) {
	    if ( $value =~ m{ \A ([0-9]+) / ([0-9]+) / ([0-9]+) : ([0-9]+) :
		    ([0-9]+ (?: [.] [0-9]* )? ) \z }smx ) {
		$value = greg_time_gm( 0, 0, 0, 1, 0,
		    __tle_year_to_Gregorian_year( $1 + 0 ) ) + (
		    (($2 - 1) * 24 + $3) * 60 + $4) * 60 + $5;
	    } else {
		carp "Invalid effective date '$value'";
		$value = undef;
	    }
	}
	$self->{$name} = $value;
	return 0;
    },
    classification => 0,
    international => \&_set_intldes,
    epoch => sub {
	$_[0]{$_[1]} = $_[2];
	$_[0]{ds50} = $_[0]->ds50 ();
	$_[0]{epoch_dynamical} = $_[2] + dynamical_delta ($_[2]);
	return 1;
    },
    firstderivative => 1,
    gravconst_r => sub {
	($_[2] == 72 || $_[2] == 721 || $_[2] == 84)
	    or croak "Error - Illegal gravconst_r; must be 72, 721, or 84";
	$_[0]{$_[1]} = $_[2];
	return 1;		# sgp4r needs reinit if this changes.
    },
    secondderivative => 1,
    bstardrag => 1,
    ephemeristype => 0,
    elementnumber => 0,
    inclination => 1,
    model => sub {
	$_[0]->is_valid_model ($_[2]) || croak <<eod;
Error - Illegal model name '$_[2]'.
eod
	$_[0]{$_[1]} = $_[2];
	return 0;
    },
    model_error => 0,
    ascendingnode => 1,
    eccentricity => 1,
    argumentofperigee => 1,
    meananomaly => 1,
    meanmotion => 1,
    revolutionsatepoch => 0,
    debug => 0,
    geometric => 0,	# Use geometric horizon for pass rise/set.
    visible => 0,	# Pass() reports only illuminated passes.
    appulse => 0,	# Maximum appulse to report.
    interval => 0,	# Interval for pass() positions, if positive.
    lazy_pass_position => 0,	# Position optional if true.
    pass_variant => sub {
	my ( $self, $name, $val ) = @_;
	$val =~ RE_ALL_DIGITS
	    or croak 'The pass_variant attribute must be an unsigned number';
	$self->{$name} = $val;
	return 0;
    },
    ds50 => undef,	# Read-only
    epoch_dynamical => undef,	# Read-only
    rcs => 0,		# Radar cross-section
    tle => undef,	# Read-only
    file	=> \&_set_optional_unsigned_integer_no_reinit,
    illum	=> \&_set_illum,
    launch_year => \&_set_intldes_part,
    launch_num	=> \&_set_intldes_part,
    launch_piece	=> \&_set_intldes_part,
    object_type	=> \&_set_object_type,
    ordinal	=> \&_set_optional_unsigned_integer_no_reinit,
    originator	=> 0,
    pass_threshold => sub {
	my ($self, $name, $value) = @_;
	not defined $value
	    or looks_like_number( $value )
	    or carp "Invalid $name '$value'";
	$self->{$name} = $value;
	return 0;
    },
    reblessable => sub {
	my $doit = !$_[0]{$_[1]} && $_[2] && $_[0]->get ('id');
	$_[0]{$_[1]} = $_[2];
	$doit and $_[0]->rebless ();
	return 0;
    },
    intrinsic_magnitude	=> \&_set_optional_float_no_reinit,
);
my %static = (
    appulse => deg2rad (10),	# Report appulses < 10 degrees.
    backdate => 1,	# Use object in pass before its epoch.
    geometric => 0,	# Use geometric horizon for pass rise/set.
    gravconst_r => 72,	# Specify geodetic data set for sgp4r.
    illum => 'sun',
    interval => 0,
    lazy_pass_position => 0,
    model => 'model',
    pass_variant => 0,
    reblessable => 1,
    visible => 1,
);
my %model_attrib = (	# For the benefit of is_model_attribute()
    ds50 => 1,		# Read-only, but it fits the definition.
    epoch => 1,		# Hand-set, since we dont want to call the code.
    epoch_dynamical => 1,	# Read-only, but fits the definition.
);
foreach (keys %attrib) {
    $model_attrib{$_} = 1 if $attrib{$_} && !ref $attrib{$_}
}
my %status;	# Subclassing data - initialized at end
my %magnitude_table;	# Magnitude data - initialized at end
my $magnitude_adjust = 0;	# Adjustment to magnitude table value

use constant TLE_INIT => '_init';

=item $tle = Astro::Coord::ECI::TLE->new()

This method instantiates an object to represent a NORAD two- or
three-line orbital element set. This is a subclass of
L<Astro::Coord::ECI|Astro::Coord::ECI>.

Any arguments get passed to the set() method.

It is both anticipated and recommended that you use the parse()
method instead of this method to create an object, since the models
currently have no code to guard against incomplete data.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new (%static, @_);
    return $self;
}

=item $tle->after_reblessing (\%possible_attributes)

This method supports reblessing into a subclass, with the argument
representing attributes that the subclass may wish to set.  It is called
by rebless() and should not be called by the user.

At this level it does nothing.

=cut

sub after_reblessing {}

=item Astro::Coord::ECI::TLE->alias (name => class ...)

This static method adds an alias for a class name, for the benefit of
users of the status() method and 'illum' attributes, and ultimately of
the rebless() method. It is intended to be used by subclasses to
register short names for themselves upon initialization, though of
course you can call it yourself as well.

For example, this class calls

 __PACKAGE__->alias (tle => __PACKAGE__);

You can register more than one alias in a single call. Aliases
can be deleted by assigning them a false value (e.g. '' or undef).

If called without arguments, it returns the current aliases.

You can actually call this as a normal method, but it still behaves
like a static method.

=cut

my %type_map = ();

sub alias {
    my ($self, @args) = @_;
    @args % 2 and croak <<eod;
Error - Must have even number of arguments for alias().
eod
    return wantarray ? %type_map : {%type_map} unless @args;
    while (@args) {
	my $name = shift @args;
	my $class = shift @args or do {
	    delete $type_map{$name};
	    next;
	};
	$class = $type_map{$class} if $type_map{$class};
	load_module ($class);
	$type_map{$name} = $class;
    }
    return $self;
}
__PACKAGE__->alias (tle => __PACKAGE__);

=item $kilometers = $tle->apoapsis();

This method returns the apoapsis of the orbit, in kilometers. Since
Astro::Coord::ECI::TLE objects always represent bodies orbiting the
Earth, this is more usually called apogee.

Note that this is the distance from the center of the Earth, not the
altitude.

=cut

sub apoapsis {
    my $self = shift;
    return $self->{&TLE_INIT}{TLE_apoapsis} ||=
	(1 + $self->get('eccentricity')) * $self->semimajor();
}

=item $kilometers = $tle->apogee();

This method is simply a synonym for apoapsis().

=cut

*apogee = \&apoapsis;

#	See Astro::Coord::ECI for docs.

sub attribute {
    return exists $attrib{$_[1]} ?
	__PACKAGE__ :
	$_[0]->SUPER::attribute ($_[1])
}

=item $tle->before_reblessing ()

This method supports reblessing into a subclass. It is intended to do
any cleanup the old class needs before reblessing into the new class. It
is called by rebless(), and should not be called by the user.

At this level it does nothing.

=cut

sub before_reblessing {}

=item $type = $tle->body_type ()

This method returns the type of the body as one of the BODY_TYPE_*
constants. This is the C<'object_type'> attribute if that is defined.
Otherwise it is derived from the common name using an algorithm similar
to the one used by the Space Track web site. This algorithm will not
work if the common name is not available, or if it does not conform to
the Space Track naming conventions. Known or suspected differences from
the algorithm described at the bottom of the Satellite Box Score page
include:

* The C<Astro::Coord::ECI::TLE> algorithm is not case-sensitive. The
Space Track algorithm appears to assume all upper-case.

* The C<Astro::Coord::ECI::TLE> algorithm looks for words (that is,
alphanumeric strings delimited by non-alphanumeric characters), whereas
the Space Track documentation seems to say it just looks for substrings.
However, implementing the documented algorithm literally results in OID
20479 'DEBUT (ORIZURU)' being classified as debris, whereas Space Track
returns it in response to a query for name 'deb' that excludes debris.

The possible returns are:

C<< BODY_TYPE_UNKNOWN => dualvar( 0, 'unknown' ) >> if the value of the
C<name> attribute is C<undef>, or if it is empty or contains only
white space.

C<< BODY_TYPE_DEBRIS => dualvar( 1, 'debris' ) >> if the value of the
C<name> attribute contains one of the words 'deb', 'debris', 'coolant',
'shroud', or 'westford needles', all checks being case-insensitive.

C<< BODY_TYPE_ROCKET_BODY => dualvar( 2, 'rocket body' ) >> if the body
is not debris, but the value of the C<name> attribute contains one of
the strings 'r/b', 'akm' (for 'apogee kick motor') or 'pkm' (for
'perigee kick motor') all checks being case-insensitive.

C<< BODY_TYPE_PAYLOAD => dualvar( 3, 'payload' ) >> if the body is not
unknown, debris, or a rocket body.

The above constants are not exported by default, but they are exportable
either by name or using the C<:constants> tag.

If L<Scalar::Util|Scalar::Util> does not export C<dualvar()>, the
constants are defined to be numeric. The cautious programmer will
therefore test them using numeric tests.

=cut

use constant BODY_TYPE_UNKNOWN => dualvar( 0, 'unknown' );
use constant BODY_TYPE_DEBRIS => dualvar( 1, 'debris' );
use constant BODY_TYPE_ROCKET_BODY => dualvar( 2, 'rocket body' );
use constant BODY_TYPE_PAYLOAD => dualvar( 3, 'payload' );

sub body_type {
    my ( $self ) = @_;
    my $type;
    $type = $self->get( 'object_type' )
	and return $type;
    defined( my $name = $self->get( 'name' ) )
	or return BODY_TYPE_UNKNOWN;
    $name =~ m/ \A \s* \z /smx
	and return BODY_TYPE_UNKNOWN;
    ( $name =~ m/ \b deb \b /smxi
	|| $name =~ m/ \b debris \b /smxi
	|| $name =~ m/ \b coolant \b /smxi
	|| $name =~ m/ \b shroud \b /smxi
	|| $name =~ m/ \b westford \s+ needles \b /smxi )
	and return BODY_TYPE_DEBRIS;
    ( $name =~ m{ \b r/b \b }smxi
	|| $name =~ m/ \b [ap] km \b /smxi )
	and return BODY_TYPE_ROCKET_BODY;
    return BODY_TYPE_PAYLOAD;
}

=item $tle->can_flare ()

This method returns true if the object is capable of generating flares
(i.e. predictable bright flashes) and false otherwise. At this level
of the inheritance hierarchy, it always returns false, but subclasses
may return true.

=cut

sub can_flare {return 0}

=item $elevation = $tle->correct_for_refraction( $elevation )

This override of the superclass' method simply returns the elevation
passed to it. Atmospheric refraction at orbital altitudes is going to be
negligible except B<extremely> close to the horizon, and I have no
algorithm for that.

If I B<do> come up with something to handle refraction close to the
horizon, though, it will appear here. One would expect the refraction
right at the limb to be twice that calculated by Thorfinn's algorithm
(used in the superclass) because the light travels to the Earth's
surface and back out again.

See the L<Astro::Coord::ECI|Astro::Coord::ECI> C<azel()> and
C<azel_offset()> documentation for whether this class'
C<correct_for_refraction()> method is actually called by those methods.

=cut

sub correct_for_refraction {
    my ( undef, $elevation ) = @_;	# Invocant unused
    return $elevation;
}

=item $value = $tle->ds50($time)

This method converts the time to days since 1950 Jan 0, 0 h GMT.
The time defaults to the epoch of the data set. This method does not
affect the $tle object - it is exposed for convenience and for testing
purposes.

It can also be called as a "static" method, i.e. as
Astro::Coord::ECI::TLE->ds50 ($time), but in this case the time may not
be defaulted, and no attempt has been made to make this a pretty error.

=cut

{	# Begin local symbol block

#	Because different Perl implementations may have different
#	epochs, we assume that 2000 Jan 1 0h UT is representable, and
#	pre-calculate that time in terms of seconds since the epoch.
#	Then, when the method is called, we convert the argument to
#	days since Y2K, and then add the magic number needed to get
#	us to days since 1950 Jan 0 0h UT.

    my $y2k = greg_time_gm( 0, 0, 0, 1, 0, 2000 );	# Calc. time of 2000 Jan 1 0h UT

    sub ds50 {
	my ($self, $epoch) = @_;
	defined $epoch or $epoch = $self->{epoch};
	my $rslt = ($epoch - $y2k) / SECSPERDAY + 18263;
	(ref $self && $self->{debug}) and print <<eod;
Debug ds50 ($epoch) = $rslt
eod
	return $rslt;
    }
}	# End local symbol block

=item $value = $tle->get('attribute')

This method retrieves the value of the given attribute. See the
L</Attributes> section for a description of the attributes.

=cut

{
    my %accessor = (
	tle => sub {$_[0]{$_[1]} ||= $_[0]->_make_tle()},
    );
    sub get {
	my $self = shift;
	my $name = shift;
	if (ref $self) {
	    exists $attrib{$name} or return $self->SUPER::get ($name);
	    return $accessor{$name} ?
		$accessor{$name}->($self, $name) :
		$self->{$name};
	} else {
	    exists $static{$name} or
		return $self->SUPER::get ($name);
	    return $static{$name};
	}
    }
}

=item $illuminated = $tle->illuminated();

This method returns a true value if the body is illuminated, and a false
value if it is not.

=cut

sub illuminated {
    my ( $self, $time ) = @_;
    return $self->__sun_elev_from_sat( $time ) >= 0;
}

=item @events = $tle->intrinsic_events( $start, $end );

This method returns any events that are intrinsic to the C<$tle> object.
If optional argument C<$start> is defined, only events occurring at or
after that Perl time are returned. Similarly, if optional argument
C<$end> is defined, only events occurring before that Perl time are
returned.

The return is an array of array references. Each array reference
specifies the Perl time of the event and a text description of the
event.

At this level of the object hierarchy nothing is returned. Subclasses
may override this to add C<pass()> events. The overrides should return
anything returned by C<SUPER::intrinsic_events(...)> in addition to
anything they return themselves.

The order of the returned events is undefined.

=cut

sub intrinsic_events {
    return;
}

=item $deep = $tle->is_deep();

This method returns true if the object is in deep space - meaning that
its period is at least 225 minutes (= 13500 seconds).

=cut

sub is_deep {
    return $_[0]->{&TLE_INIT}{TLE_isdeep}
	if exists $_[0]->{&TLE_INIT}{TLE_isdeep};
    return ($_[0]->{&TLE_INIT}{TLE_isdeep} = $_[0]->period () >= 13500);
}

=item $boolean = $tle->is_model_attribute ($name);

This method returns true if the named attribute is an attribute of
the model - i.e. it came from the TLE data and actually affects the
model computations. It is really for the benefit of
Astro::Coord::ECI::TLE::Set, so that class can determine how its
set() method should handle the attribute.

=cut

sub is_model_attribute { return $model_attrib{$_[1]} }

=item $boolean = $tle->is_valid_model ($model_name);

This method returns true if the given name is the name of an orbital
model, and false otherwise.

Actually, in the spirit of UNIVERSAL::can, it returns a reference to
the code if the model exists, and undef otherwise.

This is really for the benefit of Astro::Coord::ECI::TLE::Set, so it
knows it needs to select the correct member object before running the
model.

This method can be called as a static method, or even as a subroutine.

=cut

{	# Begin local symbol block

    my %valid = map {$_ => __PACKAGE__->can ($_)}
	qw{model model4 model4r model8 null sdp4 sdp8 sgp sgp4 sgp4r sgp8};

    #>>>	NOTE WELL
    #>>>	If a model is added, the period method must change
    #>>>	as well, to calculate using the new model. I really
    #>>>	ought to do all this with code attributes.

    sub is_valid_model {
	return $valid{$_[1]}
    }

}	# End local symbol block

=item $mag = $tle->magnitude( $station );

This method returns the magnitude of the body as seen from the given
station. If no C<$station> is specified, the object's C<'station'>
attribute is used. If that is not set, and exception is thrown.

This is calculated from the C<'intrinsic_magnitude'> attribute, the
distance from the station to the satellite, and the fraction of the
satellite illuminated. The formula is from Mike McCants.

We return C<undef> if the C<'intrinsic_magnitude'> or C<'illum'>
attributes are C<undef>, or if the illuminating body is below the
horizon as seen from the satellite.

After this method returns the time set in the station attribute should
be considered undefined. In fact, it will be set to the same time as the
invocant if a defined magnitude was returned. But if C<undef> was
returned, the station's time may not have been changed.

Some very desultory investigation of International Space Station
magnitude predictions suggests that this method produces magnitude
estimates about half a magnitude less bright than Heavens Above.

=cut

sub magnitude {
    my ( $self, $sta ) = __default_station( @_ );

    # If we have no standard magnitude, just return undef.
    defined( my $std_mag = $self->get( 'intrinsic_magnitude' ) )
	or return undef;	## no critic (ProhibitExplicitReturnUndef)

    # If we have no illuminating body for some reason, we also have to
    # just return undef.
    my $illum = $self->get( 'illum' )
	or return undef;	## no critic (ProhibitExplicitReturnUndef)

    # Pick up the time.
    my $time = $self->universal();

    # If the illuminating body is below the horizon, we return undef.
    $self->illuminated()
	or return undef;	## no critic (ProhibitExplicitReturnUndef)

    # Compute the range amd the elevation.
    my ( undef, $elev, $range ) = $sta->universal( $time )->azel( $self );

    # If the satellite is below the horizon, just return undef
    $elev < 0
	and return undef;	## no critic (ProhibitExplicitReturnUndef)

    # Adjust the magnitude if the illuminating body is not the Sun.
    my $mag_adj = $illum->isa( 'Astro::Coord::ECI::Sun' ) ? 0 :
	$illum->magnitude() - Astro::Coord::ECI::Sun->MEAN_MAGNITUDE();

    # Compute the fraction of the satellite illuminated.
    my $frac_illum = ( 1 + cos( $self->angle( $illum, $sta ) ) ) / 2;

    # Finally we get to McCants' algorithm
    return $std_mag + $mag_adj - 15.75 +
	2.5 * log( $range ** 2 / $frac_illum ) / log( 10 );

}

=item Astro::Coord::ECI::TLE->magnitude_table( command => arguments ...)

This method maintains the internal magnitude table, which is used by the
parse() method to fill in magnitudes, since they are not normally
available from the usual sources.  The first argument determines what is
done to the status table; subsequent arguments depend on the first
argument. Valid commands and arguments are:

C<magnitude_table( add => $id, $mag )> adds a magnitude entry to the
table, replacing the existing entry for the given OID if any.

C<magnitude_table( adjust => $adjustment )> maintains a magnitude
adjustment to be added to the value in the magnitude table before
setting the C<intrinsic_magnitude> of an object. If the argument is
C<undef> the current adjustment is returned; otherwise the argument
becomes the new adjustment. Actual magnitude table entries are not
modified by this operation; the adjustment is done in the C<parse()>
method.

C<magnitude_table( 'clear' )> clears the magnitude table.

C<magnitude_table( drop => $id )> removes the given OID from the table
if it is there.

C<magnitude_table( magnitude => \%mag ) replaces the magnitude table
with the contents of the given hash. The keys will be normalized to 5
digits.

C<magnitude_table( molczan => $file_name, $mag_offset )> replaces the
magnitude table with the contents of the named Molczan-format file. The
C<$file_name> argument can also be a scalar reference with the scalar
containing the data, or an open handle. The C<$mag_offset> is an
adjustment to be added to the magnitudes read from the file, and
defaults to 0.

C<magnitude_table( quicksat => $file_name, $mag_offset )> replaces the
magnitude table with the contents of the named Quicksat-format file. The
C<$file_name> argument can also be a scalar reference with the scalar
containing the data, or an open handle. The C<$mag_offset> is an
adjustment to be added to the magnitudes read from the file, and
defaults to 0. In addition to this value, C<0.7> is added to the
magnitude before storage to adjust the data from full-phase to
half-phase.

C<magnitude_table( show => ... )> returns an array which is a slice of
the magnitude table, which is stored as a hash. In other words, it
returns OID/magnitude pairs in no particular order. If any further
arguments are passed, they are the OIDs to return. Otherwise all are
returned.

Examples of Molczan-format data are contained in F<mcnames.zip> and
F<vsnames.zip> available on Mike McCants' web site; these can be fetched
using the L<Astro::SpaceTrack|Astro::SpaceTrack> C<mccants()> method. An
example of Quicksat-format data is contained in F<qsmag.zip>. See Mike
McCants' web site, L<https://www.prismnet.com/~mmccants/> for an
explanation of the differences.

Note that if you have one of the reported pure Perl versions of
L<Scalar::Util|Scalar::Util>, you can not pass open handles to
functionality that would otherwise accept them.

=cut

{
    my $openhandle = Scalar::Util->can( 'openhandle' ) || sub { return };

    my $parse_file = sub {
	my ( $file_name, $mag_offset, $parse_info ) = @_;
	defined $mag_offset
	    or $mag_offset = 0;
	$mag_offset += $parse_info->{mag_offset};
	my %mag;
	my $fh;
	if ( $openhandle->( $file_name ) ) {
	    $fh = $file_name;
	} else {
	    open $fh, '<', $file_name	## no critic (RequireBriefOpen)
		or croak "Failed to open $file_name: $!";
	}
	while ( <$fh> ) {
	    chomp;
	    m/ \A \s* (?: \# | \z ) /smx
		and next;	# Extension to syntax.
	    $parse_info->{pad} > length
		and $_ = sprintf '%-*s', $parse_info->{pad}, $_;
	    # Perl 5.8 and below require an explicit buffer to unpack.
	    my ( $id, $mag ) = unpack $parse_info->{template}, $_;
	    $mag =~ s/ \s+ //smxg;
	    looks_like_number( $mag )
		or next;
	    $mag{ _normalize_oid( $id ) } = $mag + $parse_info->{mag_offset};
	}
	close $fh;
	%magnitude_table = %mag;
    };

    my %cmd_def = (
	add	=> sub {
	    my ( $id, $mag ) = @_;
	    defined $id
		and $id =~ m/ \A [0-9]+ \z /smx
		and defined $mag
		and looks_like_number( $mag )
		or croak 'magnitude_table add needs an OID and a magnitude';
	    $magnitude_table{ _normalize_oid( $id ) } = $mag;
	    return;
	},
	adjust	=> sub {
	    my ( $adj ) = @_;
	    if ( defined $adj ) {
		looks_like_number( $adj )
		    or croak 'magnitude_table adjust needs a floating point number';
		$magnitude_adjust = $adj;
		return;
	    } else {
		return $magnitude_adjust;
	    }
	},
	clear	=> sub {
	    %magnitude_table = ();
	    return;
	},
	dump	=> sub {
	    local $Data::Dumper::Terse = 1;
	    local $Data::Dumper::Sortkeys = 1;
	    print Dumper( \%magnitude_table );
	    return;
	},
	drop	=> sub {
	    my ( $id ) = @_;
	    defined $id
		and $id =~ m/ \A [0-9]+ \z /smx
		or croak 'magnitude_table drop needs an OID';
	    delete $magnitude_table{ _normalize_oid( $id ) };
	    return;
	},
	magnitude	=> sub {
	    my ( $tbl ) = @_;
	    HASH_REF eq ref $tbl
		or croak 'magnitude_table magnitude needs a hash ref';
	    my %mag;
	    foreach my $key ( keys %{ $tbl } ) {
		my $val = $tbl->{$key};
		$key =~ m/ \A [0-9]+ \z /smx
		    or croak "OID '$key' must be numeric";
		looks_like_number( $val )
		    or croak "Magnitude '$val' must be numeric";
		$mag{ _normalize_oid( $key ) } = $val;
	    }
	    %magnitude_table = %mag;
	    return;
	},
	molczan	=> sub {
	    my ( $file_name, $mag_factor ) = @_;
	    $parse_file->( $file_name, $mag_factor, {
		    mag_offset	=> 0,
		    pad		=> 49,
		    template	=> 'a5x32a5',
		} );
	    return;
	},
	quicksat	=> sub {
	    my ( $file_name, $mag_factor ) = @_;
	    $parse_file->( $file_name, $mag_factor, {
		    mag_offset	=> 0.7,
		    pad		=> 56,
		    template	=> 'a5x28a5',
		} );
	    return;
	},
	show	=> sub {
	    my ( @arg ) = @_;
	    @arg
		or return %magnitude_table;
	    return (
		map { $_ => $magnitude_table{$_} }
		grep { defined $magnitude_table{$_} }
		map { _normalize_oid( $_ ) } @arg
	    );
	},
    );

    sub magnitude_table {
	my ( undef, $cmd, @arg ) = @_;	# Invocant not used
	my $code = $cmd_def{$cmd}
	    or croak "'$cmd' is not a valid magnitude_table subcommand";
	return $code->( @arg );
    }
}

=item $time = $tle->max_effective_date(...);

This method returns the maximum date among its arguments and the
effective date of the $tle object as set in the C<effective> attribute,
if that is defined. If no effective date is set but the C<backdate>
attribute is false, the C<epoch> of the object is used as the effective
date. If there are no arguments and no effective date, C<undef> is
returned.

=cut

sub max_effective_date {
    my ($self, @args) = @_;
    if (my $effective = $self->get('effective')) {
	push @args, $effective;
    } elsif (!$self->get('backdate')) {
	push @args, $self->get('epoch');
    }
    return max( grep {defined $_} @args );
}

=item $tle = $tle->members();

This method simply returns the object it is called on. It exists for
convenience in getting back validated objects when iterating over a
mixture of L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> and
L<Astro::Coord::ECI::TLE::Set|Astro::Coord::ECI::TLE::Set> objects.

=cut

sub members {
    return shift;
}

=item $tle = $tle->model($time)

This method calculates the position of the body described by the TLE
object at the given time, using the preferred model. As of
Astro::Coord::ECI::TLE 0.010_10 this is sgp4r; previously it was sgp4 or
sdp4, whichever was appropriate.

The intent is that this method will use whatever model is currently
preferred. If the preferred model changes, this method will use the
new preferred model as soon as I:

  - Find out about the change;
  - Can get the specifications for the new model;
  - Can find the time to code up the new model.

You need to call one of the Astro::Coord::ECI methods (e.g. geodetic ()
or equatorial ()) to retrieve the position you just calculated.

=cut

BEGIN {
    *model = \&sgp4r;
}

=item $tle = $tle->model4 ($time)

This method calculates the position of the body described by the TLE
object at the given time, using either the SGP4 or SDP4 model,
whichever is appropriate.

You need to call one of the Astro::Coord::ECI methods (e.g. geodetic ()
or equatorial ()) to retrieve the position you just calculated.

=cut

sub model4 {
    return $_[0]->is_deep ? $_[0]->sdp4 ($_[1]) : $_[0]->sgp4 ($_[1]);
}

=item $tle = $tle->model4r ($time)

This method calculates the position of the body described by the TLE
object at the given time, using the "Revisiting Spacetrack Report #3"
model (sgp4r). It is really just a synonym for sgp4r, which covers both
near-earth and deep space bodies, but is provided for consistency's
sake. If some other model becomes preferred, this method will still call
sgp4r.

You need to call one of the Astro::Coord::ECI methods (e.g. geodetic ()
or equatorial ()) to retrieve the position you just calculated.

=cut

BEGIN {
    *model4r = \&sgp4r;
}

=item $tle = $tle->model8 ($time)

This method calculates the position of the body described by the TLE
object at the given time, using either the SGP8 or SDP8 model,
whichever is appropriate.

You need to call one of the Astro::Coord::ECI methods (e.g. geodetic ()
or equatorial ()) to retrieve the position you just calculated.

=cut

sub model8 {
    return $_[0]->is_deep ? $_[0]->sdp8 ($_[1]) : $_[0]->sgp8 ($_[1]);
}

=item $tle = $tle->null ($time)

This method does nothing. It is a valid orbital model, though. If you
call $tle->set (model => 'null'), no position calculation is done as a
side effect of calling $tle->universal ($time).

=cut

sub null { return $_[0] }

=item @elements = Astro::Coord::ECI::TLE->parse( @data );

This method parses NORAD two- or three-line element sets, JSON element
sets, or a mixture, returning a list of Astro::Coord::ECI::TLE objects.
The L</Attributes> section identifies those attributes which will be
filled in by this method.

TLE input will be split into individual lines, and all blank lines and
lines beginning with '#' will be eliminated. The remaining lines are
assumed to represent two- or three-line element sets, in so-called
external format. Internal format (denoted by a 'G' in column 79 of line
1 of the set, not counting the common name if any) is not supported,
and the presence of such data will result in an exception being thrown.

Input beginning with C<[{> (with optional spaces) is presumed to be
NORAD JSON element sets and parsed accordingly.

Optionally, the first argument (after the invocant) can be a reference
to a hash of default attribute values. These are preferred over the
static values, but attributes provided by the TLE or JSON input override
both.

=cut

sub parse {
    my ($self, @args) = @_;
    my @rslt;
    my $attrs = HASH_REF eq ref $args[0] ? shift @args : {};

    my @data;
    foreach my $datum (@args) {
	ref $datum and croak <<eod;
Error - Arguments to parse() must be scalar.
eod
	if ( $datum =~ m/ \A \s* \[? \s* \{ /smx ) {
	    push @rslt, $self->_parse_json( $attrs, $datum );
	} else {
	    foreach my $line (split qr{\n}, $datum) {
		$line =~ s/ \s+ \z //smx;
		$line =~ m/ \A \s* [#] /smx and next;
		$line and push @data, $line;
	    }
	}
    }

    while (@data) {
	my %ele = ( %static, %{ $attrs } );
	my $name;
	my $line = shift @data;
	$line =~ s/\s+$//;
	my $tle = "$line\n";
	$line =~ m{ \A 1 (\s* [0-9]+) }smx and length $1 == 6 or do {
	    ( $name = $line ) =~ s/ \A 0 \s+ //smx;	# SpaceTrack 3le
	    $line = shift @data;
	    $tle .= "$line\n";
	};
	if (length ($line) > 79 && substr ($line, 79, 1) eq 'G') {
	    croak "G (internal) format data not supported";
	} else {
	    ($line =~ m/^1(\s*[0-9]+)/ && length ($1) == 6)
		or croak "Invalid line 1 '$line'";
	    length ($line) < 80 and $line .= ' ' x (80 - length ($line));

	    @ele{qw{id classification international epoch firstderivative
		secondderivative bstardrag ephemeristype elementnumber}} =
		unpack 'x2A5A1x1A8x1A14x1A10x1A8x1A8x1A1x1A4', $line;
	    $ele{elementnumber} =~ s/ \A \s+ //smx;

	    $line = shift @data;
	    $tle .= "$line\n";
	    ($line =~ m/^2(\s*[0-9]+)/ && length ($1) == 6)
		or croak "Invalid line 2 '$line'";
	    length ($line) < 80 and $line .= ' ' x (80 - length ($line));
	    @ele{qw{id_2 inclination ascendingnode eccentricity
		argumentofperigee meananomaly meanmotion
		revolutionsatepoch}} =
		unpack 'x2A5x1A8x1A8x1A7x1A8x1A8x1A11A5', $line;

	    foreach my $key ( qw{ id epoch firstderivative
		secondderivative bstardrag ephemeristype elementnumber
		id_2 inclination ascendingnode eccentricity
		argumentofperigee meananomaly meanmotion }
	    ) {
		$ele{$key} =~ s/ \s /0/smxg;
	    }

	    $ele{id} == $ele{id_2} or
		croak "Invalid data. Line 1 was for id $ele{id} but ",
		    "line 2 was for $ele{id_2}";
	    delete $ele{id_2};
	}
	foreach (qw{eccentricity}) {
	    $ele{$_} = "0.$ele{$_}" + 0;
	}
	foreach (qw{secondderivative bstardrag}) {
	    $ele{$_} =~ s/(.)(.{5})(..)/$1.$2e$3/;
	    $ele{$_} += 0;
	}
	foreach (qw{epoch}) {
	    my ($yr, $day) = $ele{$_} =~ m/(..)(.*)/;
	    $yr = __tle_year_to_Gregorian_year( $yr );
	    $ele{$_} = greg_time_gm( 0, 0, 0, 1, 0, $yr ) +
		( $day - 1 ) * SECSPERDAY;
	}

#	From here is conversion to the units expected by the
#	models.

	foreach (qw{ascendingnode argumentofperigee meananomaly
		    inclination}) {
	    $ele{$_} *= SGP_DE2RA;
	}
	my $temp = SGP_TWOPI;
	foreach (qw{meanmotion firstderivative secondderivative}) {
	    $temp /= SGP_XMNPDA;
	    $ele{$_} *= $temp;
	}

	my $body = __PACKAGE__->new (%ele);	# Note that setting the
						# ID does the reblessing.
	$body->__parse_name( $name );
	$body->{tle} = $tle;
	push @rslt, $body;
    }

    if ( keys %magnitude_table ) {
	foreach my $tle ( @rslt ) {
	    defined( my $oid = $tle->get( 'id' ) )
		or next;
	    defined $tle->get( 'intrinsic_magnitude' )
		and next;
	    defined( my $std_mag = $magnitude_table{ _normalize_oid( $oid ) } )
		or next;
	    $tle->set( intrinsic_magnitude => $std_mag +
		$magnitude_adjust );
	}
    }
    return @rslt;
}

sub __parse_name {
    my ( $self, $name ) = @_;
    defined $name
	or return;
    $name =~ s{ \s* -- ( effective | rcs ) \s+ ( \S+ ) }{
	$self->set( $1 => $2 );
	''
    }smxge;
    $name ne ''
	and $self->set( name => $name );
    return;
}

# Parse information for the above from
# CelesTrak "FAQs: Two-Line Element Set Format", by Dr. T. S. Kelso,
# http://celestrak.com/columns/v04n03/
# Per this, all data are for the NORAD SGP4/SDP4 model, except for the
# first and second time derivative, which are for the simpler SGP model.
# The actual documentation of the algorithms, along with a reference
# implementation in FORTRAN, is available at
# http://celestrak.com/NORAD/documentation/spacetrk.pdf

=item @passes = $tle->pass ($station, $start, $end, \@sky)

This method returns passes of the body over the given station between
the given start end end times. The \@sky argument is background bodies
to compute appulses with (see note 3).

A pass is detected by this method when the body sets. Unless
C<PASS_VARIANT_TRUNCATE> (see below) is in effect, this means that
passes are not usefully detected for geosynchronous or
near-geosynchronous bodies, and that passes where the body sets after
the C<$end> time will not be detected.

All arguments are optional, the defaults being

 $station = the 'station' attribute of the invocant
 $start = time()
 $end = $start + 7 days
 \@sky = []

The return is a list of passes, which may be empty. Each pass is
represented by an anonymous hash containing the following keys:

  {body} => Reference to body making pass;
  {time} => Time of pass (culmination);
  {events} => [the individual events of the pass].

The individual events are also anonymous hashes, with each hash
containing the following keys:

  {azimuth} => Azimuth of event in radians (see note 1);
  {body} => Reference to body making pass (see note 2);
  {appulse} => {  # This is present only for PASS_EVENT_APPULSE;
      {angle} => minimum separation in radians;
      {body} => other body involved in appulse;
      }
  {elevation} => Elevation of event in radians (see note 1);
  {event} => Event code (PASS_EVENT_xxxx);
  {illumination} => Illumination at time of event (PASS_EVENT_xxxx);
  {range} => Distance to event in kilometers (see note 1);
  {station} => Reference to observing station (see note 2);
  {time} => Time of event;

The events are coded by the following manifest constants:

  PASS_EVENT_NONE => dualvar (0, '');
  PASS_EVENT_SHADOWED => dualvar (1, 'shdw');
  PASS_EVENT_LIT => dualvar (2, 'lit');
  PASS_EVENT_DAY => dualvar (3, 'day');
  PASS_EVENT_RISE => dualvar (4, 'rise');
  PASS_EVENT_MAX => dualvar (5, 'max');
  PASS_EVENT_SET => dualvar (6, 'set');
  PASS_EVENT_APPULSE => dualvar (7, 'apls');
  PASS_EVENT_START => dualvar( 11, 'start' );
  PASS_EVENT_END => dualvar( 12, 'end' );
  PASS_EVENT_BRIGHTEST => dualvar( 13, 'brgt' );

The C<PASS_EVENT_START> and C<PASS_EVENT_END> events are not normally
generated. You can get them in lieu of whatever events start and end the
pass by setting C<PASS_VARIANT_START_END> in the C<pass_variant>
attribute. Unless you are filtering out non-visible events, though, they
are just the rise and set events under different names.

The dualvar function comes from Scalar::Util, and generates values
which are numeric in numeric context and strings in string context. If
Scalar::Util cannot be loaded the numeric values are returned.

These manifest constants can be imported using the individual names, or
the tags ':constants' or ':all'. They can also be accessed as methods
using (e.g.) $tle->PASS_EVENT_LIT, or as static methods using (e.g.)
Astro::Coord::ECI::TLE->PASS_EVENT_LIT.

Illumination is represented by one of PASS_EVENT_SHADOWED,
PASS_EVENT_LIT, or PASS_EVENT_DAY. The first two are calculated based on
whether the illuminating body (i.e. the body specified by the 'illum'
attribute) is above the horizon; the third is based on whether the Sun
is higher than specified by the 'twilight' attribute, and trumps the
other two (i.e. if it's day it doesn't matter whether the satellite is
illuminated).

Time resolution of the events is typically to the nearest second, except
for appulses, which need to be calculated more closely to detect
transits. The time reported for the event is the time B<after> the event
occurred. For example, the time reported for rise is the earliest time
the body is found above the horizon, and the time reported for set is
the earliest time the body is found below the horizon.

The operation of this method is affected by the following attributes,
in addition to its arguments and the orbital elements associated with
the object:

  * appulse	# Maximum appulse to report
  * edge_of_earths_shadow	# Used in the calculation of
		# whether the satellite is illuminated or in
		# shadow.
  * geometric	# Use geometric horizon for pass rise/set
  * horizon	# Effective horizon
  * interval	# Interval for pass() positions, if positive
  * lazy_pass_position # {azimuth}, {elevation} and {range}
		# are optional if true (see note 1).
  * pass_threshold # Minimum elevation satellite must reach
		# for the pass to be reportable. If visible
		# is true, it must be visible above this
		# elevation
  * pass_variant # Tweak what pass() returns; currently no
		# effect unless 'visible' is true.
  * illum	# Source of illumination.
  * twilight	# Distance of illuminator below horizon
  * visible	# Pass() reports only illuminated passes

Note 1:

If the C<lazy_pass_position> attribute is true, the {azimuth},
{elevation}, and {range} keys may not be present. This attribute gives
the event-calculating algorithm permission to omit these if the time of
the event can be determined without computing the position of the body.
Currently this happens only for events generated in response to setting
the C<interval> attribute, but the user should not make this assumption
in his or her own code.

Typically you will only want to set this true if, after calling the
C<pass()> method, you are not interested in the azimuth, elevation and
range, but compute the event positions in some coordinates other than
azimuth, elevation, and range.

Note 2:

The time set in the various {body} and {station} objects is B<not>
guaranteed to be anything in particular. Specifically, it is almost
certainly not the time of the event. If you make use of the {body}
object you will probably need to set its time to the time of the event
before you do so.

Note 3:

The algorithm for computing appulses has been modified slightly in
version 0.056_04. This modification only applies to elements
of the optional C<\@sky> array that represent artificial satellites.

The problem I'm trying to address is that two satellites in very similar
orbits can appear to converge again after their appulse, due to their
increasing distance from the observer. If this happens early enough in
the pass it can fool the binary search algorithm that determines the
appulse time.

The revision is to first step across the pass, finding the closest
approach of the two bodies. A binary search is then done on a small
interval around the closest approach.

=cut

use constant PASS_EVENT_NONE => dualvar (0, '');	# Guaranteed false.
use constant PASS_EVENT_SHADOWED => dualvar (1, 'shdw');
use constant PASS_EVENT_LIT => dualvar (2, 'lit');
use constant PASS_EVENT_DAY => dualvar (3, 'day');
use constant PASS_EVENT_RISE => dualvar (4, 'rise');
use constant PASS_EVENT_MAX => dualvar (5, 'max');
use constant PASS_EVENT_SET => dualvar (6, 'set');
use constant PASS_EVENT_APPULSE => dualvar (7, 'apls');
use constant PASS_EVENT_START => dualvar( 11, 'start' );
use constant PASS_EVENT_END => dualvar( 12, 'end' );
use constant PASS_EVENT_BRIGHTEST => dualvar( 13, 'brgt' );

use constant PASS_VARIANT_VISIBLE_EVENTS => 0x01;
use constant PASS_VARIANT_FAKE_MAX	=> 0x02;
use constant PASS_VARIANT_START_END	=> 0x04;
use constant PASS_VARIANT_NO_ILLUMINATION => 0x08;
use constant PASS_VARIANT_BRIGHTEST	=> 0x10;
use constant PASS_VARIANT_TRUNCATE	=> 0x20;
use constant PASS_VARIANT_NONE => 0x00;		# Must be 0.

my @pass_variant_mask = (
    PASS_VARIANT_NO_ILLUMINATION | PASS_VARIANT_START_END |
	PASS_VARIANT_BRIGHTEST | PASS_VARIANT_TRUNCATE,
    PASS_VARIANT_VISIBLE_EVENTS | PASS_VARIANT_FAKE_MAX |
	PASS_VARIANT_START_END | PASS_VARIANT_BRIGHTEST |
	PASS_VARIANT_TRUNCATE,
);

use constant SCREENING_HORIZON_OFFSET => deg2rad( -3 );

# *****	Promise Astro::Coord::ECI::TLE::Set that pass() only uses the
# *****	public interface. That way pass() will get the Set object,
# *****	and will work if we have more than one set of elements for the
# *****	body, even if we switch element sets in the middle of a pass.

*_nodelegate_pass = \&pass;

# The following method is not supported, and may be changed or retracted
# at any time without notice. Its purpose in life is to provide a handle
# by which the experimental and unreleased Astro::Coord::ECI::Points
# objects can manipulate the the start and end times of the pass
# calculation.
sub __default_pass_times {
    my ( undef, $start, $end ) = @_;	# Invocant unused
    defined $start
	or $start = time;
    defined $end
	or $end = $start + 7 * SECSPERDAY;
    return ( $start, $end );
}

sub pass {
    my @args = __default_station( @_ );
    my @sky;
    ARRAY_REF eq ref $args[-1]
	and @sky = @{pop @args};
    my $tle = shift @args;
    my $sta = shift @args;

    # We give subclasses a way of specifying their own default times. If
    # an undefined end time is returned, the subclass is stating that
    # there are no passes in the given range, and we simply return.
    my ( $pass_start, $pass_end ) = $tle->__default_pass_times(
	splice @args, 0, 2 );
    defined $pass_start
	or return;

    $pass_end >= $pass_start or croak <<eod;
Error - End time must be after start time.
eod

    $pass_start = $tle->max_effective_date($pass_start);
    $pass_start <= $pass_end or return;

    my @lighting = (
	PASS_EVENT_SHADOWED,
	PASS_EVENT_LIT,
	PASS_EVENT_DAY,
    );
    my $verbose = $tle->get ('interval');
    my $pass_step = 60;
    my $horizon = $tle->get ('horizon');
    my $effective_horizon = $tle->get ('geometric') ? 0 : $horizon;
    my $pass_threshold = $tle->get( 'pass_threshold' );
    my $twilight = $tle->get ('twilight');
    my $want_visible = $tle->get ('visible');
    my $appulse_dist = $tle->get ('appulse');
    my $debug = $tle->get ('debug');
    my $pass_variant = $tle->get( 'pass_variant' ) &
	$pass_variant_mask[ $want_visible ? 1 : 0 ];
    defined $tle->get( 'intrinsic_magnitude' )
	or $pass_variant &= ~ PASS_VARIANT_BRIGHTEST;
    my $truncate = $pass_variant & PASS_VARIANT_TRUNCATE;
    defined $pass_threshold
	and $pass_threshold > $horizon
	or $pass_threshold = $horizon;

    # We need the number of radians the satellite travels in a minute so
    # we can be slightly conservative determining whether the satellite
    # might be lit while screening for a pass.
    # TODO For something not in orbit the period should be undefined.
    # But we might call pass() on it anyway because something like a
    # sounding rocket would still rise and set. What we have at the
    # moment is a total crock, but until I can figure out something
    # better ...
    my $period = $tle->period();
    # TODO the next statement is the crock referred to just above
    defined $period
	or $period = 90 * 60;	# Pretend we're in a 90 min orbit
    my $min_sun_elev_from_sat = - TWOPI / $period * 60;

    # We also want to be slightly conservative when deciding whether the
    # satellite passes above the horizon. Since the above is clearly too
    # much (since at its maximum elevation the apparent path of the
    # satellite is horizontal) we reduce it using a piece of pure
    # ad-hocery.
    my $screening_horizon = $horizon + SCREENING_HORIZON_OFFSET;
    $effective_horizon < $screening_horizon
	and $screening_horizon = $effective_horizon;

#	We need the sun at some point, maybe

    my ( $sun, $suntim, $dawn, $sun_screen, $sun_limit );
    if ( $pass_variant & PASS_VARIANT_NO_ILLUMINATION ) {
	$suntim = $sun_screen = $sun_limit = $pass_end + SECSPERDAY;
	$dawn = 1;
    } else {
	$sun = $tle->get( 'sun' );
	( $suntim, $dawn, $sun_screen, $sun_limit ) =
	    _next_elevation_screen( $sta->universal( $pass_start ),
		$pass_step, $sun, $twilight );
    }

#	For each time to be covered

    my $step = $pass_step;
    my $bigstep = 5 * $step;
    my $littlestep = $step;
    my $end = $pass_end;
    $truncate
	and $end += $littlestep;
    my @info;	# Information on an individual pass.
    my @passes;	# Accumulated informtion on all passes.
    my $visible;
    for (my $time = $pass_start; $time <= $end; $time += $step) {

#	If the current sun event has occurred, handle it and calculate
#	the next one.

	if ( $time >= $sun_limit ) {
	    ( $suntim, $dawn, $sun_screen, $sun_limit ) =
		_next_elevation_screen( $sta->universal( $suntim ),
		    $pass_step, $sun, $twilight );
	}

#	Skip if the sun is up. We set the step size small, because we
#	are not actually tracking the satellite so we do not know what
#	the appropriate size is.

	$want_visible
	    and	not @info
	    and not $dawn
	    and $time < $sun_screen
	    and do {
	    $step = $littlestep;
	    next;
	};

#	Calculate azimuth and elevation.

	my ($azm, $elev, $rng) = $sta->azel ($tle->universal ($time));

#	Adjust the step size based on how far the body is below the
#	horizon.

	$step = $elev < -.4 ? $bigstep : $littlestep;

#	If the body is below the horizon, we check for accumulated data,
#	handle it if any, clear it, and on to the next iteration. We
#	have to make the check on effective horizon as well as screening
#	horizon, because maybe we are at the very end of the prediction
#	period and the satellite makes it below the effective horizon
#	but not the screening horizon before the end of the prediction
#	period. Sigh.

	if ( $elev < $screening_horizon
	    || @info && $elev < $effective_horizon &&
		$info[-1]{elevation} >= $effective_horizon
	    || $truncate && $time >= $pass_end
	) {
	    @info = () unless $visible;
	    next unless @info;

#	    We may have skipped part of the pass because it began in
#	    daylight or before the official beginning of the prediction
#	    period. Pick up that part now.

	    {	# Single-iteration loop.
		my $time = $info[0]{time} - $step;
		$truncate
		    and $time < $pass_start
		    and last;
		my ( $try_azm, $try_elev, $try_rng ) = $sta->azel (
		    $tle->universal( $time ) );
		last if $try_elev < $effective_horizon;
		my $litup = $time < $suntim ? 2 - $dawn : 1 + $dawn;
		1 == $litup
		    and not $tle->illuminated( $time )
		    and $litup = 0;
		unshift @info, {
		    azimuth => $try_azm,
		    elevation => $try_elev,
		    event => PASS_EVENT_NONE,
		    illumination => $lighting[$litup],
		    range => $try_rng,
		    time => $time,
		};
		redo;
	    }

	    # Compute the exact events.

	    my @time;

	    # Compute exact max

=begin comment

	    {
		my @try;
		if ( @info > 1 ) {
		    @try = (
			[ $info[0]{time}, $sta->azel( $tle->universal(
				    $info[0]{time} ) ) ],
			[ $info[-1]{time}, $sta->azel( $tle->universal(
				    $info[-1]{time} ) ) ],
		    );
		} else {
		    my $trial_time = $info[0]{time} - 30;
		    push @try, [ $trial_time, $sta->azel(
			    $tle->universal( $trial_time ) ) ];
		    $trial_time += 60;
		    push @try, [ $trial_time, $sta->azel(
			    $tle->universal( $trial_time ) ) ];
		}

		while ( $try[1][0] - $try[0][0] > 0.01 ) {
		    my $middle = ( $try[0][0] + $try[1][0] ) / 2;
		    my $inx = $try[0][2] > $try[1][2] ? 1 : 0;
		    splice @try, $inx, 1, [ $middle, $sta->azel(
			    $tle->universal( $middle ) ) ];
		}

		push @time, [ floor( $try[1][0] + .5 ), PASS_EVENT_MAX ];

	    }

=end comment

=cut

	    my ( $trial_start, $trial_finish ) =
		( $info[0]{time} - $pass_step,
		    $info[-1]{time} + $pass_step
		);
	    $truncate
		and ( $trial_start, $trial_finish ) = (
		    max( $trial_start, $pass_start ),
		    min( $trial_finish, $pass_end )
		);
	    my $culmination = find_first_true( $trial_start,
		$trial_finish,
		    sub { ( $sta->azel( $tle->universal( $_[0] ) ) )[1] >
			( $sta->azel( $tle->universal( $_[0] + 1 ) ) )[1]
		    });
	    push @time, [ $culmination, PASS_EVENT_MAX ];

	    # Compute exact rise and set.

	    $truncate
		or ( $trial_start, $trial_finish ) = (
		$info[0]{time} - $step, $info[-1]{time} + $step );
	    my $sat_rise = find_first_true( $trial_start,
		$culmination,
		sub { ( $sta->azel( $tle->universal( $_[0] ) ) )[1] >=
		    $effective_horizon
		},
	    );
	    my $sat_set = find_first_true ( $culmination,
		$trial_finish,
		sub { ( $sta->azel( $tle->universal( $_[0] ) ) )[1] <
		    $effective_horizon
		},
	    );
	    push @time,
		[ $sat_rise, PASS_EVENT_RISE ],
		[ $sat_set, PASS_EVENT_SET ],
	    ;

	    warn <<eod if $debug;	## no critic (RequireCarping)

Debug - Computed @{[strftime '%d-%b-%Y %H:%M:%S', localtime $time[0][0]
		    ]} $time[0][1]
                 @{[strftime '%d-%b-%Y %H:%M:%S', localtime $time[1][0]
		    ]} $time[1][1]
                 @{[strftime '%d-%b-%Y %H:%M:%S', localtime $time[2][0]
		    ]} $time[2][1]
eod

	    # Because we relaxed the detection criteria to be sure we
	    # caught all passes, we may have a pass that ended before
	    # the prediction interval started. Reject that here.

	    $sat_set < $pass_start
		and do {
		@info = ();
		next;
	    };

	    # Clear the original data.

	    @info = ();

	    # Generate the full data for the exact events.

	    my ($suntim, $dawn);
	    warn "Contents of \@time: ", Dumper (\@time)	## no critic (RequireCarping)
		if $debug;
	    foreach (sort {$a->[0] <=> $b->[0]} @time) {
		my ( $time, $evnt_name, @extra ) = @$_;
		my ($azm, $elev, $rng) = $sta->azel (
		    $tle->universal ($time));
		my @illumination;
		if ( $sun ) {
		    ($suntim, $dawn) =
			$sta->universal ($time)->next_elevation ($sun,
			    $twilight)
			if !$suntim || $time >= $suntim;
		    my $litup = $time < $suntim ? 2 - $dawn : 1 + $dawn;
		    1 == $litup
			and not $tle->illuminated( $time )
			and $litup = 0;
		    push @illumination, illumination => $lighting[$litup];
		}
		push @info, {
		    azimuth => $azm,
		    body => $tle,
		    elevation => $elev,
		    event => $evnt_name,
		    range => $rng,
		    station => $sta,
		    time => $time,
		    @illumination,
		    @extra,
		};
	    }

	    # Compute illumination changes

	    if ( $sun ) {
		my @illum;
		my $prior;
		foreach my $evt ( @info ) {
		    $prior or next;
		    $prior->{illumination} == $evt->{illumination}
			and next;
		    my ($suntim, $dawn) =
			$sta->universal ($prior->{time})->
			next_elevation ($sun, $twilight);
		    my $time = 
			find_first_true ($prior->{time}, $evt->{time},
			sub {
			    my $litup = $_[0] < $suntim ?
				2 - $dawn : 1 + $dawn;
			    1 == $litup
				and not $tle->illuminated( $_[0] )
				and $litup = 0;
			    $lighting[$litup] == $evt->{illumination}
			    });
		    my ($azm, $elev, $rng) = $sta->azel (
			$tle->universal ($time));
		    push @illum, {
			azimuth => $azm,
			body => $tle,
			elevation => $elev,
			event => $evt->{illumination},
			illumination => $evt->{illumination},
			range => $rng,
			station => $sta,
			time => $time,
		    };
		} continue {
		    $prior = $evt;
		}
		push @info, @illum;
	    }

	    # Do not record this pass if it turns out not to contain
	    # any points that meet the recording criteria.

	    eval {	# So I can return().
		foreach my $event ( @info ) {
		    $event->{elevation} < $pass_threshold
			and next;
		    not $want_visible
			or $event->{illumination} == PASS_EVENT_LIT
			or next;
		    return 1;
		}
		return 0;
	    } or do {
		@info = ();
		next;
	    };

	    # Put the events created thus far into order.

	    @info = sort { $a->{time} <=> $b->{time} } @info;

	    # Compute the brightest moment if desired.

	    if ( $pass_variant & PASS_VARIANT_BRIGHTEST ) {

		@info = sort { $a->{time} <=> $b->{time} } @info,
		    _pass_compute_brightest( $tle, $sta, $sun, \@info );
	    }

	    # If we want visible events only

	    if ( $pass_variant & PASS_VARIANT_VISIBLE_EVENTS ) {

		# Filter out anything that does not pass muster

		@info = grep { $_->{illumination} == PASS_EVENT_LIT ||
		    $_->{event} == PASS_EVENT_SHADOWED ||
		    $_->{event} == PASS_EVENT_DAY
		    } @info;

		# If we want to fake a max event if that took place in
		# darkness

		if ( $pass_variant & PASS_VARIANT_FAKE_MAX &&
		    ! grep { $_->{event} == PASS_EVENT_MAX } @info ) {

		    # Given that the max got dropped, the fake max is
		    # either the first or the last point.

		    my ( $dup_inx, $splice_inx ) =
			$info[0]{elevation} > $info[-1]{elevation} ?
			( 0, 1 ) : ( -1, -1 );

		    # Shallow clone, and change the event code to max.

		    my $max = { %{ $info[$dup_inx] } };
		    $max->{event} = PASS_EVENT_MAX;

		    # Insert the max either just after the first, or
		    # just before the last event, as the case may be.

		    splice @info, $splice_inx, 0, $max;

		}
	    }

	    # If we want the first and last events to be 'start' and
	    # 'end', willy-nilly, hammer these codes into them.

	    if ( $pass_variant & PASS_VARIANT_START_END ) {
		$info[0]{event} = PASS_EVENT_START;
		$info[-1]{event} = PASS_EVENT_END;
	    }

	    # If PASS_VARIANT_TRUNCATE is in effect, the first and last
	    # events should be 'start' and 'end' IF AND ONLY IF the
	    # satellite is above the horizon at that point AND the time
	    # is at the start or end of the interval. Because the first
	    # event is AFTER its exact time, we need to back up a bit
	    # and recalculate.

	    if ( $truncate ) {
		my $prior = $info[0]{time} - 1;
		if ( $prior <= $pass_start ) {
		    my $elevation = ( $sta->azel(
			    $tle->universal( $prior ) ) )[1];
		    $elevation > $effective_horizon
			and $info[0]{event} = PASS_EVENT_START;
		}
		$info[-1]{elevation} > $effective_horizon
		    and $info[-1]{time} >= $pass_end
		    and $info[-1]{event} = PASS_EVENT_END;
	    }

	    # Pick up the first and last event times, to use to bracket
	    # future calculations.

	    my $first_time = $info[0]{time};
	    my $last_time = $info[-1]{time};
	    my $number_of_events = @info;

	    # Compute nearest approach to background bodies

	    # Note (fortuitous discovery) the ISS travels 1.175
	    # degrees per second at the zenith, so I need better
	    # than 1 second resolution to detect a transit.

	    foreach my $body (@sky) {
		my $when = find_first_true(
		    _pass_bracket_appulse( $sta, $tle, $body,
			$first_time, $last_time ),
		    sub {$sta->angle ($body->universal ($_[0]),
				    $tle->universal ($_[0])) <
			    $sta->angle ($body->universal ($_[0] + .1),
				    $tle->universal ($_[0] + .1))},
		    .1);
		my $angle = 
		    $sta->angle ($body->universal ($when),
			    $tle->universal ($when));
		next if $angle > $appulse_dist;
		my ( $azimuth, $elevation, $range ) = $sta->azel( $tle );
		push @info, {
		    body	=> $tle,
		    event	=> PASS_EVENT_APPULSE,
		    station	=> $sta,
		    time	=> $when,
		    azimuth	=> $azimuth,
		    elevation	=> $elevation,
		    range	=> $range,
		    appulse	=> {
			angle	=> $angle,
			body	=> $body,
		    },
		    _find_illumination( $sun, $when, \@info ),
		};

		warn <<"EOD" if $debug;	## no critic (RequireCarping)
	    $time[$#time][1] @{[strftime '%d-%b-%Y %H:%M:%S',
		localtime $time[$#time][0]]}
EOD
	    }

	    # Add in the intrinsic events if there are any.
	    foreach my $evt (
		$tle->intrinsic_events( $first_time, $last_time )
	    ) {
		my ( $when, $event ) = @{ $evt };
		push @info, {
		    body	=> $tle,
		    event	=> $event,
		    station	=> $sta,
		    time	=> $when,
		    _find_illumination( $sun, $when, \@info ),
		    $tle->_find_position( $sta, $when ),
		};
	    }

	    # If we're verbose, calculate the points.

	    if ( $verbose ) {

		my %events = map { $_->{time} => 1 } @info;
		for ( my $it = ceil( $first_time ); $it < $last_time;
		    $it += $verbose ) {

		    # If we already have an event for this time, skip.

		    $events{$it} and next;

		    # The next line of code relies on the fact that the
		    # events from rise through max and set are already
		    # in chronological order. Yes, in theory we step off
		    # the end of that part of @info, but in practice we
		    # exit the for loop before we get to that point.

		    push @info, {
			body => $tle,
			event => PASS_EVENT_NONE,
			station => $sta,
			time => $it,
			_find_illumination( $sun, $it, \@info ),
			$tle->_find_position( $sta, $it ),
		    };
		}
	    }

	    # Sort the data again if we have added events.

	    @info > $number_of_events
		and @info = sort { $a->{time} <=> $b->{time} } @info;

#	    Record the data for the pass.

	    confess <<eod unless defined $culmination;
Programming error - \$culmination undefined at end of pass calculation.
eod
	    push @passes, {
		body => $tle,
		events => [@info],
		time => $culmination,
	    };

#	    Clear out the data.

	    @info = ();
	    $visible = 0;
	    $culmination = undef;
	    next;
	}

	{	# Localize

	    # Calculate whether the body is visible.

	    my @illumination;
	    if ( $sun ) {
		my $litup = $time < $sun_screen ? 2 - $dawn : 1 + $dawn;
		my $sun_elev_from_sat = $tle->__sun_elev_from_sat( $time );
		$visible ||= $elev > $screening_horizon && (
		    ! $want_visible ||
		    $litup == 1 && $sun_elev_from_sat >= $min_sun_elev_from_sat
		);
		$litup = $time < $suntim ? 2 - $dawn : 1 + $dawn;
		$litup == 1
		    and $sun_elev_from_sat < 0
		    and $litup = 0;
		push @illumination, illumination => $lighting[$litup];
	    } else {
		$visible = $elev > $screening_horizon;
	    }

	    # Accumulate results.

	    push @info, {
		azimuth => $azm,
		elevation => $elev,
		event => PASS_EVENT_NONE,
		range => $rng,
		time => $time,
		@illumination,
	    };

	}

    }
    return @passes;

}

# The problem the following attempts to deal with is that if two
# satellites with similar orbits rise about the same time, they may
# appear to approach, diverge, and approach again. The last apparent
# approach is because they are receding from the observer faster than
# from each other.
#
# What the following code attempts to do is to provide reasonable
# brackets around the time of closest approach. If the body is a TLE
# object, we step across the pass in 30-second intervals, and return the
# interval 30 seconds before and after the closest position found.
# Otherwise we just return the beginning and end of the pass.
#
# Originally there was an attempt to determine if the orbits were
# "sufficiently close", and only step across if that was the case. But
# it proved impracticable to define "sufficiently close", and it was
# determined by benchmarking that the preliminary stepping had only a
# minimal effect on the algorithm's execution time. So we step any time
# we are computing an appulse of an artificial satellite to another
# artificial satellite.

{

    # The following manifest constant is to be used only here. Pretend
    # it is localized.

    use constant APPULSE_CHECK_STEP	=> 30;	# seconds

    sub _pass_bracket_appulse {
	my ( $sta, $tle, $body, $first_time, $last_time ) = @_;

	# The problem we're trying to avoid does not occur unless the
	# body is a TLE.
	embodies( $body, 'Astro::Coord::ECI::TLE' )
	    or return ( $first_time, $last_time );

	# OK, we think we have a problem. Step across the entire pass in
	# 30-second intervals and find the one where the two bodies
	# approach most closely.
	my ( $smallest, $mark );
	for ( my $time = $first_time; $time <= $last_time;
	    $time += APPULSE_CHECK_STEP
	) {
	    my $angle = $sta->angle(
		$body->universal( $time ),
		$tle->universal( $time ),
	    );
	    defined $smallest
		and $angle > $smallest
		or ( $smallest, $mark ) = ( $angle, $time );
	}

	# We return an interval around this closest point as the
	# interval in which to apply the binary search algorithm.
	return (
	    max( $mark - APPULSE_CHECK_STEP, $first_time ),
	    min( $mark + APPULSE_CHECK_STEP, $last_time ),
	);
    }
}

# Compute the position of the satellite at its brightest. We expect to
# be called only if the computation makes sense -- that is, if the
# intrinsic_magnitude attribute is set and we are calculating
# visibility. We will return an event hash, or nothing if there are no
# illuminated points. We will return nothing with a warning if there is
# exactly one illuminated point, since we can't conveniently make the
# calculation from this and it should not happen anyway.
#
# The arguments are:
# $tle - The orbiting body
# $sta - The observing body
# $sun - The illuminating body (assumed defined)
# $info - A reference to the array of events computed thus far, in order
#         by time.
#
# The $info array is assumed to already have visibility and visibility
# events calculated.
sub _pass_compute_brightest {
    my ( $tle, $sta, $sun, $info ) = @_;
    my @wrk = @{ $info };

    # We skip over all the un-illuminated events at the start.
    while ( $wrk[0]{illumination} == PASS_EVENT_SHADOWED ) {
	shift @wrk;
	@wrk
	    or return;
    }
    my $earliest = $wrk[0]{time};

    # We want the time of the first shadowed event, since we're
    # illuminated up to that point.
    my $latest = $wrk[-1]{time};
    while ( $wrk[-1]{illumination} == PASS_EVENT_SHADOWED ) {
	$latest = $wrk[-1]{time};
	pop @wrk;
	@wrk
	    or return;
    }

    # We back off a second from the time of the shadow (or set) event,
    # to get a time when we are illuminated and above the horizon.
    $latest -= 1;
    @wrk > 1
	or do {
	# carp 'No magnitude calculation done: only one illuminated position';
	return;
    };

    # Because the behavior is non-linear, we step through the time at
    # 30-second intervals, then at 1-second intervals to find the
    # brightest.
    my $twilight = $tle->get( 'twilight' );
    foreach my $delta ( 30, 1 ) {
	@wrk = ();
	for ( my $time = $earliest; $time <= $latest; $time += $delta ) {
	    push @wrk, [
		$time,
		$tle->universal( $time )->magnitude( $sta ),
	    ];
	}
	# Because our time span is probably not a multiple of our step
	# size, we slap the last time onto the end.
	$wrk[-1][0] < $latest
	    and push @wrk, [
	    $latest,
	    $tle->universal( $latest )->magnitude( $sta ),
	];

	# The next interval becomes the brightest and second-brightest
	# time found.
	@wrk = sort { $a->[1] <=> $b->[1] } grep { defined $_->[1] } @wrk;
	( $earliest, $latest ) = sort { $a <=> $b }
	    map { $wrk[$_][0] } 0, 1;
    }

    # Make up and return the event.
    my $time = $wrk[0][0];
    my ( $azm, $elev, $rng ) =
	$sta->azel( $tle->universal( $time ) );
    my ( undef, $sun_elev ) = $sta->azel( $sun->universal(
	    $time ) );
    my $illum = $sun_elev < $twilight ?
	PASS_EVENT_LIT :
	PASS_EVENT_DAY;
    return {
	azimuth		=> $azm,
	body		=> $tle,
	elevation	=> $elev,
	event		=> PASS_EVENT_BRIGHTEST,
	illumination	=> $illum,
	magnitude	=> $wrk[0][1],
	range		=> $rng,
	station		=> $sta,
	time		=> $time,
    };
}

=item $kilometers = $tle->periapsis();

This method returns the periapsis of the orbit, in kilometers. Since
Astro::Coord::ECI::TLE objects always represent bodies orbiting the
Earth, this is more usually called perigee.

Note that this is the distance from the center of the Earth, not the
altitude.

=cut

sub periapsis {
    my $self = shift;
    return $self->{&TLE_INIT}{TLE_periapsis} ||=
	(1 - $self->get('eccentricity')) * $self->semimajor();
}

=item $kilometers = $tle->perigee();

This method is simply a synonym for periapsis().

=cut

*perigee = \&periapsis;

=item $seconds = $tle->period ($model);

This method returns the orbital period of the object in seconds using
the given model. If the model is unspecified (or specified as a false
value), the current setting of the 'model' attribute is used.

There are actually only two period calculations available. If the model
is 'sgp4r' (or its equivalents 'model' and 'model4r'), the sgp4r
calculation will be used. Otherwise the calculation from the original
Space Track Report Number 3 will be used. 'Otherwise' includes the case
where the model is 'null'.

The difference between using the original and the revised algorithm is
minimal. For the objects in the sgp4-ver.tle file provided with the
'Revisiting Spacetrack Report #3' code, the largest is about 50
nanoseconds for OID 23333, which is in a highly eccentric orbit.

The difference between using the various values of gravconst_r with
sgp4r is somewhat more pronounced. Among the objects in sgp4-ver.tle the
largest difference was about a millisecond, again for OID 23333.

Neither of these differences seems to me significant, but I thought it
would be easier to take the model into account than to explain why I did
not.

A note on subclassing: A body that is not in orbit should return a
period of C<undef>.

=cut

{
    my %model_map = (
	model => \&_period_r,
	model4r => \&_period_r,
	sgp4r => \&_period_r,
    );
    sub period {
	my $self = shift;
	my $code = $model_map{shift || $self->{model}} || \&_period;
	return $code->($self);
    }
}

#	Original period calculation, recast to remove an equivocation on
#	where the period was cached, which caused the cache to be
#	ineffective.

sub _period {
    my $self = shift;
    return $self->{&TLE_INIT}{TLE_period} ||= do {
	my $a1 = (SGP_XKE / $self->{meanmotion}) ** SGP_TOTHRD;
	my $temp = 1.5 * SGP_CK2 * (3 * cos ($self->{inclination}) ** 2 - 1) /
		(1 - $self->{eccentricity} * $self->{eccentricity}) ** 1.5;
	my $del1 = $temp / ($a1 * $a1);
	my $a0 = $a1 * (1 - $del1 * (.5 * SGP_TOTHRD +
		$del1 * (1 + 134/81 * $del1)));
	my $del0 = $temp / ($a0 * $a0);
	my $xnodp = $self->{meanmotion} / (1 + $del0);
	SGP_TWOPI / $xnodp * SGP_XSCPMN;
    };
}

#	Compute period using sgp4r's adjusted mean motion. Yes, I took
#	the coward's way out and initialized the model, but we use this
#	only if the model is sgp4r (implying that it will be initialized
#	anyway) or if the user explicitly asked for it.

sub _period_r {
    my ($self) = @_;
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r} ||= $self->_r_sgp4init ();
    return &SGP_TWOPI/$parm->{meanmotion} * 60;
}

=item $tle = $tle->rebless ($class, \%possible_attributes)

This method reblesses a TLE object. The class must be either
L<Astro::Coord::ECI|Astro::Coord::ECI> or a subclass thereof, as must
the object passed in to be reblessed. If the $tle object has its
C<reblessable> attribute false, it will not be reblessed,
but will be returned unmodified. Before reblessing, the
before_reblessing() method is called.  After reblessing, the
after_reblessing() method is called with the \%possible_attributes hash
reference as argument.

It is possible to omit the $class argument if the \%possible_attributes
argument contains the keys {class} or {type}, taken in that order. If
the $class argument is omitted and the \%possible_attributes hash does
B<not> have the requisite keys, the $tle object is unmodified.

It is also possible to omit both arguments, in which case the object
will be reblessed according to the content of the internal status
table.

For convenience, you can pass an alias instead of the full class name. The
following aliases are recognized:

 tle => 'Astro::Coord::ECI::TLE'

If you install
L<Astro::Coord::ECI::TLE::Iridium|Astro::Coord::ECI::TLE::Iridium> it
will define alias

 iridium => 'Astro::Coord::ECI::TLE::Iridium'

Other aliases may be defined with the alias() static method.

Note that this method returns the original object (possibly reblessed).
It does not under any circumstances manufacture another object.

=cut

sub rebless {
    my ($tle, @args) = @_;
    __instance( $tle, __PACKAGE__ ) or croak <<eod;
Error - You can only rebless an object of class @{[__PACKAGE__]}
        or a subclass thereof. The object you are trying to rebless
	is of class @{[ref $tle]}.
eod
    $tle->get ('reblessable') or return $tle;
    @args or do {
	my $id = $tle->get ('id') or return $tle;
	$id =~ m/ [^0-9] /smx
	    or $id = sprintf '%05d', $id;
	@args = $status{$id} || 'tle';
    };
    my $class = HASH_REF eq ref $args[0] ?
	($args[0]->{class} || $args[0]->{type}) : shift @args
	or return $tle;
    $class = $type_map{$class} if $type_map{$class};
    load_module ($class);
    __classisa( $class, __PACKAGE__ ) or croak <<eod;
Error - You can only rebless an object into @{[__PACKAGE__]} or
        a subclass thereof. You are trying to rebless the object
	into $class.
eod
    $tle->before_reblessing ();
    bless $tle, $class;
    $tle->after_reblessing (@args);
    return $tle;
}

=item $kilometers = $tle->semimajor();

This method calculates the semimajor axis of the orbit, using Kepler's
Third Law (Isaac Newton's version) in the form

 T ** 2 / a ** 3 = 4 * pi ** 2 / mu

where

 T is the orbital period,
 a is the semimajor axis of the orbit,
 pi is the circle ratio (3.14159 ...), and
 mu is the Earth's gravitational constant,
    3.986005e5 km ** 3 / sec ** 2

The calculation is carried out using the period implied by the current
model.

=cut

{
    my $mu = 3.986005e5;	# km ** 3 / sec ** 2 -- for Earth.
    sub semimajor {
	my $self = shift;
	return $self->{&TLE_INIT}{TLE_semimajor} ||= do {
	    my $to2pi = $self->period / SGP_TWOPI;
	    exp (log ($to2pi * $to2pi * $mu) / 3);
	};
    }
}

=item $kilometers = $tle->semiminor();

This method calculates the semiminor axis of the orbit, using the
semimajor axis and the eccentricity, by the equation

 b = a * sqrt(1 - e)

where a is the semimajor axis and e is the eccentricity.

=cut

sub semiminor {
    my $self = shift;
    return $self->{&TLE_INIT}{TLE_semiminor} ||= do {
	my $e = $self->get('eccentricity');
	$self->semimajor() * sqrt(1 - $e * $e);
    };
}

=item $tle->set (attribute => value ...)

This method sets the values of the various attributes. The changing of
attributes actually used by the orbital models will cause the models to
be reinitialized. This happens transparently, and is no big deal. For
a description of the attributes, see L</Attributes>.

Because this is a subclass of L<Astro::Coord::ECI|Astro::Coord::ECI>,
any attributes of that class can also be set.

=cut

sub set {
    my ($self, @args) = @_;
    @args % 2 and croak "The set method takes an even number of arguments.";
    my ($clear, $extant);
    if (ref $self) {
	$extant = \%attrib;
    } else {
	$self = $extant = \%static;
    }
    while (@args) {
	my $name = shift @args;
	my $val = shift @args;
	exists $extant->{$name} or do {
	    $self->SUPER::set ($name, $val);
	    next;
	};
	defined $attrib{$name} or croak "Attribute $name is read-only.";
	if ( CODE_REF eq ref $attrib{$name} ) {
	    $attrib{$name}->($self, $name, $val) and $clear = 1;
	} else {
	    $self->{$name} = $val;
	    $clear ||= $attrib{$name};
	}
    }
    $clear and delete $self->{&TLE_INIT};
    return $self;
}

=item Astro::Coord::ECI::TLE->status (command => arguments ...)

This method maintains the internal status table, which is used by the
parse() method to determine which subclass (if any) to bless the
created object into. The first argument determines what is done to the
status table; subsequent arguments depend on the first argument. Valid
commands and arguments are:

status (add => $id, $type => $status, $name, $comment) adds an item to
the status table or modifies an existing item. The $id is the NORAD ID
of the body.

No types are supported out of the box, but if you have installed
L<Astro::Coord::ECI::TLE::Iridium|Astro::Coord::ECI::TLE::Iridium> that
or C<'iridium'> will work.

The $status is 0, 1, 2, or 3 representing in-service, spare, failed, or
decayed respectively.  The strings '+' or '' will be interpreted as 0,
'S', 's', or '?' as 1, 'D' as 3, and any other non-numeric string as 2.
The  $name and $comment arguments default to empty.

status ('clear') clears the status table.

status (clear => 'type') clears all entries of the given type in the
status table. For supported types, see the discussion of 'add',
above.

status (drop => $id) removes the given NORAD ID from the status table.

status ('show') returns a list of list references, representing the
'add' commands which would be used to regenerate the status table.

Initially, the status table is populated with the status as of December
3, 2010.

=cut

sub status {
    my ( undef, $cmd, @arg ) = @_;	# Invocant unused
    if ($cmd eq 'add') {
	my ( $id, $type, $status, $name, $comment ) = @arg;
	$id or croak <<eod;
Error - The status ('add') call requires a NORAD ID.
eod
	$id =~ m/ [^0-9] /smx
	    or $id = sprintf '%05d', $id;
	$type or croak <<eod;
Error - The status (add => $id) call requires a type.
eod
	my $class = $type_map{$type} || $type;
	__classisa( $class, __PACKAGE__ ) or croak <<eod;
Error - $type must specify a subclass of @{[__PACKAGE__]}.
eod
	$status ||= 0;
	if ( my $code = $class->can( '__decode_operational_status' ) ) {
	    $status = $code->( $status );
	}
	$name ||= '';
	$comment ||='';
	$status{$id} = {
	    comment => $comment,
	    status => $status,
	    name => $name,
	    id => $id,
	    type => $type,
	    class => $class,
	};
    } elsif ($cmd eq 'clear') {
	my ( $type ) = @arg;
	if (!defined $type) {
	    %status = ();
	} else {
	    my $class = $type_map{$type} || $type;
	    __classisa( $class, __PACKAGE__ ) or croak <<eod;
Error - $type must specify a subclass of @{[__PACKAGE__]}.
eod
	    foreach my $key (keys %status) {
		$status{$key}{class} eq $class and delete $status{$key};
	    }
	}
    } elsif ($cmd eq 'drop') {
	my $id = $arg[0] or croak <<eod;
Error - The status ('drop') call requires a NORAD ID.
eod
	delete $status{$id};
    } elsif ($cmd eq 'dump') {	# <<<< Undocumented!!!
	# This functionality is UNDOCUMENTED and UNSUPPORTED. It exists
	# for the convenience of the author, who reserves the right to
	# change or revoke it without notice.
	# If called in void context, prints a Data::Dumper dump of the
	# status information; otherwise returns the dump.
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Sortkeys = 1;
	my $data = @arg ?
	    +{ map { $_ => $status{$_} } grep { $status{$_} } @arg } :
	    \%status;
	defined wantarray
	    and return __PACKAGE__ . ' status = ', Dumper( $data );
	print __PACKAGE__, " status = ", Dumper ( $data );
    } elsif ($cmd eq 'show') {
	return (
	    sort { $a->[0] <=> $b->[0] }
	    map { [ $_->{id}, $_->{type}, $_->{status}, $_->{name},
		$_->{comment} ] }
	    map { defined $status{$_} ? $status{$_} : () }
	    @arg ? @arg : keys %status
	);
    } elsif ($cmd eq 'yaml') {	# <<<< Undocumented!!!
	# This functionality is UNDOCUMENTED and UNSUPPORTED. It exists
	# for the convenience of the author, who reserves the right to
	# change or revoke it without notice.
	# If called in void context, prints a YAML dump of the status
	# information; otherwise returns the YAML dump.
	load_module( 'YAML' )
	    or croak 'YAML not available';
	my $data = @arg ?
	    +{ map { $_ => $status{$_} } grep { $status{$_} } @arg } :
	    \%status;
	defined wantarray
	    and return YAML::Dump( $data );
	print YAML::Dump( $data );
    } else {
	croak <<eod;
Error - '$cmd' is not a legal status() command.
eod
    }
    return;
}

=item $tle = $tle->sgp($time)

This method calculates the position of the body described by the TLE
object at the given time, using the SGP model. The universal time of the
object is set to $time, and the 'equinox_dynamical' attribute is set to
to the current value of the 'epoch_dynamical' attribute.

The result is the original object reference. You need to call one of
the Astro::Coord::ECI methods (e.g. geodetic () or equatorial ()) to
retrieve the position you just calculated.

"Spacetrack Report Number 3" (see "Acknowledgments") says that this
model can be used for either near-earth or deep-space orbits, but the
reference implementation they provide dies on an attempt to use this
model for a deep-space object, and I have followed the reference
implementation.

=cut

sub sgp {
    my ($self, $time) = @_;
    my $oid = $self->get('id');
    $self->{model_error} = undef;
    my $tsince = ($time - $self->{epoch}) / 60;	# Calc. is in minutes.

#*	Initialization.

#>>>	Rather than use a separate indicator argument to trigger
#>>>	initialization of the model, we use the Orcish maneuver to
#>>>	retrieve the results of initialization, performing the
#>>>	calculations if needed. -- TRW

    my $parm = $self->{&TLE_INIT}{TLE_sgp} ||= do {
	$self->is_deep and croak <<EOD;
Error - The SGP model is not valid for deep space objects.
        Use the SDP4, SDP4R, or SDP8 models instead.
EOD
	my $c1 = SGP_CK2 * 1.5;
	my $c2 = SGP_CK2 / 4;
	my $c3 = SGP_CK2 / 2;
	my $c4 = SGP_XJ3 * SGP_AE ** 3 / (4 * SGP_CK2);
	my $cosi0 = cos ($self->{inclination});
	my $sini0 = sin ($self->{inclination});
	my $a1 = (SGP_XKE / $self->{meanmotion}) ** SGP_TOTHRD;
	my $d1 = $c1 / $a1 / $a1 * (3 * $cosi0 * $cosi0 - 1) /
	    (1 - $self->{eccentricity} * $self->{eccentricity}) ** 1.5;
	my $a0 = $a1 *
	    (1 - 1/3 * $d1 - $d1 * $d1 - 134/81 * $d1 * $d1 * $d1); 
	my $p0 = $a0 * (1 - $self->{eccentricity} * $self->{eccentricity});
	my $q0 = $a0 * (1 - $self->{eccentricity});
	my $xlo = $self->{meananomaly} + $self->{argumentofperigee} +
	    $self->{ascendingnode};
	my $d10 = $c3 * $sini0 * $sini0;
	my $d20 = $c2 * (7 * $cosi0 * $cosi0 - 1);
	my $d30 = $c1 * $cosi0;
	my $d40 = $d30 * $sini0;
	my $po2no = $self->{meanmotion} / ($p0 * $p0);
	my $omgdt = $c1 * $po2no * (5 * $cosi0 * $cosi0 - 1);
	my $xnodot = -2 * $d30 * $po2no;
	my $c5 = .5 * $c4 * $sini0 * (3 + 5 * $cosi0) / (1 + $cosi0);
	my $c6 = $c4 * $sini0;
	$self->{debug} and warn <<eod;	## no critic (RequireCarping)
Debug sgp initialization -
        A0 = $a0
        C5 = $c5
        C6 = $c6
        D10 = $d10
        D20 = $d20
        D30 = $d30
        D40 = $d40
        OMGDT = $omgdt
        Q0 = $q0
        XLO = $xlo
        XNODOT = $xnodot
eod
	{
	    a0 => $a0,
	    c5 => $c5,
	    c6 => $c6,
	    d10 => $d10,
	    d20 => $d20,
	    d30 => $d30,
	    d40 => $d40,
	    omgdt => $omgdt,
	    q0 => $q0,
	    xlo => $xlo,
	    xnodot => $xnodot,
	};
    };

#*	Update for secular gravity and atmospheric drag.

    my $a = $self->{meanmotion} +
	    (2 * $self->{firstderivative} +
	    3 * $self->{secondderivative} * $tsince) * $tsince;
    # $a is only magic inside certain constructions, but Perl::Critic
    # either does not know this, or does not realize that it is a
    # lexical variable here.
    $a =	## no critic (RequireLocalizedPunctuationVars)
	$parm->{a0} * ($self->{meanmotion} / $a) ** SGP_TOTHRD;
    my $e = $a > $parm->{q0} ? 1 - $parm->{q0} / $a : SGP_E6A;
    my $p = $a * (1 - $e * $e);
    my $xnodes = $self->{ascendingnode} + $parm->{xnodot} * $tsince;
    my $omgas = $self->{argumentofperigee} + $parm->{omgdt} * $tsince;
    my $xls = mod2pi ($parm->{xlo} + ($self->{meanmotion} + $parm->{omgdt} +
	    $parm->{xnodot} + ($self->{firstderivative} +
	    $self->{secondderivative} * $tsince) * $tsince) * $tsince);
    $self->{debug} and warn <<eod;	## no critic (RequireCarping)
Debug sgp - atmospheric drag and gravity
        TSINCE = $tsince
        A = $a
        E = $e
        P = $p
        XNODES = $xnodes
        OMGAS = $omgas
        XLS = $xls
eod

#*	Long period periodics.

    my $axnsl = $e * cos ($omgas);
    my $aynsl = $e * sin ($omgas) - $parm->{c6} / $p;
    my $xl = mod2pi ($xls - $parm->{c5} / $p * $axnsl);
    $self->{debug} and warn <<eod;	## no critic (RequireCarping)
Debug sgp - long period periodics
        AXNSL = $axnsl
        AYNSL = $aynsl
        XL = $xl
eod

#*	Solve Kepler's equation.

    my $u = mod2pi ($xl - $xnodes);
    my ($item3, $eo1, $tem5) = (0, $u, 1);
    my ($sineo1, $coseo1);
    while (1) {
	$sineo1 = sin ($eo1);
	$coseo1 = cos ($eo1);
	last if abs ($tem5) < SGP_E6A || $item3++ >= 10;
	$tem5 = 1 - $coseo1 * $axnsl - $sineo1 * $aynsl;
	$tem5 = ($u - $aynsl * $coseo1 + $axnsl * $sineo1 - $eo1) / $tem5;
	my $tem2 = abs ($tem5);
	$tem2 > 1 and $tem5 = $tem2 / $tem5;
	$eo1 += $tem5;
    }
    $self->{debug} and warn <<eod;	## no critic (RequireCarping)
Debug sgp - solve equation of Kepler
        U = $u
        EO1 = $eo1
        SINEO1 = $sineo1
        COSEO1 = $coseo1
eod

#*	Short period preliminary quantities.

    my $ecose = $axnsl * $coseo1 + $aynsl * $sineo1;
    my $esine = $axnsl * $sineo1 - $aynsl * $coseo1;
    my $el2 = $axnsl * $axnsl + $aynsl * $aynsl;
    $self->{debug}
	and warn "Debug - OID $oid sgp effective eccentricity $el2\n";
    $el2 > 1 and croak "Error - OID $oid Sgp effective eccentricity > 1";
    my $pl = $a * (1 - $el2);
    my $pl2 = $pl * $pl;
    my $r = $a * (1 - $ecose);
    my $rdot = SGP_XKE * sqrt ($a) / $r * $esine;
    my $rvdot = SGP_XKE * sqrt ($pl) / $r;
    my $temp = $esine / (1 + sqrt (1 - $el2));
    my $sinu = $a / $r * ($sineo1 - $aynsl - $axnsl * $temp);
    my $cosu = $a / $r * ($coseo1 - $axnsl + $aynsl * $temp);
    my $su = _actan ($sinu, $cosu);
    $self->{debug} and warn <<eod;	## no critic (RequireCarping)
Debug sgp - short period preliminary quantities
        PL2 = $pl2
        R = $r
        RDOT = $rdot
        RVDOT = $rvdot
        SINU = $sinu
        COSU = $cosu
        SU = $su
eod

#*	Update for short periodics.

    my $sin2u = ($cosu + $cosu) * $sinu;
    my $cos2u = 1 - 2 * $sinu * $sinu;
    my $rk = $r + $parm->{d10} / $pl * $cos2u;
    my $uk = $su - $parm->{d20} / $pl2 * $sin2u;
    my $xnodek = $xnodes + $parm->{d30} * $sin2u / $pl2;
    my $xinck = $self->{inclination} + $parm->{d40} / $pl2 * $cos2u;

#* 	Orientation vectors.

    my $sinuk = sin ($uk);
    my $cosuk = cos ($uk);
    my $sinnok = sin ($xnodek);
    my $cosnok = cos ($xnodek);
    my $sinik = sin ($xinck);
    my $cosik = cos ($xinck);
    my $xmx = - $sinnok * $cosik;
    my $xmy = $cosnok * $cosik;
    my $ux = $xmx * $sinuk + $cosnok * $cosuk;
    my $uy = $xmy * $sinuk + $sinnok * $cosuk;
    my $uz = $sinik * $sinuk;
    my $vx = $xmx * $cosuk - $cosnok * $sinuk;
    my $vy = $xmy * $cosuk - $sinnok * $sinuk;
    my $vz = $sinik * $cosuk;

#*	Position and velocity.

    my $x = $rk * $ux;
    my $y = $rk * $uy;
    my $z = $rk * $uz;
    my $xdot = $rdot * $ux;
    my $ydot = $rdot * $uy;
    my $zdot = $rdot * $uz;
    $xdot = $rvdot * $vx + $xdot;
    $ydot = $rvdot * $vy + $ydot;
    $zdot = $rvdot * $vz + $zdot;

    return _convert_out($self, $x, $y, $z, $xdot, $ydot, $zdot, $time);
}

=item $tle = $tle->sgp4($time)

This method calculates the position of the body described by the TLE
object at the given time, using the SGP4 model. The universal time of
the object is set to $time, and the 'equinox_dynamical' attribute is set
to the current value of the 'epoch_dynamical' attribute.

The result is the original object reference. See the L</DESCRIPTION>
heading above for how to retrieve the coordinates you just calculated.

"Spacetrack Report Number 3" (see "Acknowledgments") says that this
model can be used only for near-earth orbits.

=cut

sub sgp4 {
    my ($self, $time) = @_;
    my $oid = $self->get('id');
    $self->{model_error} = undef;
    my $tsince = ($time - $self->{epoch}) / 60;	# Calc. is in minutes.

#>>>	Rather than use a separate indicator argument to trigger
#>>>	initialization of the model, we use the Orcish maneuver to
#>>>	retrieve the results of initialization, performing the
#>>>	calculations if needed. -- TRW

    my $parm = $self->{&TLE_INIT}{TLE_sgp4} ||= do {
	$self->is_deep and croak <<EOD;
Error - The SGP4 model is not valid for deep space objects.
        Use the SDP4, SDP4R or SDP8 models instead.
EOD

#*	Recover original mean motion (XNODP) and semimajor axis (AODP)
#*	from input elements.

	my $a1 = (SGP_XKE / $self->{meanmotion}) ** SGP_TOTHRD;
	my $cosi0 = cos ($self->{inclination});
	my $theta2 = $cosi0 * $cosi0;
	my $x3thm1 = 3 * $theta2 - 1;
	my $eosq = $self->{eccentricity} * $self->{eccentricity};
	my $beta02 = 1 - $eosq;
	my $beta0 = sqrt ($beta02);
	my $del1 = 1.5 * SGP_CK2 * $x3thm1 / ($a1 * $a1 * $beta0 * $beta02);
	my $a0 = $a1 * (1 - $del1 * (.5 * SGP_TOTHRD + $del1 * (1 + 134
		    / 81 * $del1)));
	my $del0 = 1.5 * SGP_CK2 * $x3thm1 / ($a0 * $a0 * $beta0 * $beta02);
	my $xnodp = $self->{meanmotion} / (1 + $del0);
	my $aodp = $a0 / (1 - $del0);

#*	Initialization

#*	For perigee less than 220 kilometers, the ISIMP flag is set and
#*	the equations are truncated to linear variation in sqrt(A) and
#*	quadratic variation in mean anomaly. Also, the C3 term, the
#*	delta omega term, and the delta M term are dropped.

#>>>	Note that the original code sets ISIMP to 1 or 0, but we just
#>>>	set $isimp to true or false. - TRW

	my $isimp = ($aodp * (1 - $self->{eccentricity}) / SGP_AE) <
	    (220 / SGP_XKMPER + SGP_AE);

#*	For perigee below 156 KM, the values of
#*	S and QOMS2T are altered.

	my $s4 = SGP_S;
	my $qoms24 = SGP_QOMS2T;
	my $perige = ($aodp * (1 - $self->{eccentricity}) - SGP_AE) *
	    SGP_XKMPER;
	unless ($perige >= 156) {
	    $s4 = $perige > 98 ? $perige - 78 : 20;
	    $qoms24 = ((120 - $s4) * SGP_AE / SGP_XKMPER) ** 4;
	    $s4 = $s4 / SGP_XKMPER + SGP_AE;
	}
	my $pinvsq = 1 / ($aodp * $aodp * $beta02 * $beta02);
	my $tsi = 1 / ($aodp - $s4);
	my $eta = $aodp * $self->{eccentricity} * $tsi;
	my $etasq = $eta * $eta;
	my $eeta = $self->{eccentricity} * $eta;
	my $psisq = abs (1 - $etasq);
	my $coef = $qoms24 * $tsi ** 4;
	my $coef1 = $coef / $psisq ** 3.5;
	my $c2 = $coef1 * $xnodp * ($aodp * (1 + 1.5 * $etasq + $eeta *
		(4 + $etasq)) + .75 * SGP_CK2 * $tsi / $psisq * $x3thm1
	    * (8 + 3 * $etasq * (8 + $etasq)));
	my $c1 = $self->{bstardrag} * $c2;
	my $sini0 = sin ($self->{inclination});
	my $a3ovk2 = - SGP_XJ3 / SGP_CK2 * SGP_AE ** 3;
	my $c3 = $coef * $tsi * $a3ovk2 * $xnodp * SGP_AE * $sini0 /
	    $self->{eccentricity};
	my $x1mth2 = 1 - $theta2;
	my $c4 = 2 * $xnodp * $coef1 * $aodp * $beta02 * ($eta * (2 + .5
		* $etasq) + $self->{eccentricity} * (.5 + 2 * $etasq) -
	    2 * SGP_CK2 * $tsi / ($aodp * $psisq) * (-3 * $x3thm1 * (1 -
		    2 * $eeta + $etasq * (1.5 - .5 * $eeta)) + .75 *
		$x1mth2 * (2 * $etasq - $eeta * (1 + $etasq)) * cos (2 *
		    $self->{argumentofperigee})));
	my $c5 = 2 * $coef1 * $aodp * $beta02 * (1 + 2.75 * ($etasq +
		$eeta) + $eeta * $etasq);
	my $theta4 = $theta2 * $theta2;
	my $temp1 = 3 * SGP_CK2 * $pinvsq * $xnodp;
	my $temp2 = $temp1 * SGP_CK2 * $pinvsq;
	my $temp3 = 1.25 * SGP_CK4 * $pinvsq * $pinvsq * $xnodp;
	my $xmdot = $xnodp + .5 * $temp1 * $beta0 * $x3thm1 + .0625 *
	    $temp2 * $beta0 * (13 - 78 * $theta2 + 137 * $theta4);
	my $x1m5th = 1 - 5 * $theta2;
	my $omgdot = -.5 * $temp1 * $x1m5th + .0625 * $temp2 * (7 - 114
	    * $theta2 + 395 * $theta4) + $temp3 * (3 - 36 * $theta2 + 49
	    * $theta4);
	my $xhdot1 = - $temp1 * $cosi0;
	my $xnodot = $xhdot1 + (.5 * $temp2 * (4 - 19 * $theta2) + 2 *
	    $temp3 * (3 - 7 * $theta2)) * $cosi0;
	my $omgcof = $self->{bstardrag} * $c3 * cos
	    ($self->{argumentofperigee});
	my $xmcof = - SGP_TOTHRD * $coef * $self->{bstardrag} * SGP_AE / $eeta;
	my $xnodcf = 3.5 * $beta02 * $xhdot1 * $c1;
	my $t2cof = 1.5 * $c1;
	my $xlcof = .125 * $a3ovk2 * $sini0 * (3 + 5 * $cosi0) / (1 + $cosi0);
	my $aycof = .25 * $a3ovk2 * $sini0;
	my $delmo = (1 + $eta * cos ($self->{meananomaly})) ** 3;
	my $sinmo = sin ($self->{meananomaly});
	my $x7thm1 = 7 * $theta2 - 1;
	my ($d2, $d3, $d4, $t3cof, $t4cof, $t5cof);
	$isimp or do {
	    my $c1sq = $c1 * $c1;
	    $d2 = 4 * $aodp * $tsi * $c1sq;
	    my $temp = $d2 * $tsi * $c1 / 3;
	    $d3 = (17 * $aodp + $s4) * $temp;
	    $d4 = .5 * $temp * $aodp * $tsi * (221 * $aodp + 31 * $s4) * $c1;
	    $t3cof = $d2 + 2 * $c1sq;
	    $t4cof = .25 * (3 * $d3 * $c1 * (12 * $d2 + 10 * $c1sq));
	    $t5cof = .2 * (3 * $d4 + 12 * $c1 * $d3 + 6 * $d2 * $d2 + 15
		* $c1sq * ( 2 * $d2 + $c1sq));
	};
	$self->{debug} and print <<eod;
Debug SGP4 - Initialize
    AODP = $aodp
    AYCOF = $aycof
    C1 = $c1
    C4 = $c4
    C5 = $c5
    COSIO = $cosi0
    D2 = @{[defined $d2 ? $d2 : 'undef']}
    D3 = @{[defined $d3 ? $d3 : 'undef']}
    D4 = @{[defined $d4 ? $d4 : 'undef']}
    DELMO = $delmo
    ETA = $eta
    ISIMP = $isimp
    OMGCOF = $omgcof
    OMGDOT = $omgdot
    SINIO = $sini0
    SINMO = $sinmo
    T2COF = @{[defined $t2cof ? $t2cof : 'undef']}
    T3COF = @{[defined $t3cof ? $t3cof : 'undef']}
    T4COF = @{[defined $t4cof ? $t4cof : 'undef']}
    T5COF = @{[defined $t5cof ? $t5cof : 'undef']}
    X1MTH2 = $x1mth2
    X3THM1 = $x3thm1
    X7THM1 = $x7thm1
    XLCOF = $xlcof
    XMCOF = $xmcof
    XMDOT = $xmdot
    XNODCF = $xnodcf
    XNODOT = $xnodot
    XNODP = $xnodp
eod
	{
	    aodp => $aodp,
	    aycof => $aycof,
	    c1 => $c1,
	    c4 => $c4,
	    c5 => $c5,
	    cosi0 => $cosi0,
	    d2 => $d2,
	    d3 => $d3,
	    d4 => $d4,
	    delmo => $delmo,
	    eta => $eta,
	    isimp => $isimp,
	    omgcof => $omgcof,
	    omgdot => $omgdot,
	    sini0 => $sini0,
	    sinmo => $sinmo,
	    t2cof => $t2cof,
	    t3cof => $t3cof,
	    t4cof => $t4cof,
	    t5cof => $t5cof,
	    x1mth2 => $x1mth2,
	    x3thm1 => $x3thm1,
	    x7thm1 => $x7thm1,
	    xlcof => $xlcof,
	    xmcof => $xmcof,
	    xmdot => $xmdot,
	    xnodcf => $xnodcf,
	    xnodot => $xnodot,
	    xnodp => $xnodp,
	};
    };

#*	Update for secular gravity and atmospheric drag.

    my $xmdf = $self->{meananomaly} + $parm->{xmdot} * $tsince;
    my $omgadf = $self->{argumentofperigee} + $parm->{omgdot} * $tsince;
    my $xnoddf = $self->{ascendingnode} + $parm->{xnodot} * $tsince;
    my $omega = $omgadf;
    my $xmp = $xmdf;
    my $tsq = $tsince * $tsince;
    my $xnode = $xnoddf + $parm->{xnodcf} * $tsq;
    my $tempa = 1 - $parm->{c1} * $tsince;
    my $tempe = $self->{bstardrag} * $parm->{c4} * $tsince;
    my $templ = $parm->{t2cof} * $tsq;
    $parm->{isimp} or do {
	my $delomg = $parm->{omgcof} * $tsince;
	my $delm = $parm->{xmcof} * ((1 + $parm->{eta} * cos($xmdf)) **
	    3 - $parm->{delmo});
	my $temp = $delomg + $delm;
	$xmp = $xmdf + $temp;
	$omega = $omgadf - $temp;
	my $tcube = $tsq * $tsince;
	my $tfour = $tsince * $tcube;
	$tempa = $tempa - $parm->{d2} * $tsq - $parm->{d3} * $tcube -
	    $parm->{d4} * $tfour;
	$tempe = $tempe + $self->{bstardrag} * $parm->{c5} * (sin($xmp)
	    - $parm->{sinmo});
	$templ = $templ + $parm->{t3cof} * $tcube + $tfour *
	    ($parm->{t4cof} + $tsince * $parm->{t5cof});
    };
    my $a = $parm->{aodp} * $tempa ** 2;
    my $e = $self->{eccentricity} - $tempe;
    my $xl = $xmp + $omega + $xnode + $parm->{xnodp} * $templ;
    $self->{debug}
	and warn "Debug - OID $oid sgp4 effective eccentricity $e\n";
    croak <<eod if $e > 1 || $e < -1;
Error - OID $oid Sgp4 effective eccentricity > 1
    Epoch = @{[scalar gmtime $self->get ('epoch')]} GMT
    \$self->{bstardrag} = $self->{bstardrag}
    \$parm->{c4} = $parm->{c4}
    \$tsince = $tsince
    \$tempe = \$self->{bstardrag} * \$parm->{c4} * \$tsince
    \$tempe = $tempe
    \$self->{eccentricity} = $self->{eccentricity}
    \$e = \$self->{eccentricity} - \$tempe
    \$e = $e
    Either this object represents a bad set of elements, or you are
    using it beyond its "best by" date ("expiry date" in some dialects
    of English).
eod
    my $beta = sqrt(1 - $e * $e);
    $self->{debug} and print <<eod;
Debug SGP4 - Before xn,
    XKE = @{[SGP_XKE]}
    A = $a
    TEMPA = $tempa
    AODP = $parm->{aodp}
eod
    my $xn = SGP_XKE / $a ** 1.5;

#*	Long period periodics

    my $axn = $e * cos($omega);
    my $temp = 1 / ($a * $beta * $beta);
    my $xll = $temp * $parm->{xlcof} * $axn;
    my $aynl = $temp * $parm->{aycof};
    my $xlt = $xl + $xll;
    my $ayn = $e * sin($omega) + $aynl;

#*	Solve Kepler's equation.

    my $capu = mod2pi($xlt - $xnode);
    my $temp2 = $capu;
    my ($temp3, $temp4, $temp5, $temp6, $sinepw, $cosepw);
    for (my $i = 0; $i < 10; $i++) {
	$sinepw = sin($temp2);
	$cosepw = cos($temp2);
	$temp3 = $axn * $sinepw;
	$temp4 = $ayn * $cosepw;
	$temp5 = $axn * $cosepw;
	$temp6 = $ayn * $sinepw;
	my $epw = ($capu - $temp4 + $temp3 - $temp2) / (1 - $temp5 -
	    $temp6) + $temp2;
	abs ($epw - $temp2) <= SGP_E6A and last;
	$temp2 = $epw;
    }

#*	Short period preliminary quantities.

    my $ecose = $temp5 + $temp6;
    my $esine = $temp3 - $temp4;
    my $elsq = $axn * $axn + $ayn * $ayn;
    $temp = 1 - $elsq;
    my $pl = $a * $temp;
    my $r = $a * (1 - $ecose);
    my $temp1 = 1 / $r;
    my $rdot = SGP_XKE * sqrt($a) * $esine * $temp1;
    my $rfdot = SGP_XKE * sqrt($pl) * $temp1;
    $temp2 = $a * $temp1;
    my $betal = sqrt($temp);
    $temp3 = 1 / (1 + $betal);
    my $cosu = $temp2 * ($cosepw - $axn + $ayn * $esine * $temp3);
    my $sinu = $temp2 * ($sinepw - $ayn - $axn * $esine * $temp3);
    my $u = _actan($sinu,$cosu);
    my $sin2u = 2 * $sinu * $cosu;
    my $cos2u = 2 * $cosu * $cosu - 1;
    $temp = 1 / $pl;
    $temp1 = SGP_CK2 * $temp;
    $temp2 = $temp1 * $temp;

#*	Update for short periodics

    my $rk = $r * (1 - 1.5 * $temp2 * $betal * $parm->{x3thm1}) + .5 *
	$temp1 * $parm->{x1mth2} * $cos2u;
    my $uk = $u - .25 * $temp2 * $parm->{x7thm1} * $sin2u;
    my $xnodek = $xnode + 1.5 * $temp2 * $parm->{cosi0} * $sin2u;
    my $xinck = $self->{inclination} + 1.5 * $temp2 * $parm->{cosi0} *
	$parm->{sini0} * $cos2u;
    my $rdotk = $rdot - $xn * $temp1 * $parm->{x1mth2} * $sin2u;
    my $rfdotk = $rfdot + $xn * $temp1 * ($parm->{x1mth2} * $cos2u + 1.5
	* $parm->{x3thm1});

#*	Orientation vectors

    my $sinuk = sin ($uk);
    my $cosuk = cos ($uk);
    my $sinik = sin ($xinck);
    my $cosik = cos ($xinck);
    my $sinnok = sin ($xnodek);
    my $cosnok = cos ($xnodek);
    my $xmx = - $sinnok * $cosik;
    my $xmy = $cosnok * $cosik;
    my $ux = $xmx * $sinuk + $cosnok * $cosuk;
    my $uy = $xmy * $sinuk + $sinnok * $cosuk;
    my $uz = $sinik * $sinuk;
    my $vx = $xmx * $cosuk - $cosnok * $sinuk;
    my $vy = $xmy * $cosuk - $sinnok * $sinuk;
    my $vz = $sinik * $cosuk;

#*	Position and velocity

    my $x = $rk * $ux;
    my $y = $rk * $uy;
    my $z = $rk * $uz;
    my $xdot = $rdotk * $ux + $rfdotk * $vx;
    my $ydot = $rdotk * $uy + $rfdotk * $vy;
    my $zdot = $rdotk * $uz + $rfdotk * $vz;

    return _convert_out($self, $x, $y, $z, $xdot, $ydot, $zdot, $time);
}

=item $tle = $tle->sdp4($time)

This method calculates the position of the body described by the TLE
object at the given time, using the SDP4 model. The universal time of
the object is set to $time, and the 'equinox_dynamical' attribute is set
to the current value of the 'epoch_dynamical' attribute.

The result is the original object reference. You need to call one of
the Astro::Coord::ECI methods (e.g. geodetic () or equatorial ()) to
retrieve the position you just calculated.

"Spacetrack Report Number 3" (see "Acknowledgments") says that this
model can be used only for deep-space orbits.

=cut

sub sdp4 {
    my ($self, $time) = @_;
    my $oid = $self->get('id');
    $self->{model_error} = undef;
    my $tsince = ($time - $self->{epoch}) / 60;	# Calc. is in minutes.

#>>>	Rather than use a separate indicator argument to trigger
#>>>	initialization of the model, we use the Orcish maneuver to
#>>>	retrieve the results of initialization, performing the
#>>>	calculations if needed. -- TRW

    my $parm = $self->{&TLE_INIT}{TLE_sdp4} ||= do {
	$self->is_deep or croak <<EOD;
Error - The SDP4 model is not valid for near-earth objects.
        Use the SGP, SGP4, SGP4R, or SGP8 models instead.
EOD

#*      Recover original mean motion (XNODP) and semimajor axis (AODP)
#*      from input elements.

	my $a1 = (SGP_XKE / $self->{meanmotion}) ** SGP_TOTHRD;
	my $cosi0 = cos ($self->{inclination});
	my $theta2 = $cosi0 * $cosi0;
	my $x3thm1 = 3 * $theta2 - 1;
	my $eosq = $self->{eccentricity} * $self->{eccentricity};
	my $beta02 = 1 - $eosq;
	my $beta0 = sqrt ($beta02);
	my $del1 = 1.5 * SGP_CK2 * $x3thm1 / ($a1 * $a1 * $beta0 * $beta02);
	my $a0 = $a1 * (1 - $del1 * (.5 * SGP_TOTHRD + $del1 * (1 + 134
		    / 81 * $del1)));
	my $del0 = 1.5 * SGP_CK2 * $x3thm1 / ($a0 * $a0 * $beta0 * $beta02);
	my $xnodp = $self->{meanmotion} / (1 + $del0);
# no problem here - we know this because AODP is returned.
	my $aodp = $a0 / (1 - $del0);

#*	Initialization

#*	For perigee below 156 KM, the values of
#*	S and QOMS2T are altered

	my $s4 = SGP_S;
	my $qoms24 = SGP_QOMS2T;
	my $perige = ($aodp * (1 - $self->{eccentricity}) - SGP_AE) *
	    SGP_XKMPER;
	unless ($perige >= 156) {
	    $s4 = $perige > 98 ? $perige - 78 : 20;
	    $qoms24 = ((120 - $s4) * SGP_AE / SGP_XKMPER) ** 4;
	    $s4 = $s4 / SGP_XKMPER + SGP_AE;
	}
	my $pinvsq = 1 / ($aodp * $aodp * $beta02 * $beta02);
	my $sing = sin ($self->{argumentofperigee});
	my $cosg = cos ($self->{argumentofperigee});
	my $tsi = 1 / ($aodp - $s4);
	my $eta = $aodp * $self->{eccentricity} * $tsi;
	my $etasq = $eta * $eta;
	my $eeta = $self->{eccentricity} * $eta;
	my $psisq = abs (1 - $etasq);
	my $coef = $qoms24 * $tsi ** 4;
	my $coef1 = $coef / $psisq ** 3.5;
	my $c2 = $coef1 * $xnodp * ($aodp * (1 + 1.5 * $etasq + $eeta *
	    (4 + $etasq)) + .75 * SGP_CK2 * $tsi / $psisq * $x3thm1 *
	    (8 + 3 * $etasq * (8 + $etasq)));
# minor problem here
	my $c1 = $self->{bstardrag} * $c2;
	my $sini0 = sin ($self->{inclination});
	my $a3ovk2 = - SGP_XJ3 / SGP_CK2 * SGP_AE ** 3;
	my $x1mth2 = 1 - $theta2;
	my $c4 = 2 * $xnodp * $coef1 * $aodp * $beta02 * ($eta * (2 + .5 *
	    $etasq) + $self->{eccentricity} * (.5 + 2 * $etasq) -
	    2 * SGP_CK2 * $tsi / ($aodp * $psisq) * ( - 3 * $x3thm1 *
	    (1 - 2 * $eeta + $etasq * (1.5 - .5 * $eeta)) + .75 * $x1mth2 *
	    (2 * $etasq - $eeta * (1 + $etasq)) *
	    cos (2 * $self->{argumentofperigee})));
	my $theta4 = $theta2 * $theta2;
	my $temp1 = 3 * SGP_CK2 * $pinvsq * $xnodp;
	my $temp2 = $temp1 * SGP_CK2 * $pinvsq;
	my $temp3 = 1.25 * SGP_CK4 * $pinvsq * $pinvsq * $xnodp;
	my $xmdot = $xnodp + .5 * $temp1 * $beta0 * $x3thm1 +
	    .0625 * $temp2 * $beta0 * (13 - 78 * $theta2 + 137 * $theta4);
	my $x1m5th = 1 - 5 * $theta2;
	my $omgdot = - .5 * $temp1 * $x1m5th +
	    .0625 * $temp2 * (7 - 114 * $theta2 + 395 * $theta4) +
	    $temp3 * (3 - 36 * $theta2 + 49 * $theta4);
	my $xhdot1 = - $temp1 * $cosi0;
	my $xnodot = $xhdot1 + (.5 * $temp2 * (4 - 19 * $theta2) +
	    2 * $temp3 * (3 - 7 * $theta2)) * $cosi0;
# problem here (inherited from C1 problem?)
	my $xnodcf = 3.5 * $beta02 * $xhdot1 * $c1;
# problem here (inherited from C1 problem?)
	my $t2cof = 1.5 * $c1;
	my $xlcof = .125 * $a3ovk2 * $sini0 * (3 + 5 * $cosi0) / (1 + $cosi0);
	my $aycof = .25 * $a3ovk2 * $sini0;
	my $x7thm1 = 7 * $theta2 - 1;
	$self->{&TLE_INIT}{TLE_deep} = {$self->_dpinit ($eosq, $sini0, $cosi0, $beta0,
	    $aodp, $theta2, $sing, $cosg, $beta02, $xmdot, $omgdot,
	    $xnodot, $xnodp)};

	$self->{debug} and print <<eod;
Debug SDP4 - Initialize
    AODP = $aodp
    AYCOF = $aycof
    C1 = $c1  << 2.45532e-06 in test_sgp-c-lib
    c2 = $c2  << 0.000171569 in test_sgp-c-lib
    C4 = $c4
    COSIO = $cosi0
    ETA = $eta
    OMGDOT = $omgdot
    s4 = $s4
    SINIO = $sini0
    T2COF = @{[defined $t2cof ? $t2cof : 'undef']}  << 3.68298e-06 in test_sgp-c-lib
    X1MTH2 = $x1mth2
    X3THM1 = $x3thm1
    X7THM1 = $x7thm1
    XLCOF = $xlcof
    XMDOT = $xmdot
    XNODCF = $xnodcf  << -1.40764e-11 in test_sgp-c-lib
    XNODOT = $xnodot
    XNODP = $xnodp
eod
	{
	    aodp => $aodp,
	    aycof => $aycof,
	    c1 => $c1,
	    c4 => $c4,
###	    c5 => $c5,
	    cosi0 => $cosi0,
###	    d2 => $d2,
###	    d3 => $d3,
###	    d4 => $d4,
###	    delmo => $delmo,
	    eta => $eta,
###	    isimp => $isimp,
###	    omgcof => $omgcof,
	    omgdot => $omgdot,
	    sini0 => $sini0,
###	    sinmo => $sinmo,
	    t2cof => $t2cof,
###	    t3cof => $t3cof,
###	    t4cof => $t4cof,
###	    t5cof => $t5cof,
	    x1mth2 => $x1mth2,
	    x3thm1 => $x3thm1,
	    x7thm1 => $x7thm1,
	    xlcof => $xlcof,
###	    xmcof => $xmcof,
	    xmdot => $xmdot,
	    xnodcf => $xnodcf,
	    xnodot => $xnodot,
	    xnodp => $xnodp,
	};
    };
#>>>trw    my $dpsp = $self->{&TLE_INIT}{TLE_deep};

#* UPDATE FOR SECULAR GRAVITY AND ATMOSPHERIC DRAG

    my $xmdf = $self->{meananomaly} + $parm->{xmdot} * $tsince;
    my $omgadf = $self->{argumentofperigee} + $parm->{omgdot} * $tsince;
    my $xnoddf = $self->{ascendingnode} + $parm->{xnodot} * $tsince;
    my $tsq = $tsince * $tsince;
    my $xnode = $xnoddf + $parm->{xnodcf} * $tsq;
    my $tempa = 1 - $parm->{c1} * $tsince;
    my $tempe = $self->{bstardrag} * $parm->{c4} * $tsince;
    my $templ = $parm->{t2cof} * $tsq;
    my $xn = $parm->{xnodp};
    my ($em, $xinc);	# Hope this is right.
    $self->_dpsec (\$xmdf, \$omgadf, \$xnode, \$em, \$xinc, \$xn, $tsince);
    my $a = (SGP_XKE / $xn) ** SGP_TOTHRD * $tempa ** 2;
    my $e = $em - $tempe;
    my $xmam = $xmdf + $parm->{xnodp} * $templ;
    $self->_dpper (\$e, \$xinc, \$omgadf, \$xnode, \$xmam, $tsince);
    my $xl = $xmam + $omgadf + $xnode;
    $self->{debug}
	and warn "Debug - OID $oid sdp4 effective eccentricity $e\n";
    ($e > 1 || $e < -1)
	and croak "Error - OID $oid Sdp4 effective eccentricity > 1";
    my $beta = sqrt (1 - $e * $e);
    $xn = SGP_XKE / $a ** 1.5;

#* LONG PERIOD PERIODICS

    my $axn = $e * cos ($omgadf);
    my $temp = 1 / ($a * $beta * $beta);
    my $xll = $temp * $parm->{xlcof} * $axn;
    my $aynl = $temp * $parm->{aycof};
    my $xlt = $xl + $xll;
    my $ayn = $e * sin ($omgadf) + $aynl;

#* SOLVE KEPLERS EQUATION

    my $capu = mod2pi ($xlt - $xnode);
    my $temp2 = $capu;
    my ($epw, $sinepw, $cosepw, $temp3, $temp4, $temp5, $temp6);
    for (my $i = 0; $i < 10; $i++) {
	$sinepw = sin ($temp2);
	$cosepw = cos ($temp2);
	$temp3 = $axn * $sinepw;
	$temp4 = $ayn * $cosepw;
	$temp5 = $axn * $cosepw;
	$temp6 = $ayn * $sinepw;
	$epw = ($capu - $temp4 + $temp3 - $temp2) / (1 - $temp5 -
	    $temp6) + $temp2;
	last if (abs ($epw - $temp2) <= SGP_E6A);
	$temp2 = $epw;
    }

#* SHORT PERIOD PRELIMINARY QUANTITIES

    my $ecose = $temp5 + $temp6;
    my $esine = $temp3 - $temp4;
    my $elsq = $axn * $axn + $ayn * $ayn;
    $temp = 1 - $elsq;
    my $pl = $a * $temp;
    my $r = $a * (1 - $ecose);
    my $temp1 = 1 / $r;
    my $rdot = SGP_XKE * sqrt ($a) * $esine * $temp1;
    my $rfdot = SGP_XKE * sqrt ($pl) * $temp1;
    $temp2 = $a * $temp1;
    my $betal = sqrt ($temp);
    $temp3 = 1 / (1 + $betal);
    my $cosu = $temp2 * ($cosepw - $axn + $ayn * $esine * $temp3);
    my $sinu = $temp2 * ($sinepw - $ayn - $axn * $esine * $temp3);
    my $u = _actan ($sinu,$cosu);
    my $sin2u = 2 * $sinu * $cosu;
    my $cos2u = 2 * $cosu * $cosu - 1;
    $temp = 1 / $pl;
    $temp1 = SGP_CK2 * $temp;
    $temp2 = $temp1 * $temp;

#* UPDATE FOR SHORT PERIODICS

    my $rk = $r * (1 - 1.5 * $temp2 * $betal * $parm->{x3thm1}) + .5 *
	$temp1 * $parm->{x1mth2} * $cos2u;
    my $uk = $u - .25 * $temp2 * $parm->{x7thm1} * $sin2u;
    my $xnodek = $xnode + 1.5 * $temp2 * $parm->{cosi0} * $sin2u;
    my $xinck = $xinc + 1.5 * $temp2 * $parm->{cosi0} * $parm->{sini0} *
	$cos2u;
    my $rdotk = $rdot - $xn * $temp1 * $parm->{x1mth2} * $sin2u;
    my $rfdotk = $rfdot + $xn * $temp1 * ($parm->{x1mth2} * $cos2u + 1.5
	* $parm->{x3thm1});

#* ORIENTATION VECTORS

    my $sinuk = sin ($uk);
    my $cosuk = cos ($uk);
    my $sinik = sin ($xinck);
    my $cosik = cos ($xinck);
    my $sinnok = sin ($xnodek);
    my $cosnok = cos ($xnodek);
    my $xmx = - $sinnok * $cosik;
    my $xmy = $cosnok * $cosik;
    my $ux = $xmx * $sinuk + $cosnok * $cosuk;
    my $uy = $xmy * $sinuk + $sinnok * $cosuk;
    my $uz = $sinik * $sinuk;
    my $vx = $xmx * $cosuk - $cosnok * $sinuk;
    my $vy = $xmy * $cosuk - $sinnok * $sinuk;
    my $vz = $sinik * $cosuk;

#* POSITION AND VELOCITY

    my $x = $rk * $ux;
    my $y = $rk * $uy;
    my $z = $rk * $uz;
    my $xdot = $rdotk * $ux + $rfdotk * $vx;
    my $ydot = $rdotk * $uy + $rfdotk * $vy;
    my $zdot = $rdotk * $uz + $rfdotk * $vz;

    return _convert_out($self, $x, $y, $z, $xdot, $ydot, $zdot, $time);
}

=item $tle = $tle->sgp8($time)

This method calculates the position of the body described by the TLE
object at the given time, using the SGP8 model. The universal time of
the object is set to $time, and the 'equinox_dynamical' attribute is set
to the current value of the 'epoch_dynamical' attribute.

The result is the original object reference. You need to call one of
the Astro::Coord::ECI methods (e.g. geodetic () or equatorial ()) to
retrieve the position you just calculated.

"Spacetrack Report Number 3" (see "Acknowledgments") says that this
model can be used only for near-earth orbits.

=cut

sub sgp8 {
    my ($self, $time) = @_;
    my $oid = $self->get('id');
    $self->{model_error} = undef;
    my $tsince = ($time - $self->{epoch}) / 60;	# Calc. is in minutes.

#>>>	Rather than use a separate indicator argument to trigger
#>>>	initialization of the model, we use the Orcish maneuver to
#>>>	retrieve the results of initialization, performing the
#>>>	calculations if needed. -- TRW

    my $parm = $self->{&TLE_INIT}{TLE_sgp8} ||= do {
	$self->is_deep and croak <<EOD;
Error - The SGP8 model is not valid for deep space objects.
        Use the SDP4, SGP4R, or SDP8 models instead.
EOD

#*	RECOVER ORIGINAL MEAN MOTION (XNODP) AND SEMIMAJOR AXIS (AODP)
#*	FROM INPUT ELEMENTS --------- CALCULATE BALLISTIC COEFFICIENT
#*	(B TERM) FROM INPUT B* DRAG TERM

	my $a1 = (SGP_XKE / $self->{meanmotion}) ** SGP_TOTHRD;
	my $cosi = cos ($self->{inclination});
	my $theta2 = $cosi * $cosi;
	my $tthmun = 3 * $theta2 - 1;
	my $eosq = $self->{eccentricity} * $self->{eccentricity};
	my $beta02 = 1 - $eosq;
	my $beta0 = sqrt ($beta02);
	my $del1 = 1.5 * SGP_CK2 * $tthmun / ($a1 * $a1 * $beta0 * $beta02);
	my $a0 = $a1 * (1 - $del1 * (.5 * SGP_TOTHRD +
	    $del1 * (1 + 134 / 81 * $del1)));
	my $del0 = 1.5 * SGP_CK2 * $tthmun / ($a0 * $a0 * $beta0 * $beta02);
	my $aodp = $a0 / (1 - $del0);
	my $xnodp = $self->{meanmotion} / (1 + $del0);
	my $b = 2 * $self->{bstardrag} / SGP_RHO;

#*	INITIALIZATION

	my $isimp = 0;
	my $po = $aodp * $beta02;
	my $pom2 = 1 / ($po * $po);
	my $sini = sin ($self->{inclination});
	my $sing = sin ($self->{argumentofperigee});
	my $cosg = cos ($self->{argumentofperigee});
	my $temp = .5 * $self->{inclination};
	my $sinio2 = sin ($temp);
	my $cosio2 = cos ($temp);
	my $theta4 = $theta2 ** 2;
	my $unm5th = 1 - 5 * $theta2;
	my $unmth2 = 1 - $theta2;
	my $a3cof = - SGP_XJ3 / SGP_CK2 * SGP_AE ** 3;
	my $pardt1 = 3 * SGP_CK2 * $pom2 * $xnodp;
	my $pardt2 = $pardt1 * SGP_CK2 * $pom2;
	my $pardt4 = 1.25 * SGP_CK4 * $pom2 * $pom2 * $xnodp;
	my $xmdt1 = .5 * $pardt1 * $beta0 * $tthmun;
	my $xgdt1 = - .5 * $pardt1 * $unm5th;
	my $xhdt1 = - $pardt1 * $cosi;
	my $xlldot = $xnodp + $xmdt1 + .0625 * $pardt2 * $beta0 *
	    (13 - 78 * $theta2 + 137 * $theta4);
	my $omgdt = $xgdt1 + .0625 * $pardt2 * (7 - 114 * $theta2 +
	    395 * $theta4) + $pardt4 * (3 - 36 * $theta2 + 49 * $theta4);
	my $xnodot = $xhdt1 + (.5 * $pardt2 * (4 - 19 * $theta2) +
	    2 * $pardt4 * (3 - 7 * $theta2)) * $cosi;
	my $tsi = 1 / ($po - SGP_S);
	my $eta = $self->{eccentricity} * SGP_S * $tsi;
	my $eta2 = $eta ** 2;
	my $psim2 = abs (1 / (1 - $eta2));
	my $alpha2 = 1 + $eosq;
	my $eeta = $self->{eccentricity} * $eta;
	my $cos2g = 2 * $cosg ** 2 - 1;
	my $d5 = $tsi * $psim2;
	my $d1 = $d5 / $po;
	my $d2 = 12 + $eta2 * (36 + 4.5 * $eta2);
	my $d3 = $eta2 * (15 + 2.5 * $eta2);
	my $d4 = $eta * (5 + 3.75 * $eta2);
	my $b1 = SGP_CK2 * $tthmun;
	my $b2 = - SGP_CK2 * $unmth2;
	my $b3 = $a3cof * $sini;
	my $c0 = .5 * $b * SGP_RHO * SGP_QOMS2T * $xnodp * $aodp *
	    $tsi ** 4 * $psim2 ** 3.5 / sqrt ($alpha2);
	my $c1 = 1.5 * $xnodp * $alpha2 ** 2 * $c0;
	my $c4 = $d1 * $d3 * $b2;
	my $c5 = $d5 * $d4 * $b3;
	my $xndt = $c1 * ( (2 + $eta2 * (3 + 34 * $eosq) +
	    5 * $eeta * (4 + $eta2) + 8.5 * $eosq) + $d1 * $d2 * $b1 +
	    $c4 * $cos2g + $c5 * $sing);
	my $xndtn = $xndt / $xnodp;

#*	IF DRAG IS VERY SMALL, THE ISIMP FLAG IS SET AND THE
#*	EQUATIONS ARE TRUNCATED TO LINEAR VARIATION IN MEAN
#*	MOTION AND QUADRATIC VARIATION IN MEAN ANOMALY

#>>>	Note that the simplified version of the code has been swapped
#>>>	above the full version to preserve the sense of the comment.

	my ($ed, $edot, $gamma, $pp, $ovgpp, $qq, $xnd);
	if (abs ($xndtn * SGP_XMNPDA) < 2.16e-3) {
	    $isimp = 1;
	    $edot = - SGP_TOTHRD * $xndtn * (1 - $self->{eccentricity});
	} else {
	    my $d6 = $eta * (30 + 22.5 * $eta2);
	    my $d7 = $eta * (5 + 12.5 * $eta2);
	    my $d8 = 1 + $eta2 * (6.75 + $eta2);
	    my $c8 = $d1 * $d7 * $b2;
	    my $c9 = $d5 * $d8 * $b3;
	    $edot = - $c0 * ($eta * (4 + $eta2 +
		    $eosq * (15.5 + 7 * $eta2)) +
		    $self->{eccentricity} * (5 + 15 * $eta2) +
		    $d1 * $d6 * $b1 + $c8 * $cos2g + $c9 * $sing);
	    my $d20 = .5 * SGP_TOTHRD * $xndtn;
	    my $aldtal = $self->{eccentricity} * $edot / $alpha2;
	    my $tsdtts = 2 * $aodp * $tsi * ($d20 * $beta02 +
		    $self->{eccentricity} * $edot);
	    my $etdt = ($edot + $self->{eccentricity} * $tsdtts)
		    * $tsi * SGP_S;
	    my $psdtps = - $eta * $etdt * $psim2;
	    my $sin2g = 2 * $sing * $cosg;
	    my $c0dtc0 = $d20 + 4 * $tsdtts - $aldtal - 7 * $psdtps;
	    my $c1dtc1 = $xndtn + 4 * $aldtal + $c0dtc0;
	    my $d9 = $eta * (6 + 68 * $eosq) +
		    $self->{eccentricity} * (20 + 15 * $eta2);
	    my $d10 = 5 * $eta * (4 + $eta2) +
		    $self->{eccentricity} * (17 + 68 * $eta2);
	    my $d11 = $eta * (72 + 18 * $eta2);
	    my $d12 = $eta * (30 + 10 * $eta2);
	    my $d13 = 5 + 11.25 * $eta2;
	    my $d14 = $tsdtts - 2 * $psdtps;
	    my $d15 = 2 * ($d20 + $self->{eccentricity} * $edot / $beta02);
	    my $d1dt = $d1 * ($d14 + $d15);
	    my $d2dt = $etdt * $d11;
	    my $d3dt = $etdt * $d12;
	    my $d4dt = $etdt * $d13;
	    my $d5dt = $d5 * $d14;
	    my $c4dt = $b2 * ($d1dt * $d3 + $d1 * $d3dt);
	    my $c5dt = $b3 * ($d5dt * $d4 + $d5 * $d4dt);
	    my $d16 = $d9 * $etdt + $d10 * $edot +
		    $b1 * ($d1dt * $d2 + $d1 * $d2dt) + $c4dt * $cos2g +
		    $c5dt * $sing +
		    $xgdt1 * ($c5 * $cosg - 2 * $c4 * $sin2g);
	    my $xnddt = $c1dtc1 * $xndt + $c1 * $d16;
	    my $eddot = $c0dtc0 * $edot -
		    $c0 * ((4 + 3 * $eta2 + 30 * $eeta +
		    $eosq * (15.5 + 21 * $eta2)) * $etdt +
		    (5 + 15 * $eta2 + $eeta * (31 + 14 * $eta2)) * $edot +
		    $b1 * ($d1dt * $d6 + $d1 * $etdt * (30 + 67.5 *
		    $eta2)) + $b2 * ($d1dt * $d7 +
		    $d1 * $etdt * (5 + 37.5 * $eta2)) * $cos2g +
		    $b3 * ($d5dt * $d8 + $d5 * $etdt * $eta * (13.5 +
		    4 * $eta2)) * $sing +
		    $xgdt1 * ($c9 * $cosg - 2 * $c8 * $sin2g));
	    my $d25 = $edot ** 2;
	    my $d17 = $xnddt / $xnodp - $xndtn ** 2;
	    my $tsddts = 2 * $tsdtts * ($tsdtts - $d20) + $aodp * $tsi *
		(SGP_TOTHRD * $beta02 * $d17 - 4 * $d20 *
		$self->{eccentricity} * $edot + 2 *
		($d25 + $self->{eccentricity} * $eddot));
	    my $etddt = ($eddot + 2 * $edot * $tsdtts) * $tsi * SGP_S +
		$tsddts * $eta;
	    my $d18 = $tsddts - $tsdtts ** 2;
	    my $d19 = - $psdtps ** 2 / $eta2 - $eta * $etddt * $psim2 -
		$psdtps ** 2;
	    my $d23 = $etdt * $etdt;
	    my $d1ddt = $d1dt * ($d14 + $d15) + $d1 * ($d18 - 2 * $d19 +
		SGP_TOTHRD * $d17 + 2 * ($alpha2 * $d25 / $beta02 +
		$self->{eccentricity} * $eddot) / $beta02);
	    my $xntrdt = $xndt * (2 * SGP_TOTHRD * $d17 + 3 * ($d25 +
		$self->{eccentricity} * $eddot) / $alpha2 -
		6 * $aldtal ** 2 + 4 * $d18 - 7 * $d19 ) +
		$c1dtc1 * $xnddt + $c1 * ($c1dtc1 * $d16 + $d9 * $etddt +
		$d10 * $eddot + $d23 * (6 + 30 * $eeta + 68 * $eosq) +
		$etdt * $edot * (40 + 30 * $eta2 + 272 * $eeta) +
		$d25 * (17 + 68 * $eta2) + $b1 * ($d1ddt * $d2 +
		2 * $d1dt * $d2dt + $d1 * ($etddt * $d11 +
		$d23 * (72 + 54 * $eta2))) + $b2 * ($d1ddt * $d3 +
		2 * $d1dt * $d3dt + $d1 * ($etddt * $d12 +
		$d23 * (30 + 30 * $eta2))) * $cos2g +
		$b3 * (($d5dt * $d14 + $d5 * ($d18 - 2 * $d19)) * $d4 +
		2 * $d4dt * $d5dt + $d5 * ($etddt * $d13 +
		22.5 * $eta * $d23)) * $sing + $xgdt1 * ((7 * $d20 +
		4 * $self->{eccentricity} * $edot / $beta02) *
		($c5 * $cosg - 2 * $c4 * $sin2g) + ( (2 * $c5dt * $cosg -
		4 * $c4dt * $sin2g) - $xgdt1 * ($c5 * $sing +
		4 * $c4 * $cos2g))));
	    my $tmnddt = $xnddt * 1.e9;
	    my $temp = $tmnddt ** 2 - $xndt * 1.e18 * $xntrdt;
	    $pp = ($temp + $tmnddt ** 2) / $temp;
	    $gamma = - $xntrdt / ($xnddt * ($pp - 2.));
	    $xnd = $xndt / ($pp * $gamma);
	    $qq = 1 - $eddot / ($edot * $gamma);
	    $ed = $edot / ($qq * $gamma);
	    $ovgpp = 1 / ($gamma * ($pp + 1.));
	}
	$self->{debug} and print <<eod;
Debug SGP8 - Initialize
    A3COF = @{[defined $a3cof ? $a3cof : 'undef']}
    COSI = @{[defined $cosi ? $cosi : 'undef']}
    COSIO2 = @{[defined $cosio2 ? $cosio2 : 'undef']}
    ED = @{[defined $ed ? $ed : 'undef']}
    EDOT = @{[defined $edot ? $edot : 'undef']}
    GAMMA = @{[defined $gamma ? $gamma : 'undef']}
    ISIMP = @{[defined $isimp ? $isimp : 'undef']}
    OMGDT = @{[defined $omgdt ? $omgdt : 'undef']}
    OVGPP = @{[defined $ovgpp ? $ovgpp : 'undef']}
    PP = @{[defined $pp ? $pp : 'undef']}
    QQ = @{[defined $qq ? $qq : 'undef']}
    SINI = @{[defined $sini ? $sini : 'undef']}
    SINIO2 = @{[defined $sinio2 ? $sinio2 : 'undef']}
    THETA2 = @{[defined $theta2 ? $theta2 : 'undef']}
    TTHMUN = @{[defined $tthmun ? $tthmun : 'undef']}
    UNM5TH = @{[defined $unm5th ? $unm5th : 'undef']}
    UNMTH2 = @{[defined $unmth2 ? $unmth2 : 'undef']}
    XGDT1 = @{[defined $xgdt1 ? $xgdt1 : 'undef']}
    XHDT1 = @{[defined $xhdt1 ? $xhdt1 : 'undef']}
    XLLDOT = @{[defined $xlldot ? $xlldot : 'undef']}
    XMDT1 = @{[defined $xmdt1 ? $xmdt1 : 'undef']}
    XND = @{[defined $xnd ? $xnd : 'undef']}
    XNDT = @{[defined $xndt ? $xndt : 'undef']}
    XNODOT = @{[defined $xnodot ? $xnodot : 'undef']}
    XNODP = @{[defined $xnodp ? $xnodp : 'undef']}
eod
	{
	    a3cof => $a3cof,
	    cosi => $cosi,
	    cosio2 => $cosio2,
	    ed => $ed,
	    edot => $edot,
	    gamma => $gamma,
	    isimp => $isimp,
	    omgdt => $omgdt,
	    ovgpp => $ovgpp,
	    pp => $pp,
	    qq => $qq,
	    sini => $sini,
	    sinio2 => $sinio2,
	    theta2 => $theta2,
	    tthmun => $tthmun,
	    unm5th => $unm5th,
	    unmth2 => $unmth2,
	    xgdt1 => $xgdt1,
	    xhdt1 => $xhdt1,
	    xlldot => $xlldot,
	    xmdt1 => $xmdt1,
	    xnd => $xnd,
	    xndt => $xndt,
	    xnodot => $xnodot,
	    xnodp => $xnodp,
	};
    };

#*	UPDATE FOR SECULAR GRAVITY AND ATMOSPHERIC DRAG

    my $xmam = mod2pi ($self->{meananomaly} + $parm->{xlldot} * $tsince);
    my $omgasm = $self->{argumentofperigee} + $parm->{omgdt} * $tsince;
    my $xnodes = $self->{ascendingnode} + $parm->{xnodot} * $tsince;

#>>>	The simplified and full logic have been swapped for clarity.

    my ($xn, $em, $z1);
    if ($parm->{isimp}) {
	$xn = $parm->{xnodp} + $parm->{xndt} * $tsince;
	$em = $self->{eccentricity} + $parm->{edot} * $tsince;
	$z1 = .5 * $parm->{xndt} * $tsince * $tsince;
    } else {
	my $temp = 1 - $parm->{gamma} * $tsince;
	my $temp1 = $temp ** $parm->{pp};
	$xn = $parm->{xnodp} + $parm->{xnd} * (1 - $temp1);
	$em = $self->{eccentricity} + $parm->{ed} * (1 - $temp ** $parm->{qq});
	$z1 = $parm->{xnd} * ($tsince + $parm->{ovgpp} * ($temp * $temp1 - 1.));
    }
    my $z7 = 3.5 * SGP_TOTHRD * $z1 / $parm->{xnodp};
    $xmam = mod2pi ($xmam + $z1 + $z7 * $parm->{xmdt1});
    $omgasm = $omgasm + $z7 * $parm->{xgdt1};
    $xnodes = $xnodes + $z7 * $parm->{xhdt1};

#*      SOLVE KEPLERS EQUATION

    my $zc2 = $xmam + $em * sin ($xmam) * (1 + $em * cos ($xmam));
    my ($cose, $sine, $zc5);
    for (my $i = 0; $i < 10; $i++) {
	$sine = sin ($zc2);
	$cose = cos ($zc2);
	$zc5 = 1 / (1 - $em * $cose);
	my $cape = ($xmam + $em * $sine - $zc2) * $zc5 + $zc2;
	last if (abs ($cape - $zc2) <= SGP_E6A);
	$zc2 = $cape;
    }

#*      SHORT PERIOD PRELIMINARY QUANTITIES

    my $am = (SGP_XKE / $xn) ** SGP_TOTHRD;
    my $beta2m = 1 - $em * $em;
    $self->{debug}
	and warn "Debug - OID $oid sgp8 effective eccentricity $em\n";
    $beta2m < 0
	and croak "Error - OID $oid Sgp8 effective eccentricity > 1";
    my $sinos = sin ($omgasm);
    my $cosos = cos ($omgasm);
    my $axnm = $em * $cosos;
    my $aynm = $em * $sinos;
    my $pm = $am * $beta2m;
    my $g1 = 1 / $pm;
    my $g2 = .5 * SGP_CK2 * $g1;
    my $g3 = $g2 * $g1;
    my $beta = sqrt ($beta2m);
    my $g4 = .25 * $parm->{a3cof} * $parm->{sini};
    my $g5 = .25 * $parm->{a3cof} * $g1;
    my $snf = $beta * $sine * $zc5;
    my $csf = ($cose - $em) * $zc5;
    my $fm = _actan ($snf,$csf);
    my $snfg = $snf * $cosos + $csf * $sinos;
    my $csfg = $csf * $cosos - $snf * $sinos;
    my $sn2f2g = 2 * $snfg * $csfg;
    my $cs2f2g = 2 * $csfg ** 2 - 1;
    my $ecosf = $em * $csf;
    my $g10 = $fm - $xmam + $em * $snf;
    my $rm = $pm / (1 + $ecosf);
    my $aovr = $am / $rm;
    my $g13 = $xn * $aovr;
    my $g14 = - $g13 * $aovr;
    my $dr = $g2 * ($parm->{unmth2} * $cs2f2g - 3 * $parm->{tthmun}) -
	    $g4 * $snfg;
    my $diwc = 3 * $g3 * $parm->{sini} * $cs2f2g - $g5 * $aynm;
    my $di = $diwc * $parm->{cosi};

#*      UPDATE FOR SHORT PERIOD PERIODICS

    my $sni2du = $parm->{sinio2} * ($g3 * (.5 * (1 - 7 * $parm->{theta2}) *
	    $sn2f2g - 3 * $parm->{unm5th} * $g10) - $g5 * $parm->{sini} *
	    $csfg * (2 + $ecosf)) - .5 * $g5 * $parm->{theta2} * $axnm /
	    $parm->{cosio2};
    my $xlamb = $fm + $omgasm + $xnodes + $g3 * (.5 * (1 + 6 *
	    $parm->{cosi} - 7 * $parm->{theta2}) * $sn2f2g - 3 *
	    ($parm->{unm5th} + 2 * $parm->{cosi}) * $g10) +
	    $g5 * $parm->{sini} * ($parm->{cosi} * $axnm /
	    (1 + $parm->{cosi}) - (2 + $ecosf) * $csfg);
    my $y4 = $parm->{sinio2} * $snfg + $csfg * $sni2du +
	    .5 * $snfg * $parm->{cosio2} * $di;
    my $y5 = $parm->{sinio2} * $csfg - $snfg * $sni2du +
	    .5 * $csfg * $parm->{cosio2} * $di;
    my $r = $rm + $dr;
    my $rdot = $xn * $am * $em * $snf / $beta + $g14 *
	    (2 * $g2 * $parm->{unmth2} * $sn2f2g + $g4 * $csfg);
    my $rvdot = $xn * $am ** 2 * $beta / $rm + $g14 * $dr +
	    $am * $g13 * $parm->{sini} * $diwc;

#*      ORIENTATION VECTORS

    my $snlamb = sin ($xlamb);
    my $cslamb = cos ($xlamb);
    my $temp = 2 * ($y5 * $snlamb - $y4 * $cslamb);
    my $ux = $y4 * $temp + $cslamb;
    my $vx = $y5 * $temp - $snlamb;
    $temp = 2 * ($y5 * $cslamb + $y4 * $snlamb);
    my $uy = - $y4 * $temp + $snlamb;
    my $vy = - $y5 * $temp + $cslamb;
    $temp = 2 * sqrt (1 - $y4 * $y4 - $y5 * $y5);
    my $uz = $y4 * $temp;
    my $vz = $y5 * $temp;

#*      POSITION AND VELOCITY

    my $x = $r * $ux;
    my $y = $r * $uy;
    my $z = $r * $uz;
    my $xdot = $rdot * $ux + $rvdot * $vx;
    my $ydot = $rdot * $uy + $rvdot * $vy;
    my $zdot = $rdot * $uz + $rvdot * $vz;

    return _convert_out ($self, $x, $y, $z, $xdot, $ydot, $zdot, $time);
}

=item $tle = $tle->sdp8($time)

This method calculates the position of the body described by the TLE
object at the given time, using the SDP8 model. The universal time of
the object is set to $time, and the 'equinox_dynamical' attribute is set
to the current value of the 'epoch_dynamical' attribute.

The result is the original object reference. You need to call one of
the Astro::Coord::ECI methods (e.g. geodetic () or equatorial ()) to
retrieve the position you just calculated.

"Spacetrack Report Number 3" (see "Acknowledgments") says that this
model can be used only for near-earth orbits.

=cut

sub sdp8 {
    my ($self, $time) = @_;
    my $oid = $self->get('id');
    $self->{model_error} = undef;
    my $tsince = ($time - $self->{epoch}) / 60;	# Calc. is in minutes.

#>>>	Rather than use a separate indicator argument to trigger
#>>>	initialization of the model, we use the Orcish maneuver to
#>>>	retrieve the results of initialization, performing the
#>>>	calculations if needed. -- TRW

    my $parm = $self->{&TLE_INIT}{TLE_sdp8} ||= do {
	$self->is_deep or croak <<EOD;
Error - The SDP8 model is not valid for near-earth objects.
        Use the SGP, SGP4, SGP4R, or SGP8 models instead.
EOD

#*      RECOVER ORIGINAL MEAN MOTION (XNODP) AND SEMIMAJOR AXIS (AODP)
#*      FROM INPUT ELEMENTS --------- CALCULATE BALLISTIC COEFFICIENT
#* (B TERM) FROM INPUT B* DRAG TERM

	my $a1 = (SGP_XKE / $self->{meanmotion}) ** SGP_TOTHRD;
	my $cosi = cos ($self->{inclination});
	my $theta2 = $cosi * $cosi;
	my $tthmun = 3 * $theta2 - 1;
	my $eosq = $self->{eccentricity} * $self->{eccentricity};
	my $beta02 = 1 - $eosq;
	my $beta0 = sqrt ($beta02);
	my $del1 = 1.5 * SGP_CK2 * $tthmun / ($a1 * $a1 * $beta0 * $beta02);
	my $a0 = $a1 * (1 - $del1 * (.5 * SGP_TOTHRD + $del1 * (1 + 134
		    / 81 * $del1)));
	my $del0 = 1.5 * SGP_CK2 * $tthmun / ($a0 * $a0 * $beta0 * $beta02);
	my $aodp = $a0 / (1 - $del0);
	my $xnodp = $self->{meanmotion} / (1 + $del0);
	my $b = 2 * $self->{bstardrag} / SGP_RHO;

#*      INITIALIZATION

	my $po = $aodp * $beta02;
	my $pom2 = 1 / ($po * $po);
	my $sini = sin ($self->{inclination});
	my $sing = sin ($self->{argumentofperigee});
	my $cosg = cos ($self->{argumentofperigee});
	my $temp = .5 * $self->{inclination};
	my $sinio2 = sin ($temp);
	my $cosio2 = cos ($temp);
	my $theta4 = $theta2 ** 2;
	my $unm5th = 1 - 5 * $theta2;
	my $unmth2 = 1 - $theta2;
	my $a3cof = - SGP_XJ3 / SGP_CK2 * SGP_AE ** 3;
	my $pardt1 = 3 * SGP_CK2 * $pom2 * $xnodp;
	my $pardt2 = $pardt1 * SGP_CK2 * $pom2;
	my $pardt4 = 1.25 * SGP_CK4 * $pom2 * $pom2 * $xnodp;
	my $xmdt1 = .5 * $pardt1 * $beta0 * $tthmun;
	my $xgdt1 = - .5 * $pardt1 * $unm5th;
	my $xhdt1 = - $pardt1 * $cosi;
	my $xlldot = $xnodp + $xmdt1 + .0625 * $pardt2 * $beta0 * (13 -
	    78 * $theta2 + 137 * $theta4);
	my $omgdt = $xgdt1 + .0625 * $pardt2 * (7 - 114 * $theta2 + 395
	    * $theta4) + $pardt4 * (3 - 36 * $theta2 + 49 * $theta4);
	my $xnodot = $xhdt1 + (.5 * $pardt2 * (4 - 19 * $theta2) + 2 *
	    $pardt4 * (3 - 7 * $theta2)) * $cosi;
	my $tsi = 1 / ($po - SGP_S);
	my $eta = $self->{eccentricity} * SGP_S * $tsi;
	my $eta2 = $eta ** 2;
	my $psim2 = abs (1 / (1 - $eta2));
	my $alpha2 = 1 + $eosq;
	my $eeta = $self->{eccentricity} * $eta;
	my $cos2g = 2 * $cosg ** 2 - 1;
	my $d5 = $tsi * $psim2;
	my $d1 = $d5 / $po;
	my $d2 = 12 + $eta2 * (36 + 4.5 * $eta2);
	my $d3 = $eta2 * (15 + 2.5 * $eta2);
	my $d4 = $eta * (5 + 3.75 * $eta2);
	my $b1 = SGP_CK2 * $tthmun;
	my $b2 = - SGP_CK2 * $unmth2;
	my $b3 = $a3cof * $sini;
	my $c0 = .5 * $b * SGP_RHO * SGP_QOMS2T * $xnodp * $aodp *
	    $tsi ** 4 * $psim2 ** 3.5 / sqrt ($alpha2);
	my $c1 = 1.5 * $xnodp * $alpha2 ** 2 * $c0;
	my $c4 = $d1 * $d3 * $b2;
	my $c5 = $d5 * $d4 * $b3;
	my $xndt = $c1 * ( (2 + $eta2 * (3 + 34 * $eosq) +
	    5 * $eeta * (4 + $eta2) + 8.5 * $eosq) + $d1 * $d2 * $b1 +
	    $c4 * $cos2g + $c5 * $sing);
	my $xndtn = $xndt / $xnodp;
	my $edot = - SGP_TOTHRD * $xndtn * (1 - $self->{eccentricity});
	$self->{&TLE_INIT}{TLE_deep} = {$self->_dpinit ($eosq, $sini,
		$cosi, $beta0, $aodp, $theta2, $sing, $cosg, $beta02,
		$xlldot, $omgdt, $xnodot, $xnodp)};
	{
	    a3cof => $a3cof,
	    cosi => $cosi,
	    cosio2 => $cosio2,
###	    ed => $ed,
	    edot => $edot,
###	    gamma => $gamma,
###	    isimp => $isimp,
	    omgdt => $omgdt,
###	    ovgpp => $ovgpp,
###	    pp => $pp,
###	    qq => $qq,
	    sini => $sini,
	    sinio2 => $sinio2,
	    theta2 => $theta2,
	    tthmun => $tthmun,
	    unm5th => $unm5th,
	    unmth2 => $unmth2,
	    xgdt1 => $xgdt1,
	    xhdt1 => $xhdt1,
	    xlldot => $xlldot,
	    xmdt1 => $xmdt1,
###	    xnd => $xnd,
	    xndt => $xndt,
	    xnodot => $xnodot,
	    xnodp => $xnodp,
	};
    };
#>>>trw    my $dpsp = $self->{&TLE_INIT}{TLE_deep};

#*	UPDATE FOR SECULAR GRAVITY AND ATMOSPHERIC DRAG

    my $z1 = .5 * $parm->{xndt} * $tsince * $tsince;
    my $z7 = 3.5 * SGP_TOTHRD * $z1 / $parm->{xnodp};
    my $xmamdf = $self->{meananomaly} + $parm->{xlldot} * $tsince;
    my $omgasm = $self->{argumentofperigee} + $parm->{omgdt} * $tsince +
	$z7 * $parm->{xgdt1};
    my $xnodes = $self->{ascendingnode} + $parm->{xnodot} * $tsince +
	$z7 * $parm->{xhdt1};
    my $xn = $parm->{xnodp};
    my ($em, $xinc);
    $self->_dpsec (\$xmamdf, \$omgasm, \$xnodes, \$em, \$xinc, \$xn, $tsince);
    $xn = $xn + $parm->{xndt} * $tsince;
    $em = $em + $parm->{edot} * $tsince;
    my $xmam = $xmamdf + $z1 + $z7 * $parm->{xmdt1};
    $self->_dpper (\$em, \$xinc, \$omgasm, \$xnodes, \$xmam, $tsince);
    $xmam = mod2pi ($xmam);

#*	SOLVE KEPLERS EQUATION

    my $zc2 = $xmam + $em * sin ($xmam) * (1 + $em * cos ($xmam));
    my ($cose, $sine, $zc5);
    for (my $i = 0; $i < 10; $i++) {
	$sine = sin ($zc2);
	$cose = cos ($zc2);
	$zc5 = 1 / (1 - $em * $cose);
	my $cape = ($xmam + $em * $sine - $zc2) * $zc5 + $zc2;
	last if (abs ($cape - $zc2) <= SGP_E6A);
	$zc2 = $cape;
    }

#*	SHORT PERIOD PRELIMINARY QUANTITIES

    my $am = (SGP_XKE / $xn) ** SGP_TOTHRD;
    my $beta2m = 1 - $em * $em;
    $self->{debug}
	and warn "Debug - OID $oid sdp8 effective eccentricity $em\n";
    $beta2m < 0
	and croak "Error - OID $oid Sdp8 effective eccentricity > 1";
    my $sinos = sin ($omgasm);
    my $cosos = cos ($omgasm);
    my $axnm = $em * $cosos;
    my $aynm = $em * $sinos;
    my $pm = $am * $beta2m;
    my $g1 = 1 / $pm;
    my $g2 = .5 * SGP_CK2 * $g1;
    my $g3 = $g2 * $g1;
    my $beta = sqrt ($beta2m);
    my $g4 = .25 * $parm->{a3cof} * $parm->{sini};
    my $g5 = .25 * $parm->{a3cof} * $g1;
    my $snf = $beta * $sine * $zc5;
    my $csf = ($cose - $em) * $zc5;
    my $fm = _actan ($snf,$csf);
    my $snfg = $snf * $cosos + $csf * $sinos;
    my $csfg = $csf * $cosos - $snf * $sinos;
    my $sn2f2g = 2 * $snfg * $csfg;
    my $cs2f2g = 2 * $csfg ** 2 - 1;
    my $ecosf = $em * $csf;
    my $g10 = $fm - $xmam + $em * $snf;
    my $rm = $pm / (1 + $ecosf);
    my $aovr = $am / $rm;
    my $g13 = $xn * $aovr;
    my $g14 = - $g13 * $aovr;
    my $dr = $g2 * ($parm->{unmth2} * $cs2f2g - 3 * $parm->{tthmun}) -
	    $g4 * $snfg;
    my $diwc = 3 * $g3 * $parm->{sini} * $cs2f2g - $g5 * $aynm;
    my $di = $diwc * $parm->{cosi};
    my $sini2 = sin (.5 * $xinc);

#*	UPDATE FOR SHORT PERIOD PERIODICS

    my $sni2du = $parm->{sinio2} * ($g3 * (.5 * (1 - 7 * $parm->{theta2}) *
	    $sn2f2g - 3 * $parm->{unm5th} * $g10) - $g5 * $parm->{sini} *
	    $csfg * (2 + $ecosf)) - .5 * $g5 * $parm->{theta2} * $axnm /
	    $parm->{cosio2};
    my $xlamb = $fm + $omgasm + $xnodes + $g3 * (.5 * (1 +
	    6 * $parm->{cosi} - 7 * $parm->{theta2}) * $sn2f2g -
	    3 * ($parm->{unm5th} + 2 * $parm->{cosi}) * $g10) +
	    $g5 * $parm->{sini} * ($parm->{cosi} * $axnm /
	    (1 + $parm->{cosi}) - (2 + $ecosf) * $csfg);
    my $y4 = $sini2 * $snfg + $csfg * $sni2du +
	    .5 * $snfg * $parm->{cosio2} * $di;
    my $y5 = $sini2 * $csfg - $snfg * $sni2du +
	    .5 * $csfg * $parm->{cosio2} * $di;
    my $r = $rm + $dr;
    my $rdot = $xn * $am * $em * $snf / $beta +
	    $g14 * (2 * $g2 * $parm->{unmth2} * $sn2f2g + $g4 * $csfg);
    my $rvdot = $xn * $am ** 2 * $beta / $rm + $g14 * $dr +
	    $am * $g13 * $parm->{sini} * $diwc;

#*	ORIENTATION VECTORS

    my $snlamb = sin ($xlamb);
    my $cslamb = cos ($xlamb);
    my $temp = 2 * ($y5 * $snlamb - $y4 * $cslamb);
    my $ux = $y4 * $temp + $cslamb;
    my $vx = $y5 * $temp - $snlamb;
    $temp = 2 * ($y5 * $cslamb + $y4 * $snlamb);
    my $uy = - $y4 * $temp + $snlamb;
    my $vy = - $y5 * $temp + $cslamb;
    $temp = 2 * sqrt (1 - $y4 * $y4 - $y5 * $y5);
    my $uz = $y4 * $temp;
    my $vz = $y5 * $temp;

#*	POSITION AND VELOCITY

    my $x = $r * $ux;
    my $y = $r * $uy;
    my $z = $r * $uz;
    my $xdot = $rdot * $ux + $rvdot * $vx;
    my $ydot = $rdot * $uy + $rvdot * $vy;
    my $zdot = $rdot * $uz + $rvdot * $vz;

    return _convert_out ($self, $x, $y, $z, $xdot, $ydot, $zdot, $time);
}

=item $self->time_set();

This method sets the coordinates of the object to whatever is
computed by the model specified by the model attribute. The
'equinox_dynamical' attribute is set to the current value of the
'epoch_dynamical' attribute.

Although there is no reason this method can not be called directly, it
exists to take advantage of the hook in the B<Astro::Coord::ECI>
object, to allow the position of the body to be computed when the
time of the object is set.

=cut

sub time_set {
    my $self = shift;
    my $model = $self->{model} or return;
    $self->$model ($self->universal);
    return;
}

#######################################################################

#	The deep-space routines

use constant DS_ZNS => 1.19459E-5;
use constant DS_C1SS => 2.9864797E-6;
use constant DS_ZES => .01675;
use constant DS_ZNL => 1.5835218E-4;
use constant DS_C1L => 4.7968065E-7;
use constant DS_ZEL => .05490;
use constant DS_ZCOSIS => .91744867;
use constant DS_ZSINIS => .39785416;
use constant DS_ZSINGS => -.98088458;
use constant DS_ZCOSGS => .1945905;
use constant DS_ZCOSHS => 1.0;
use constant DS_ZSINHS => 0.0;
use constant DS_Q22 => 1.7891679E-6;
use constant DS_Q31 => 2.1460748E-6;
use constant DS_Q33 => 2.2123015E-7;
use constant DS_G22 => 5.7686396;
use constant DS_G32 => 0.95240898;
use constant DS_G44 => 1.8014998;
use constant DS_G52 => 1.0508330;
use constant DS_G54 => 4.4108898;
use constant DS_ROOT22 => 1.7891679E-6;
use constant DS_ROOT32 => 3.7393792E-7;
use constant DS_ROOT44 => 7.3636953E-9;
use constant DS_ROOT52 => 1.1428639E-7;
use constant DS_ROOT54 => 2.1765803E-9;
use constant DS_THDT => 4.3752691E-3;

#	_dpinit
#
#	the corresponding FORTRAN IV simply leaves values in variables
#	for the use of the other deep-space routines. For the Perl
#	translation, we figure out which ones are actually used, and
#	return a list of key/value pairs to be added to the pre-
#	computed model parameters. -- TRW

sub _dpinit {
    my ($self, $eqsq, $siniq, $cosiq, $rteqsq, $a0, $cosq2, $sinomo,
	    $cosomo, $bsq, $xlldot, $omgdt, $xnodot, $xnodp) = @_;

    my $thgr = thetag ($self->{epoch});
    my $eq  =  $self->{eccentricity};
    my $xnq  =  $xnodp;
    my $aqnv  =  1 / $a0;
    my $xqncl  =  $self->{inclination};
    my $xmao = $self->{meananomaly};
    my $xpidot = $omgdt + $xnodot;
    my $sinq  =  sin ($self->{ascendingnode});
    my $cosq  =  cos ($self->{ascendingnode});

#*	Initialize lunar & solar terms

    my $day = $self->{ds50} + 18261.5;

#>>>	The original code contained here a comparison of DAY to
#>>>	uninitialized variable PREEP, and "optimized out" the
#>>>	following if they were equal. This works naturally in
#>>>	FORTRAN, which has a different concept of variable scoping.
#>>>	Rather than make this work in Perl, I have removed the
#>>>	test. As I understand the FORTRAN, it's only used if
#>>>	consecutive data sets have exactly the same epoch. Given
#>>>	that this is initialization code, the optimization is
#>>>	(I hope!) not that important, and given the mess that
#>>>	follows, its absence will not (I hope!) be noticable. - TRW

    my $xnodce = 4.5236020 - 9.2422029E-4 * $day;
    my $stem = sin ($xnodce);
    my $ctem = cos ($xnodce);
    my $zcosil = .91375164 - .03568096 * $ctem;
    my $zsinil = sqrt (1 - $zcosil * $zcosil);
    my $zsinhl =  .089683511 * $stem / $zsinil;
    my $zcoshl = sqrt (1 - $zsinhl * $zsinhl);
    my $c = 4.7199672 + .22997150 * $day;
    my $gam = 5.8351514 + .0019443680 * $day;
    my $zmol = mod2pi ($c - $gam);
    my $zx = .39785416 * $stem / $zsinil;
    my $zy = $zcoshl * $ctem + 0.91744867 * $zsinhl * $stem;
    $zx = _actan ($zx, $zy);
    $zx = $gam + $zx - $xnodce;
    my $zcosgl = cos ($zx);
    my $zsingl = sin ($zx);
    my $zmos = mod2pi (6.2565837 + .017201977 * $day);

#>>>	Here endeth the optimization - only it isn't one any more
#>>>	since I removed it. - TRW

#>>>	The following loop replaces some spaghetti involving an
#>>>	assigned goto which essentially executes the same big chunk
#>>>	of obscure code twice: once for the Sun, and once for the Moon.
#>>>	The comments "Do Solar terms" and "Do Lunar terms" in the
#>>>	original apply to the first and second iterations of the loop,
#>>>	respectively. The "my" variables declared just before the "for"
#>>>	are those values computed inside the loop that are used outside
#>>>	the loop. Accumulators are set to zero. -- TRW

#>>>trw    my $savtsn = 1.0E20;
    my $xnoi = 1 / $xnq;
    my ($sse, $ssi, $ssl, $ssh, $ssg) = (0, 0, 0, 0, 0);
    my ($se2, $ee2, $si2, $xi2, $sl2, $xl2, $sgh2, $xgh2, $sh2, $xh2, $se3,
	$e3, $si3, $xi3, $sl3, $xl3, $sgh3, $xgh3, $sh3, $xh3, $sl4, $xl4,
	$sgh4, $xgh4);

    foreach my $inputs (
	    [DS_ZCOSGS, DS_ZSINGS, DS_ZCOSIS, DS_ZSINIS, $cosq, $sinq,
		    DS_C1SS, DS_ZNS, DS_ZES, $zmos, 0],
	    [$zcosgl, $zsingl, $zcosil, $zsinil,
		    $zcoshl * $cosq + $zsinhl * $sinq,
		    $sinq * $zcoshl - $cosq * $zsinhl, DS_C1L, DS_ZNL,
		    DS_ZEL, $zmol, 1],
	    ) {

#>>>	Pick off the terms specific to the body being covered by this
#>>>	iteration. The $lunar flag was not in the original FORTRAN, but
#>>>	was added to help convert the assigned GOTOs and associated
#>>>	code into a loop. -- TRW

#>>>trw	my ($zcosg, $zsing, $zcosi, $zsini, $zcosh, $zsinh, $cc, $zn, $ze,
#>>>trw	    $zmo, $lunar) = @$inputs;
	my ($zcosg, $zsing, $zcosi, $zsini, $zcosh, $zsinh, $cc, $zn, $ze,
	    undef, $lunar) = @$inputs;

#>>>	From here until the next comment of mine is essentialy
#>>>	verbatim from the original FORTRAN - or as verbatim as
#>>>	is reasonable considering that the following is Perl. -- TRW

	my $a1 = $zcosg * $zcosh + $zsing * $zcosi * $zsinh;
	my $a3 = - $zsing * $zcosh + $zcosg * $zcosi * $zsinh;
	my $a7 = - $zcosg * $zsinh + $zsing * $zcosi * $zcosh;
	my $a8 = $zsing * $zsini;
	my $a9 = $zsing * $zsinh + $zcosg * $zcosi * $zcosh;
	my $a10 = $zcosg * $zsini;
	my $a2 = $cosiq * $a7 + $siniq * $a8;
	my $a4 = $cosiq * $a9 + $siniq * $a10;
	my $a5 = - $siniq * $a7 + $cosiq * $a8;
	my $a6 = - $siniq * $a9 + $cosiq * $a10;
#C
	my $x1 = $a1 * $cosomo + $a2 * $sinomo;
	my $x2 = $a3 * $cosomo + $a4 * $sinomo;
	my $x3 = - $a1 * $sinomo + $a2 * $cosomo;
	my $x4 = - $a3 * $sinomo + $a4 * $cosomo;
	my $x5 = $a5 * $sinomo;
	my $x6 = $a6 * $sinomo;
	my $x7 = $a5 * $cosomo;
	my $x8 = $a6 * $cosomo;
#C
	my $z31 = 12 * $x1 * $x1 - 3 * $x3 * $x3;
	my $z32 = 24 * $x1 * $x2 - 6 * $x3 * $x4;
	my $z33 = 12 * $x2 * $x2 - 3 * $x4 * $x4;
	my $z1 = 3 * ($a1 * $a1 + $a2 * $a2) + $z31 * $eqsq;
	my $z2 = 6 * ($a1 * $a3 + $a2 * $a4) + $z32 * $eqsq;
	my $z3 = 3 * ($a3 * $a3 + $a4 * $a4) + $z33 * $eqsq;
	my $z11 = - 6 * $a1 * $a5 + $eqsq * ( - 24 * $x1 * $x7 - 6 * $x3 * $x5);
	my $z12 = - 6 * ($a1 * $a6 + $a3 * $a5) + $eqsq *
	    ( - 24 * ($x2 * $x7 + $x1 * $x8) - 6 * ($x3 * $x6 + $x4 * $x5));
	my $z13 = - 6 * $a3 * $a6 + $eqsq * ( - 24 * $x2 * $x8 - 6 * $x4 * $x6);
	my $z21 = 6 * $a2 * $a5 + $eqsq * (24 * $x1 * $x5 - 6 * $x3 * $x7);
	my $z22 = 6 * ($a4 * $a5 + $a2 * $a6) + $eqsq *
	    (24 * ($x2 * $x5 + $x1 * $x6) - 6 * ($x4 * $x7 + $x3 * $x8));
	my $z23 = 6 * $a4 * $a6 + $eqsq * (24 * $x2 * $x6 - 6 * $x4 * $x8);
	$z1 = $z1 + $z1 + $bsq * $z31;
	$z2 = $z2 + $z2 + $bsq * $z32;
	$z3 = $z3 + $z3 + $bsq * $z33;
	my $s3 = $cc * $xnoi;
	my $s2 = - .5 * $s3 / $rteqsq;
	my $s4 = $s3 * $rteqsq;
	my $s1 = - 15 * $eq * $s4;
	my $s5 = $x1 * $x3 + $x2 * $x4;
	my $s6 = $x2 * $x3 + $x1 * $x4;
	my $s7 = $x2 * $x4 - $x1 * $x3;
	my $se = $s1 * $zn * $s5;
	my $si = $s2 * $zn * ($z11 + $z13);
	my $sl = - $zn * $s3 * ($z1 + $z3 - 14 - 6 * $eqsq);
	my $sgh = $s4 * $zn * ($z31 + $z33 - 6.);
	my $sh = $xqncl < 5.2359877E-2 ? 0 : - $zn * $s2 * ($z21 + $z23);
	$ee2 = 2 * $s1 * $s6;
	$e3 = 2 * $s1 * $s7;
	$xi2 = 2 * $s2 * $z12;
	$xi3 = 2 * $s2 * ($z13 - $z11);
	$xl2 = - 2 * $s3 * $z2;
	$xl3 = - 2 * $s3 * ($z3 - $z1);
	$xl4 = - 2 * $s3 * ( - 21 - 9 * $eqsq) * $ze;
	$xgh2 = 2 * $s4 * $z32;
	$xgh3 = 2 * $s4 * ($z33 - $z31);
	$xgh4 = - 18 * $s4 * $ze;
	$xh2 = - 2 * $s2 * $z22;
	$xh3 = - 2 * $s2 * ($z23 - $z21);

#>>>	The following intermediate values are used outside the loop.
#>>>	We save off the Solar values. The Lunar values remain after
#>>>	the second iteration, and are used in situ. -- TRW

	unless ($lunar) {
	    $se2 = $ee2;
	    $si2 = $xi2;
	    $sl2 = $xl2;
	    $sgh2 = $xgh2;
	    $sh2 = $xh2;
	    $se3 = $e3;
	    $si3 = $xi3;
	    $sl3 = $xl3;
	    $sgh3 = $xgh3;
	    $sh3 = $xh3;
	    $sl4 = $xl4;
	    $sgh4 = $xgh4;
	}

#>>>	Okay, now we accumulate everything that needs accumulating.
#>>>	The Lunar calculation is slightly different from the solar
#>>>	one, a problem we fix up using the introduced $lunar flag.
#>>>	-- TRW

	$sse = $sse + $se;
	$ssi = $ssi + $si;
	$ssl = $ssl + $sl;
	$ssh = $ssh + $sh / $siniq;
	$ssg = $ssg + $sgh - ($lunar ? $cosiq / $siniq * $sh : $cosiq * $ssh);

    }

#>>>	The only substantial modification in the following is the
#>>>	swapping of 24-hour and 12-hour calculations for clarity.
#>>>	-- TRW

    my $iresfl = 0;
    my $isynfl = 0;
    my ($bfact, $xlamo);
    my ($d2201, $d2211, $d3210, $d3222, $d4410, $d4422,
	    $d5220, $d5232, $d5421, $d5433,
	    $del1, $del2, $del3, $fasx2, $fasx4, $fasx6);

    if ($xnq < .0052359877 && $xnq > .0034906585) {

#*      Synchronous resonance terms initialization.

	$iresfl = 1;
	$isynfl = 1;
	my $g200 = 1.0 + $eqsq * ( - 2.5 + .8125 * $eqsq);
	my $g310 = 1.0 + 2.0 * $eqsq;
	my $g300 = 1.0 + $eqsq * ( - 6.0 + 6.60937 * $eqsq);
	my $f220 = .75 * (1 + $cosiq) * (1 + $cosiq);
	my $f311 = .9375 * $siniq * $siniq * (1 + 3 * $cosiq) - .75 * (1
	    + $cosiq);
	my $f330 = 1 + $cosiq;
	$f330 = 1.875 * $f330 * $f330 * $f330;
	$del1 = 3 * $xnq * $xnq * $aqnv * $aqnv;
	$del2 = 2 * $del1 * $f220 * $g200 * DS_Q22;
	$del3 = 3 * $del1 * $f330 * $g300 * DS_Q33 * $aqnv;
	$del1 = $del1 * $f311 * $g310 * DS_Q31 * $aqnv;
	$fasx2 = .13130908;
	$fasx4 = 2.8843198;
	$fasx6 = .37448087;
	$xlamo = $xmao + $self->{ascendingnode} +
	    $self->{argumentofperigee} - $thgr;
	$bfact = $xlldot + $xpidot - DS_THDT;
	$bfact = $bfact + $ssl + $ssg + $ssh;
    } elsif ($xnq < 8.26E-3 || $xnq > 9.24E-3 || $eq < 0.5) {

#>>>	Do nothing. The original code returned from this point,
#>>>	leaving atime, step2, stepn, stepp, xfact, xli, and xni
#>>>	uninitialized. It's a minor bit of wasted motion to
#>>>	compute these when they're not used, but this way the
#>>>	method returns from only one point, which makes the
#>>>	provision of debug output easier.

    } else {

#*      Geopotential resonance initialization for 12 hour orbits

	$iresfl = 1;
	my $eoc = $eq * $eqsq;
	my $g201 = - .306 - ($eq - .64) * .440;
	my ($g211, $g310, $g322, $g410, $g422, $g520);
	if ($eq <= .65) {
	    $g211 = 3.616 - 13.247 * $eq + 16.290 * $eqsq;
	    $g310 = - 19.302 + 117.390 * $eq - 228.419 * $eqsq + 156.591
		* $eoc;
	    $g322 = - 18.9068 + 109.7927 * $eq - 214.6334 * $eqsq +
		146.5816 * $eoc;
	    $g410 = - 41.122 + 242.694 * $eq - 471.094 * $eqsq + 313.953
		* $eoc;
	    $g422 = - 146.407 + 841.880 * $eq - 1629.014 * $eqsq +
		1083.435 * $eoc;
	    $g520 = - 532.114 + 3017.977 * $eq - 5740 * $eqsq + 3708.276
		* $eoc;
	} else {
	    $g211 = - 72.099 + 331.819 * $eq - 508.738 * $eqsq +
		266.724 * $eoc;
	    $g310 = - 346.844 + 1582.851 * $eq - 2415.925 * $eqsq +
		1246.113 * $eoc;
	    $g322 = - 342.585 + 1554.908 * $eq - 2366.899 * $eqsq +
		1215.972 * $eoc;
	    $g410 = - 1052.797 + 4758.686 * $eq - 7193.992 * $eqsq +
		3651.957 * $eoc;
	    $g422 = - 3581.69 + 16178.11 * $eq - 24462.77 * $eqsq +
		12422.52 * $eoc;
	    $g520 = $eq > .715 ?
		-5149.66 + 29936.92 * $eq - 54087.36 * $eqsq + 31324.56 * $eoc :
		1464.74 - 4664.75 * $eq + 3763.64 * $eqsq;
	}
	my ($g533, $g521, $g532);
	if ($eq < .7) {
	    $g533 = - 919.2277 + 4988.61 * $eq - 9064.77 * $eqsq +
		5542.21 * $eoc;
	    $g521 = - 822.71072 + 4568.6173 * $eq - 8491.4146 * $eqsq +
		5337.524 * $eoc;
	    $g532 = - 853.666 + 4690.25 * $eq - 8624.77 * $eqsq +
		5341.4 * $eoc;
	} else {
	    $g533 = - 37995.78 + 161616.52 * $eq - 229838.2 * $eqsq +
		109377.94 * $eoc;
	    $g521 = - 51752.104 + 218913.95 * $eq - 309468.16 * $eqsq +
		146349.42 * $eoc;
	    $g532 = - 40023.88 + 170470.89 * $eq - 242699.48 * $eqsq +
		115605.82 * $eoc;
	}

	my $sini2 = $siniq * $siniq;
	my $f220 = .75 * (1 + 2 * $cosiq + $cosq2);
	my $f221 = 1.5 * $sini2;
	my $f321 = 1.875 * $siniq * (1 - 2 * $cosiq - 3 * $cosq2);
	my $f322 = - 1.875 * $siniq * (1 + 2 * $cosiq - 3 * $cosq2);
	my $f441 = 35 * $sini2 * $f220;
	my $f442 = 39.3750 * $sini2 * $sini2;
	my $f522 = 9.84375 * $siniq * ($sini2 * (1 - 2 * $cosiq - 5 * $cosq2) +
	    .33333333 * ( - 2 + 4 * $cosiq + 6 * $cosq2));
	my $f523 = $siniq * (4.92187512 * $sini2 * ( - 2 - 4 * $cosiq +
		10 * $cosq2) + 6.56250012 * (1 + 2 * $cosiq - 3 * $cosq2));
	my $f542 = 29.53125 * $siniq * (2 - 8 * $cosiq + $cosq2 * ( - 12 +
		8 * $cosiq + 10 * $cosq2));
	my $f543 = 29.53125 * $siniq * ( - 2 - 8 * $cosiq + $cosq2 * (12 +
		8 * $cosiq - 10 * $cosq2));
	my $xno2 = $xnq * $xnq;
	my $ainv2 = $aqnv * $aqnv;
	my $temp1 = 3 * $xno2 * $ainv2;
	my $temp = $temp1 * DS_ROOT22;
	$d2201 = $temp * $f220 * $g201;
	$d2211 = $temp * $f221 * $g211;
	$temp1 = $temp1 * $aqnv;
	$temp = $temp1 * DS_ROOT32;
	$d3210 = $temp * $f321 * $g310;
	$d3222 = $temp * $f322 * $g322;
	$temp1 = $temp1 * $aqnv;
	$temp = 2 * $temp1 * DS_ROOT44;
	$d4410 = $temp * $f441 * $g410;
	$d4422 = $temp * $f442 * $g422;
	$temp1 = $temp1 * $aqnv;
	$temp = $temp1 * DS_ROOT52;
	$d5220 = $temp * $f522 * $g520;
	$d5232 = $temp * $f523 * $g532;
	$temp = 2 * $temp1 * DS_ROOT54;
	$d5421 = $temp * $f542 * $g521;
	$d5433 = $temp * $f543 * $g533;
	$xlamo = $xmao + $self->{ascendingnode} + $self->{ascendingnode} -
	    $thgr - $thgr;
	$bfact = $xlldot + $xnodot + $xnodot - DS_THDT - DS_THDT;
	$bfact = $bfact + $ssl + $ssh + $ssh;
    }

#	$bfact won't be defined unless we're a 12- or 24-hour orbit.
    my $xfact;
    defined $bfact and $xfact = $bfact - $xnq;
#C
#C INITIALIZE INTEGRATOR
#C
    my $xli = $xlamo;
    my $xni = $xnq;
    my $atime = 0;
    my $stepp = 720;
    my $stepn = -720;
    my $step2 = 259200;

    $self->{debug} and do {
	local $Data::Dumper::Terse = 1;
	print <<eod;
Debug _dpinit -
    atime = @{[defined $atime ? $atime : q{undef}]}
    cosiq = @{[defined $cosiq ? $cosiq : q{undef}]}
    d2201 = @{[defined $d2201 ? $d2201 : q{undef}]}
    d2211 = @{[defined $d2211 ? $d2211 : q{undef}]}
    d3210 = @{[defined $d3210 ? $d3210 : q{undef}]}
    d3222 = @{[defined $d3222 ? $d3222 : q{undef}]}
    d4410 = @{[defined $d4410 ? $d4410 : q{undef}]}
    d4422 = @{[defined $d4422 ? $d4422 : q{undef}]}
    d5220 = @{[defined $d5220 ? $d5220 : q{undef}]}
    d5232 = @{[defined $d5232 ? $d5232 : q{undef}]}
    d5421 = @{[defined $d5421 ? $d5421 : q{undef}]}
    d5433 = @{[defined $d5433 ? $d5433 : q{undef}]}
    del1  = @{[defined $del1 ? $del1 : q{undef}]}
    del2  = @{[defined $del2 ? $del2 : q{undef}]}
    del3  = @{[defined $del3 ? $del3 : q{undef}]}
    e3    = @{[defined $e3 ? $e3 : q{undef}]}
    ee2   = @{[defined $ee2 ? $ee2 : q{undef}]}
    fasx2 = @{[defined $fasx2 ? $fasx2 : q{undef}]}
    fasx4 = @{[defined $fasx4 ? $fasx4 : q{undef}]}
    fasx6 = @{[defined $fasx6 ? $fasx6 : q{undef}]}
    iresfl = @{[defined $iresfl ? $iresfl : q{undef}]}
    isynfl = @{[defined $isynfl ? $isynfl : q{undef}]}
    omgdt = @{[defined $omgdt ? $omgdt : q{undef}]}
    se2   = @{[defined $se2 ? $se2 : q{undef}]}
    se3   = @{[defined $se3 ? $se3 : q{undef}]}
    sgh2  = @{[defined $sgh2 ? $sgh2 : q{undef}]}
    sgh3  = @{[defined $sgh3 ? $sgh3 : q{undef}]}
    sgh4  = @{[defined $sgh4 ? $sgh4 : q{undef}]}
    sh2   = @{[defined $sh2 ? $sh2 : q{undef}]}
    sh3   = @{[defined $sh3 ? $sh3 : q{undef}]}
    si2   = @{[defined $si2 ? $si2 : q{undef}]}
    si3   = @{[defined $si3 ? $si3 : q{undef}]}
    siniq = @{[defined $siniq ? $siniq : q{undef}]}
    sl2   = @{[defined $sl2 ? $sl2 : q{undef}]}
    sl3   = @{[defined $sl3 ? $sl3 : q{undef}]}
    sl4   = @{[defined $sl4 ? $sl4 : q{undef}]}
    sse   = @{[defined $sse ? $sse : q{undef}]}
    ssg   = @{[defined $ssg ? $ssg : q{undef}]}  << 9.4652e-09 in test_sgp-c-lib
    ssh   = @{[defined $ssh ? $ssh : q{undef}]}
    ssi   = @{[defined $ssi ? $ssi : q{undef}]}
    ssl   = @{[defined $ssl ? $ssl : q{undef}]}
    step2 = @{[defined $step2 ? $step2 : q{undef}]}
    stepn = @{[defined $stepn ? $stepn : q{undef}]}
    stepp = @{[defined $stepp ? $stepp : q{undef}]}
    thgr  = @{[defined $thgr ? $thgr : q{undef}]}  << 1.26513 in test_sgp-c-lib
    xfact = @{[defined $xfact ? $xfact : q{undef}]}
    xgh2  = @{[defined $xgh2 ? $xgh2 : q{undef}]}
    xgh3  = @{[defined $xgh3 ? $xgh3 : q{undef}]}
    xgh4  = @{[defined $xgh4 ? $xgh4 : q{undef}]}
    xh2   = @{[defined $xh2 ? $xh2 : q{undef}]}
    xh3   = @{[defined $xh3 ? $xh3 : q{undef}]}
    xi2   = @{[defined $xi2 ? $xi2 : q{undef}]}
    xi3   = @{[defined $xi3 ? $xi3 : q{undef}]}
    xl2   = @{[defined $xl2 ? $xl2 : q{undef}]}
    xl3   = @{[defined $xl3 ? $xl3 : q{undef}]}
    xl4   = @{[defined $xl4 ? $xl4 : q{undef}]}
    xlamo = @{[defined $xlamo ? $xlamo : q{undef}]}
    xli   = @{[defined $xli ? $xli : q{undef}]}
    xni   = @{[defined $xni ? $xni : q{undef}]}
    xnq   = @{[defined $xnq ? $xnq : q{undef}]}
    zmol  = @{[defined $zmol ? $zmol : q{undef}]}
    zmos  = @{[defined $zmos ? $zmos : q{undef}]}
eod
    };

    return (
	atime => $atime,
	cosiq => $cosiq,
	d2201 => $d2201,
	d2211 => $d2211,
	d3210 => $d3210,
	d3222 => $d3222,
	d4410 => $d4410,
	d4422 => $d4422,
	d5220 => $d5220,
	d5232 => $d5232,
	d5421 => $d5421,
	d5433 => $d5433,
	del1  => $del1,
	del2  => $del2,
	del3  => $del3,
	e3    => $e3,
	ee2   => $ee2,
	fasx2 => $fasx2,
	fasx4 => $fasx4,
	fasx6 => $fasx6,
	iresfl => $iresfl,
	isynfl => $isynfl,
	omgdt => $omgdt,
	se2   => $se2,
	se3   => $se3,
	sgh2  => $sgh2,
	sgh3  => $sgh3,
	sgh4  => $sgh4,
	sh2   => $sh2,
	sh3   => $sh3,
	si2   => $si2,
	si3   => $si3,
	siniq => $siniq,
	sl2   => $sl2,
	sl3   => $sl3,
	sl4   => $sl4,
	sse   => $sse,
	ssg   => $ssg,
	ssh   => $ssh,
	ssi   => $ssi,
	ssl   => $ssl,
	step2 => $step2,
	stepn => $stepn,
	stepp => $stepp,
	thgr  => $thgr,
	xfact => $xfact,
	xgh2  => $xgh2,
	xgh3  => $xgh3,
	xgh4  => $xgh4,
	xh2   => $xh2,
	xh3   => $xh3,
	xi2   => $xi2,
	xi3   => $xi3,
	xl2   => $xl2,
	xl3   => $xl3,
	xl4   => $xl4,
	xlamo => $xlamo,
	xli   => $xli,
	xni   => $xni,
	xnq   => $xnq,
	zmol  => $zmol,
	zmos  => $zmos,
    );
}

#	_dpsec

#	Compute deep space secular effects.

#	The corresponding FORTRAN was a goodly plate of spaghetti, with
#	a couple chunks of code being executed via assigned GOTOs. Not
#	only that, but most of the arguments get modified, and
#	therefore need to be passed by reference. So the corresponding
#	PERL may not end up corresponding very closely.

#	In fact, at this point in the code the only argument that is
#	NOT modified is T.

sub _dpsec {
    my ($self, @args) = @_;
    my $dpsp = $self->{&TLE_INIT}{TLE_deep};
    my ($xll, $omgasm, $xnodes, $em, $xinc, $xn, $t) = @args;
    my @orig;
    $self->{debug}
	and @orig = map {defined $_ ? $_ : 'undef'}
	    map { SCALAR_REF eq ref $_ ? $$_ : $_} @args;

#* ENTRANCE FOR DEEP SPACE SECULAR EFFECTS

    $$xll = $$xll + $dpsp->{ssl} * $t;
    $$omgasm = $$omgasm + $dpsp->{ssg} * $t;
    $$xnodes = $$xnodes + $dpsp->{ssh} * $t;
    $$em = $self->{eccentricity} + $dpsp->{sse} * $t;
    ($$xinc = $self->{inclination} + $dpsp->{ssi} * $t) < 0 and do {
	$$xinc = - $$xinc;
	$$xnodes = $$xnodes + SGP_PI;
	$$omgasm = $$omgasm - SGP_PI;
    };

    $dpsp->{iresfl} and do {

	my ($delt);
	while (1) {
	    (!$dpsp->{atime} || $t >= 0 && $dpsp->{atime} < 0 ||
		    $t < 0 && $dpsp->{atime} >= 0) and do {

#C
#C EPOCH RESTART
#C

		$delt = $t >= 0 ? $dpsp->{stepp} : $dpsp->{stepn};
		$dpsp->{atime} = 0;
		$dpsp->{xni} = $dpsp->{xnq};
		$dpsp->{xli} = $dpsp->{xlamo};
		last;
	    };
	    abs ($t) >= abs ($dpsp->{atime}) and do {
		$delt = $t > 0 ? $dpsp->{stepp} : $dpsp->{stepn};
		last;
	    };
	    $delt = $t > 0 ? $dpsp->{stepn} : $dpsp->{stepp};
	    $self->_dps_dot ($delt);	# Calc. dot terms and integrate.
	}

	while (abs ($t - $dpsp->{atime}) >= $dpsp->{stepp}) {
	    $self->_dps_dot ($delt);	# Calc. dot terms and integrate.
	}
	my $ft = $t - $dpsp->{atime};
	my ($xldot, $xndot, $xnddt) = $self->_dps_dot ();	# Calc. dot terms.
	$$xn = $dpsp->{xni} + $xndot * $ft + $xnddt * $ft * $ft * 0.5;
	my $xl = $dpsp->{xli} + $xldot * $ft + $xndot * $ft * $ft * 0.5;
	my $temp = - $$xnodes + $dpsp->{thgr} + $t * DS_THDT;
	$$xll = $dpsp->{isynfl}  ? $xl - $$omgasm + $temp : $xl + $temp + $temp;
    };

    $self->{debug} and print <<eod;
Debug _dpsec -
    xll    : $orig[0] -> $$xll
    omgasm : $orig[1] -> $$omgasm
    xnodes : $orig[2] -> $$xnodes
    em     : $orig[3] -> $$em
    xinc   : $orig[4] -> $$xinc
    xn     : $orig[5] -> $$xn
    t      : $t
eod
    return;
}

#	_dps_dot

#	Calculate the dot terms for the secular effects.

#	In the original FORTRAN, this was a chunk of code followed
#	by an assigned GOTO. But here it has transmogrified into a
#	method. If an argument is passed, it is taken to be the delta
#	for an iteration of the integration step, which is done. It
#	returns xldot, xndot, and xnddt

sub _dps_dot {
    my ($self, $delt) = @_;
    my $dpsp = $self->{&TLE_INIT}{TLE_deep};

#C
#C DOT TERMS CALCULATED
#C

# We get here from either:
#   - an explicit GOTO below line 130;
#   - an explicit GOTO below line 160, which is reached from below 110 or 125.
# This is the only reference to line 152.
# XNDOT, XNDDT, and XLDOT come out of this.
#150:
    my ($xndot, $xnddt);
    if ($dpsp->{isynfl}) {
	$xndot = $dpsp->{del1} * sin ($dpsp->{xli} - $dpsp->{fasx2}) +
	    $dpsp->{del2} * sin (2 * ($dpsp->{xli} - $dpsp->{fasx4})) +
	    $dpsp->{del3} * sin (3 * ($dpsp->{xli} - $dpsp->{fasx6}));
	$xnddt = $dpsp->{del1} * cos ($dpsp->{xli} - $dpsp->{fasx2}) +
	    2 * $dpsp->{del2} * cos (2 * ($dpsp->{xli} - $dpsp->{fasx4})) +
	    3 * $dpsp->{del3} * cos (3 * ($dpsp->{xli} - $dpsp->{fasx6}));
    } else {
	my $xomi = $self->{argumentofperigee} +
	    $dpsp->{omgdt} * $dpsp->{atime};
	my $x2omi = $xomi + $xomi;
	my $x2li = $dpsp->{xli} + $dpsp->{xli};
	$xndot = $dpsp->{d2201} * sin ($x2omi + $dpsp->{xli} - DS_G22) +
	    $dpsp->{d2211} * sin ($dpsp->{xli} - DS_G22) +
	    $dpsp->{d3210} * sin ($xomi + $dpsp->{xli} - DS_G32) +
	    $dpsp->{d3222} * sin ( - $xomi + $dpsp->{xli} - DS_G32) +
	    $dpsp->{d4410} * sin ($x2omi + $x2li - DS_G44) +
	    $dpsp->{d4422} * sin ($x2li - DS_G44) +
	    $dpsp->{d5220} * sin ($xomi + $dpsp->{xli} - DS_G52) +
	    $dpsp->{d5232} * sin ( - $xomi + $dpsp->{xli} - DS_G52) +
	    $dpsp->{d5421} * sin ($xomi + $x2li - DS_G54) +
	    $dpsp->{d5433} * sin ( - $xomi + $x2li - DS_G54);
	$xnddt = $dpsp->{d2201} * cos ($x2omi + $dpsp->{xli} - DS_G22) +
	    $dpsp->{d2211} * cos ($dpsp->{xli} - DS_G22) +
	    $dpsp->{d3210} * cos ($xomi + $dpsp->{xli} - DS_G32) +
	    $dpsp->{d3222} * cos ( - $xomi + $dpsp->{xli} - DS_G32) +
	    $dpsp->{d5220} * cos ($xomi + $dpsp->{xli} - DS_G52) +
	    $dpsp->{d5232} * cos ( - $xomi + $dpsp->{xli} - DS_G52) +
	    2 * ($dpsp->{d4410} * cos ($x2omi + $x2li - DS_G44) +
	    $dpsp->{d4422} * cos ($x2li - DS_G44) +
	    $dpsp->{d5421} * cos ($xomi + $x2li - DS_G54) +
	    $dpsp->{d5433} * cos ( - $xomi + $x2li - DS_G54));
    }
    my $xldot = $dpsp->{xni} + $dpsp->{xfact};
    $xnddt = $xnddt * $xldot;

#C
#C INTEGRATOR
#C

    defined $delt and do {
	$dpsp->{xli} = $dpsp->{xli} + $xldot * $delt + $xndot * $dpsp->{step2};
	$dpsp->{xni} = $dpsp->{xni} + $xndot * $delt + $xnddt * $dpsp->{step2};
	$dpsp->{atime} = $dpsp->{atime} + $delt;
    };

    return ($xldot, $xndot, $xnddt);
}

#	_dpper

#	Calculate solar/lunar periodics.

#	Note that T must also be passed.

#	Note also that EM, XINC, OMGASM, XNODES, and XLL must be passed
#	by reference, since they get modified. Sigh.

sub _dpper {
    my ($self, @args) = @_;
    my $dpsp = $self->{&TLE_INIT}{TLE_deep};
    my ($em, $xinc, $omgasm, $xnodes, $xll, $t) = @args;
    my @orig;
    $self->{debug}
	and @orig = map {defined $_ ? $_ : 'undef'}
	    map { SCALAR_REF eq ref $_ ? $$_ : $_} @args;

#C
#C ENTRANCES FOR LUNAR-SOLAR PERIODICS
#C
#C
#ENTRY DPPER(EM,XINC,OMGASM,XNODES,XLL)

    my $sinis = sin ($$xinc);
    my $cosis = cos ($$xinc);

# The following is an optimization that
# skips a bunch of calculations if the
# current time is within 30 (minutes) of
# the previous.
# This is the only reference to line 210

    unless (defined $dpsp->{savtsn} && abs ($dpsp->{savtsn} - $t) < 30) {
	$dpsp->{savtsn} = $t;
	my $zm = $dpsp->{zmos} + DS_ZNS * $t;
	my $zf = $zm + 2 * DS_ZES * sin ($zm);
	my $sinzf = sin ($zf);
	my $f2 = .5 * $sinzf * $sinzf - .25;
	my $f3 = - .5 * $sinzf * cos ($zf);
	my $ses = $dpsp->{se2} * $f2 + $dpsp->{se3} * $f3;
	my $sis = $dpsp->{si2} * $f2 + $dpsp->{si3} * $f3;
	my $sls = $dpsp->{sl2} * $f2 + $dpsp->{sl3} * $f3 +
	    $dpsp->{sl4} * $sinzf;
	$dpsp->{sghs} = $dpsp->{sgh2} * $f2 + $dpsp->{sgh3} * $f3 +
	    $dpsp->{sgh4} * $sinzf;
	$dpsp->{shs} = $dpsp->{sh2} * $f2 + $dpsp->{sh3} * $f3;
	$zm = $dpsp->{zmol} + DS_ZNL * $t;
	$zf = $zm + 2 * DS_ZEL * sin ($zm);
	$sinzf = sin ($zf);
	$f2 = .5 * $sinzf * $sinzf - .25;
	$f3 = - .5 * $sinzf * cos ($zf);
	my $sel = $dpsp->{ee2} * $f2 + $dpsp->{e3} * $f3;
	my $sil = $dpsp->{xi2} * $f2 + $dpsp->{xi3} * $f3;
	my $sll = $dpsp->{xl2} * $f2 + $dpsp->{xl3} * $f3 + $dpsp->{xl4} * $sinzf;
	$dpsp->{sghl} = $dpsp->{xgh2} * $f2 + $dpsp->{xgh3} * $f3 + $dpsp->{xgh4} * $sinzf;
	$dpsp->{shl} = $dpsp->{xh2} * $f2 + $dpsp->{xh3} * $f3;
	$dpsp->{pe} = $ses + $sel;
	$dpsp->{pinc} = $sis + $sil;
	$dpsp->{pl} = $sls + $sll;
    }

    my $pgh = $dpsp->{sghs} + $dpsp->{sghl};
    my $ph = $dpsp->{shs} + $dpsp->{shl};
    $$xinc = $$xinc + $dpsp->{pinc};
    $$em = $$em + $dpsp->{pe};

    if ($self->{inclination} >= .2) {

#C
#C APPLY PERIODICS DIRECTLY
#C
#218:

	my $ph = $ph / $dpsp->{siniq};
	my $pgh = $pgh - $dpsp->{cosiq} * $ph;
	$$omgasm = $$omgasm + $pgh;
	$$xnodes = $$xnodes + $ph;
	$$xll = $$xll + $dpsp->{pl};
    } else {

#C
#C APPLY PERIODICS WITH LYDDANE MODIFICATION
#C
#220:
	my $sinok = sin ($$xnodes);
	my $cosok = cos ($$xnodes);
	my $alfdp = $sinis * $sinok;
	my $betdp = $sinis * $cosok;
	my $dalf = $ph * $cosok + $dpsp->{pinc} * $cosis * $sinok;
	my $dbet = - $ph * $sinok + $dpsp->{pinc} * $cosis * $cosok;
	$alfdp = $alfdp + $dalf;
	$betdp = $betdp + $dbet;
	my $xls = $$xll + $$omgasm + $cosis * $$xnodes;
	my $dls = $dpsp->{pl} + $pgh - $dpsp->{pinc} * $$xnodes * $sinis;
	$xls = $xls + $dls;
	$$xnodes = _actan ($alfdp,$betdp);
	$$xll = $$xll + $dpsp->{pl};
	$$omgasm = $xls - $$xll - cos ($$xinc) * $$xnodes;
    }

    $self->{debug} and print <<eod;
Debug _dpper -
    em     : $orig[0] -> $$em
    xinc   : $orig[1] -> $$xinc
    omgasm : $orig[2] -> $$omgasm
    xnodes : $orig[3] -> $$xnodes
    xll    : $orig[4] -> $$xll
    t      : $t
eod

    return;
}

#######################################################################

#	All "Revisiting Spacetrack Report #3" code

=item $tle = $tle->sgp4r($time)

This method calculates the position of the body described by the TLE
object at the given time, using the revised SGP4 model. The universal
time of the object is set to $time, and the 'equinox_dynamical'
attribute is set to the current value of the 'epoch_dynamical'
attribute.

The result is the original object reference. See the L</DESCRIPTION>
heading above for how to retrieve the coordinates you just calculated.

The algorithm for this model comes from "Revisiting Spacetrack Report
Number 3" (see L<ACKNOWLEDGMENTS|/ACKNOWLEDGMENTS>). That report
considers the algorithm to be a correction and extension of SGP4
(merging it with SDP4), and simply calls the algorithm SGP4. I have
appended the "r" (for 'revised' or 'revisited', take your pick) because
I have preserved the original algorithm as well.

B<Note well> that this algorithm depends on the setting of the
'gravconst_r' attribute. The default setting of that attribute in this
module is 84, but the test data that comes with "Revisiting Spacetrack
Report #3" uses 72.

This algorithm is also (currently) the only one that returns a useful
value in the model_error attribute, as follows:

 0 = success
 1 = mean eccentricity < 0 or > 1, or a < .95
 2 = mean motion < 0.0
 3 = instantaneous eccentricity < 0 or > 1
 4 = semi-latus rectum < 0
 5 = epoch elements are sub-orbital
 6 = satellite has decayed

These errors are dualvars if your Scalar::Util supports these. That is,
they are interpreted as numbers in numeric context and the
corresponding string in string context. The string is generally the
explanation, except for 0, which is '' in string context. If your
Scalar::Util does not support dualvar, the numeric value is returned.

Currently, errors 1 through 4 cause an explicit exception to be thrown
after setting the model_error attribute. Exceptions will also be thrown
if the TLE eccentricity is negative or greater than one, or the TLE mean
motion is negative.

Errors 5 and 6 look more like informational errors to me. Error 5
indicates that the perigee is less than the radius of the earth. This
could very well happen if the TLE represents a coasting arc of a
spacecraft being launched or preparing for re-entry. Error 6 means the
actual computed position was underground. Maybe this should be an
exception, though I have never needed this kind of exception previously.

B<Note> that this first release of the 'Revisiting Spacetrack Report #3'
functionality should be considered alpha code. That is to say, I may
need to change the way it behaves, especially in the matter of what is
an exception and what is not.

=cut

#	What follows (down to, but not including, the 'end sgp4unit.for'
#	comment) is the Fortran code from sgp4unit.for, translated into
#	Perl by the custom for2pl script, with conversion specification
#	sgp4unit.spec. No hand-edits have been applied. The preferred
#	way to modify this code is to enhance for2pl (which is _not_
#	included in the CPAN kit) or to modify sgp4unit.for (ditto),
#	since that way further modifications can be easily incorporated
#	into this module.
#
#	Comments in the included file are those from the original
#	Fortran unless preceded by '>>>>trw'. The latter are comments
#	introduced by the conversion program to remove unwanted Fortran.
#
#	IMPLEMENTATION NOTES:
#
#	The original Space Track Report Number 3 code used a custom
#	function called FMOD2P to reduce an angle to the range 0 <=
#	angle < 2*PI. This is translated to Astro::Coord::ECI::Utils
#	function mod2pi. But the Revisiting Spacetrack Report #3 code
#	used the Fortran intrinsic function DMOD, which produces
#	negative results for a negative divisor. So instead of using
#	mod2pi, sgp4r() and related code use the POSIX fmod function,
#	which has the same behaviour.
#
#	Similarly, the original code used a custom function ACTAN to
#	produce an arc in the range 0 <= arc < 2*PI from its two
#	arguments and the single-argument ATAN intrinsic. The
#	translation into Perl ended up with an _actan function at that
#	point. But the revised code simply uses atan2.
#
#	The included file processed from sgp4unit.for begins here.

use constant SGP4R_ERROR_0 => dualvar (0, '');  # guaranteed false
use constant SGP4R_ERROR_MEAN_ECCEN =>
    'Sgp4r 1: Mean eccentricity < 0 or > 1, or a < .95';
use constant SGP4R_ERROR_1 => dualvar (1, SGP4R_ERROR_MEAN_ECCEN);
use constant SGP4R_ERROR_MEAN_MOTION =>
    'Sgp4r 2: Mean motion < 0.0';
use constant SGP4R_ERROR_2 => dualvar (2, SGP4R_ERROR_MEAN_MOTION);
use constant SGP4R_ERROR_INST_ECCEN =>
    'Sgp4r 3: Instantaneous eccentricity < 0 or > 1';
use constant SGP4R_ERROR_3 => dualvar (3, SGP4R_ERROR_INST_ECCEN);
use constant SGP4R_ERROR_LATUSRECTUM =>
    'Sgp4r 4: Semi-latus rectum < 0';
use constant SGP4R_ERROR_4 => dualvar (4, SGP4R_ERROR_LATUSRECTUM);
use constant SGP4R_ERROR_5 => dualvar (5,
    'Sgp4r 5: Epoch elements are sub-orbital');
use constant SGP4R_ERROR_6 => dualvar (6,
    'Sgp4r 6: Satellite has decayed');

#*   -------------------------------------------------------------------
#*
#*                               sgp4unit.for
#*
#*    this file contains the sgp4 procedures for analytical propagation
#*    of a satellite. the code was originally released in the 1980 and 1986
#*    spacetrack papers. a detailed discussion of the theory and history
#*    may be found in the 2006 aiaa paper by vallado, crawford, hujsak,
#*    and kelso.
#*
#*                            companion code for
#*               fundamentals of astrodynamics and applications
#*                                    2007
#*                              by david vallado
#*
#*       (w) 719-573-2600, email dvallado@agi.com
#*
#*    current :
#*               2 apr 07  david vallado
#*                           misc fixes for constants
#*    changes :
#*              14 aug 06  david vallado
#*                           chg lyddane choice back to strn3, constants,
#*                           separate debug and writes, misc doc
#*              26 jul 05  david vallado
#*                           fixes for paper
#*                           note that each fix is preceded by a
#*                           comment with "sgp4fix" and an explanation of
#*                           what was changed
#*              10 aug 04  david vallado
#*                           2nd printing baseline working
#*              14 may 01  david vallado
#*                           2nd edition baseline
#*                     80  norad
#*                           original baseline
#*
#*     *****************************************************************
#*  Files         :
#*    Unit 14     - sgp4test.dbg    debug output file

#* -----------------------------------------------------------------------------
#*
#*                           SUBROUTINE DPPER
#*
#*  This Subroutine provides deep space long period periodic contributions
#*    to the mean elements.  by design, these periodics are zero at epoch.
#*    this used to be dscom which included initialization, but it's really a
#*    recurring function.
#*
#*  author        : david vallado                  719-573-2600   28 jun 2005
#*
#*  inputs        :
#*    e3          -
#*    ee2         -
#*    peo         -
#*    pgho        -
#*    pho         -
#*    pinco       -
#*    plo         -
#*    se2 , se3 , Sgh2, Sgh3, Sgh4, Sh2, Sh3, Si2, Si3, Sl2, Sl3, Sl4 -
#*    t           -
#*    xh2, xh3, xi2, xi3, xl2, xl3, xl4 -
#*    zmol        -
#*    zmos        -
#*    ep          - eccentricity                           0.0 - 1.0
#*    inclo       - inclination - needed for lyddane modification
#*    nodep       - right ascension of ascending node
#*    argpp       - argument of perigee
#*    mp          - mean anomaly
#*
#*  outputs       :
#*    ep          - eccentricity                           0.0 - 1.0
#*    inclp       - inclination
#*    nodep       - right ascension of ascending node
#*    argpp       - argument of perigee
#*    mp          - mean anomaly
#*
#*  locals        :
#*    alfdp       -
#*    betdp       -
#*    cosip  , sinip  , cosop  , sinop  ,
#*    dalf        -
#*    dbet        -
#*    dls         -
#*    f2, f3      -
#*    pe          -
#*    pgh         -
#*    ph          -
#*    pinc        -
#*    pl          -
#*    sel   , ses   , sghl  , sghs  , shl   , shs   , sil   , sinzf , sis   ,
#*    sll   , sls
#*    xls         -
#*    xnoh        -
#*    zf          -
#*    zm          -
#*
#*  coupling      :
#*    none.
#*
#*  references    :
#*    hoots, roehrich, norad spacetrack report #3 1980
#*    hoots, norad spacetrack report #6 1986
#*    hoots, schumacher and glover 2004
#*    vallado, crawford, hujsak, kelso  2006
#*------------------------------------------------------------------------------

sub _r_dpper {
    my ($self, $t, $eccp, $inclp, $nodep, $argpp, $mp) = @_;
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r}
        or confess "Programming error - Sgp4r not initialized";

#* -------------------------- Local Variables --------------------------
    my ($alfdp, $betdp, $cosip, $cosop, $dalf, $dbet, $dls, $f2, $f3,
        $pe, $pgh, $ph, $pinc, $pl, $sel, $ses, $sghl, $sghs, $shl,
        $shs, $sil, $sinip, $sinop, $sinzf, $sis, $sll, $sls, $xls,
        $xnoh, $zf, $zm);
    my ($zel, $zes, $znl, $zns);
#>>>>trw	INCLUDE 'ASTMATH.CMN'

#* ----------------------------- Constants -----------------------------
    $zes= 0.01675;
    $zel= 0.0549;
    $zns= 1.19459e-05;

    $znl= 0.00015835218;
#* ------------------- CALCULATE TIME VARYING PERIODICS ----------------

    $zm= $parm->{zmos}+ $zns*$t;
    if ($parm->{init}) {
        $zm= $parm->{zmos}
    }
    $zf= $zm+ 2*$zes*sin($zm);
    $sinzf= sin($zf);
    $f2=  0.5*$sinzf*$sinzf- 0.25;
    $f3= -0.5*$sinzf*cos($zf);
    $ses= $parm->{se2}*$f2+ $parm->{se3}*$f3;
    $sis= $parm->{si2}*$f2+ $parm->{si3}*$f3;
    $sls= $parm->{sl2}*$f2+ $parm->{sl3}*$f3+ $parm->{sl4}*$sinzf;
    $sghs= $parm->{sgh2}*$f2+ $parm->{sgh3}*$f3+ $parm->{sgh4}*$sinzf;
    $shs= $parm->{sh2}*$f2+ $parm->{sh3}*$f3;

    $zm= $parm->{zmol}+ $znl*$t;
    if ($parm->{init}) {
        $zm= $parm->{zmol}
    }
    $zf= $zm+ 2*$zel*sin($zm);
    $sinzf= sin($zf);
    $f2=  0.5*$sinzf*$sinzf- 0.25;
    $f3= -0.5*$sinzf*cos($zf);
    $sel= $parm->{ee2}*$f2+ $parm->{e3}*$f3;
    $sil= $parm->{xi2}*$f2+ $parm->{xi3}*$f3;
    $sll= $parm->{xl2}*$f2+ $parm->{xl3}*$f3+ $parm->{xl4}*$sinzf;
    $sghl= $parm->{xgh2}*$f2+ $parm->{xgh3}*$f3+ $parm->{xgh4}*$sinzf;
    $shl= $parm->{xh2}*$f2+ $parm->{xh3}*$f3;
    $pe= $ses+ $sel;
    $pinc= $sis+ $sil;
    $pl= $sls+ $sll;
    $pgh= $sghs+ $sghl;

    $ph= $shs+ $shl;
    if ( !  $parm->{init}) {
        $pe= $pe- $parm->{peo};
        $pinc= $pinc- $parm->{pinco};
        $pl= $pl- $parm->{plo};
        $pgh= $pgh- $parm->{pgho};
        $ph= $ph- $parm->{pho};
        $$inclp= $$inclp+ $pinc;
        $$eccp= $$eccp+ $pe;
        $sinip= sin($$inclp);

        $cosip= cos($$inclp);
#* ------------------------- APPLY PERIODICS DIRECTLY ------------------
#c    sgp4fix for lyddane choice
#c    strn3 used original inclination - this is technically feasible
#c    gsfc used perturbed inclination - also technically feasible
#c    probably best to readjust the 0.2 limit value and limit discontinuity
#c    0.2 rad = 11.45916 deg
#c    use next line for original strn3 approach and original inclination
#c            IF (inclo.ge.0.2D0) THEN
#c    use next line for gsfc version and perturbed inclination

        if ($$inclp >= 0.2) {
            $ph= $ph/$sinip;
            $pgh= $pgh- $cosip*$ph;
            $$argpp= $$argpp+ $pgh;
            $$nodep= $$nodep+ $ph;
            $$mp= $$mp+ $pl;

        } else {
#* ----------------- APPLY PERIODICS WITH LYDDANE MODIFICATION ---------
            $sinop= sin($$nodep);
            $cosop= cos($$nodep);
            $alfdp= $sinip*$sinop;
            $betdp= $sinip*$cosop;
            $dalf=  $ph*$cosop+ $pinc*$cosip*$sinop;
            $dbet= -$ph*$sinop+ $pinc*$cosip*$cosop;
            $alfdp= $alfdp+ $dalf;
            $betdp= $betdp+ $dbet;
            $$nodep= fmod($$nodep, &SGP_TWOPI);
            $xls= $$mp+ $$argpp+ $cosip*$$nodep;
            $dls= $pl+ $pgh- $pinc*$$nodep*$sinip;
            $xls= $xls+ $dls;
            $xnoh= $$nodep;
            $$nodep= atan2($alfdp, $betdp);
            if (abs($xnoh-$$nodep)  >  &SGP_PI) {
                if ($$nodep <  $xnoh) {
                    $$nodep= $$nodep+&SGP_TWOPI;
                } else {
                    $$nodep= $$nodep-&SGP_TWOPI;
                }
            }
            $$mp= $$mp+ $pl;
            $$argpp=  $xls- $$mp- $cosip*$$nodep;
        }

    }
#c        INCLUDE 'debug1.for'

    return;
}

#* -----------------------------------------------------------------------------
#*
#*                           SUBROUTINE DSCOM
#*
#*  This Subroutine provides deep space common items used by both the secular
#*    and periodics subroutines.  input is provided as shown. this routine
#*    used to be called dpper, but the functions inside weren't well organized.
#*
#*  author        : david vallado                  719-573-2600   28 jun 2005
#*
#*  inputs        :
#*    epoch       -
#*    ep          - eccentricity
#*    argpp       - argument of perigee
#*    tc          -
#*    inclp       - inclination
#*    nodep      - right ascension of ascending node
#*    np          - mean motion
#*
#*  outputs       :
#*    sinim  , cosim  , sinomm , cosomm , snodm  , cnodm
#*    day         -
#*    e3          -
#*    ee2         -
#*    em          - eccentricity
#*    emsq        - eccentricity squared
#*    gam         -
#*    peo         -
#*    pgho        -
#*    pho         -
#*    pinco       -
#*    plo         -
#*    rtemsq      -
#*    se2, se3         -
#*    sgh2, sgh3, sgh4        -
#*    sh2, sh3, si2, si3, sl2, sl3, sl4         -
#*    s1, s2, s3, s4, s5, s6, s7          -
#*    ss1, ss2, ss3, ss4, ss5, ss6, ss7, sz1, sz2, sz3         -
#*    sz11, sz12, sz13, sz21, sz22, sz23, sz31, sz32, sz33        -
#*    xgh2, xgh3, xgh4, xh2, xh3, xi2, xi3, xl2, xl3, xl4         -
#*    nm          - mean motion
#*    z1, z2, z3, z11, z12, z13, z21, z22, z23, z31, z32, z33         -
#*    zmol        -
#*    zmos        -
#*
#*  locals        :
#*    a1, a2, a3, a4, a5, a6, a7, a8, a9, a10         -
#*    betasq      -
#*    cc          -
#*    ctem, stem        -
#*    x1, x2, x3, x4, x5, x6, x7, x8          -
#*    xnodce      -
#*    xnoi        -
#*    zcosg  , zsing  , zcosgl , zsingl , zcosh  , zsinh  , zcoshl , zsinhl ,
#*    zcosi  , zsini  , zcosil , zsinil ,
#*    zx          -
#*    zy          -
#*
#*  coupling      :
#*    none.
#*
#*  references    :
#*    hoots, roehrich, norad spacetrack report #3 1980
#*    hoots, norad spacetrack report #6 1986
#*    hoots, schumacher and glover 2004
#*    vallado, crawford, hujsak, kelso  2006
#*------------------------------------------------------------------------------

sub _r_dscom {
    my ($self, $tc) = @_;
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r}
        or confess "Programming error - Sgp4r not initialized";
    my $init = $parm->{init}
        or confess "Programming error - Sgp4r initialization not in progress";

#* -------------------------- Local Variables --------------------------
    my ($c1ss, $c1l, $zcosis, $zsinis, $zsings, $zcosgs, $zes, $zel);

    my ($a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10, $betasq, $cc,
        $ctem, $stem, $x1, $x2, $x3, $x4, $x5, $x6, $x7, $x8, $xnodce,
        $xnoi, $zcosg, $zcosgl, $zcosh, $zcoshl, $zcosi, $zcosil,
        $zsing, $zsingl, $zsinh, $zsinhl, $zsini, $zsinil, $zx, $zy);
#>>>>trw	INCLUDE 'ASTMATH.CMN'

#* ------------------------------ Constants ----------------------------
    $zes=  0.01675;
    $zel=  0.0549;
    $c1ss=  2.9864797e-06;
    $c1l=  4.7968065e-07;
    $zsinis=  0.39785416;
    $zcosis=  0.91744867;
    $zcosgs=  0.1945905;

    $zsings= -0.98088458;
#* ----------------- DEEP SPACE PERIODICS INITIALIZATION ---------------
    $init->{xn}= $parm->{meanmotion};
    $init->{eccm}= $parm->{eccentricity};
    $init->{snodm}= sin($parm->{ascendingnode});
    $init->{cnodm}= cos($parm->{ascendingnode});
    $init->{sinomm}= sin($parm->{argumentofperigee});
    $init->{cosomm}= cos($parm->{argumentofperigee});
    $init->{sinim}= sin($parm->{inclination});
    $init->{cosim}= cos($parm->{inclination});
    $init->{emsq}= $init->{eccm}*$init->{eccm};
    $betasq= 1-$init->{emsq};

    $init->{rtemsq}= sqrt($betasq);
#* --------------------- INITIALIZE LUNAR SOLAR TERMS ------------------
    $parm->{peo}= 0;
    $parm->{pinco}= 0;
    $parm->{plo}= 0;
    $parm->{pgho}= 0;
    $parm->{pho}= 0;
    $init->{day}= $self->{ds50}+ 18261.5 + $tc/1440;
    $xnodce= fmod(4.523602 - 0.00092422029*$init->{day}, &SGP_TWOPI);
    $stem= sin($xnodce);
    $ctem= cos($xnodce);
    $zcosil= 0.91375164 - 0.03568096*$ctem;
    $zsinil= sqrt(1 - $zcosil*$zcosil);
    $zsinhl= 0.089683511*$stem/ $zsinil;
    $zcoshl= sqrt(1 - $zsinhl*$zsinhl);
    $init->{gam}= 5.8351514 + 0.001944368*$init->{day};
    $zx= 0.39785416*$stem/$zsinil;
    $zy= $zcoshl*$ctem+ 0.91744867*$zsinhl*$stem;
    $zx= atan2($zx, $zy);
    $zx= $init->{gam}+ $zx- $xnodce;
    $zcosgl= cos($zx);

    $zsingl= sin($zx);
#* ---------------------------- DO SOLAR TERMS -------------------------
    $zcosg= $zcosgs;
    $zsing= $zsings;
    $zcosi= $zcosis;
    $zsini= $zsinis;
    $zcosh= $init->{cnodm};
    $zsinh= $init->{snodm};
    $cc= $c1ss;

    $xnoi= 1 / $init->{xn};
    foreach my $lsflg (1 .. 2) {
        $a1=   $zcosg*$zcosh+ $zsing*$zcosi*$zsinh;
        $a3=  -$zsing*$zcosh+ $zcosg*$zcosi*$zsinh;
        $a7=  -$zcosg*$zsinh+ $zsing*$zcosi*$zcosh;
        $a8=   $zsing*$zsini;
        $a9=   $zsing*$zsinh+ $zcosg*$zcosi*$zcosh;
        $a10=   $zcosg*$zsini;
        $a2=   $init->{cosim}*$a7+ $init->{sinim}*$a8;
        $a4=   $init->{cosim}*$a9+ $init->{sinim}*$a10;
        $a5=  -$init->{sinim}*$a7+ $init->{cosim}*$a8;

        $a6=  -$init->{sinim}*$a9+ $init->{cosim}*$a10;
        $x1=  $a1*$init->{cosomm}+ $a2*$init->{sinomm};
        $x2=  $a3*$init->{cosomm}+ $a4*$init->{sinomm};
        $x3= -$a1*$init->{sinomm}+ $a2*$init->{cosomm};
        $x4= -$a3*$init->{sinomm}+ $a4*$init->{cosomm};
        $x5=  $a5*$init->{sinomm};
        $x6=  $a6*$init->{sinomm};
        $x7=  $a5*$init->{cosomm};

        $x8=  $a6*$init->{cosomm};
        $init->{z31}= 12*$x1*$x1- 3*$x3*$x3;
        $init->{z32}= 24*$x1*$x2- 6*$x3*$x4;
        $init->{z33}= 12*$x2*$x2- 3*$x4*$x4;
        $init->{z1}=  3* ($a1*$a1+ $a2*$a2) +
            $init->{z31}*$init->{emsq};
        $init->{z2}=  6* ($a1*$a3+ $a2*$a4) +
            $init->{z32}*$init->{emsq};
        $init->{z3}=  3* ($a3*$a3+ $a4*$a4) +
            $init->{z33}*$init->{emsq};
        $init->{z11}= -6*$a1*$a5+ $init->{emsq}*
            (-24*$x1*$x7-6*$x3*$x5);
        $init->{z12}= -6* ($a1*$a6+ $a3*$a5) + $init->{emsq}* (
            -24*($x2*$x7+$x1*$x8) - 6*($x3*$x6+$x4*$x5) );
        $init->{z13}= -6*$a3*$a6+ $init->{emsq}*(-24*$x2*$x8-
            6*$x4*$x6);
        $init->{z21}=  6*$a2*$a5+ $init->{emsq}*(24*$x1*$x5-6*$x3*$x7);
        $init->{z22}=  6* ($a4*$a5+ $a2*$a6) + $init->{emsq}* ( 
            24*($x2*$x5+$x1*$x6) - 6*($x4*$x7+$x3*$x8) );
        $init->{z23}=  6*$a4*$a6+ $init->{emsq}*(24*$x2*$x6- 6*$x4*$x8);
        $init->{z1}= $init->{z1}+ $init->{z1}+ $betasq*$init->{z31};
        $init->{z2}= $init->{z2}+ $init->{z2}+ $betasq*$init->{z32};
        $init->{z3}= $init->{z3}+ $init->{z3}+ $betasq*$init->{z33};
        $init->{s3}= $cc*$xnoi;
        $init->{s2}= -0.5*$init->{s3}/ $init->{rtemsq};
        $init->{s4}= $init->{s3}*$init->{rtemsq};
        $init->{s1}= -15*$init->{eccm}*$init->{s4};
        $init->{s5}= $x1*$x3+ $x2*$x4;
        $init->{s6}= $x2*$x3+ $x1*$x4;

        $init->{s7}= $x2*$x4- $x1*$x3;
#* ------------------------------ DO LUNAR TERMS -----------------------
        if ($lsflg == 1) {
            $init->{ss1}= $init->{s1};
            $init->{ss2}= $init->{s2};
            $init->{ss3}= $init->{s3};
            $init->{ss4}= $init->{s4};
            $init->{ss5}= $init->{s5};
            $init->{ss6}= $init->{s6};
            $init->{ss7}= $init->{s7};
            $init->{sz1}= $init->{z1};
            $init->{sz2}= $init->{z2};
            $init->{sz3}= $init->{z3};
            $init->{sz11}= $init->{z11};
            $init->{sz12}= $init->{z12};
            $init->{sz13}= $init->{z13};
            $init->{sz21}= $init->{z21};
            $init->{sz22}= $init->{z22};
            $init->{sz23}= $init->{z23};
            $init->{sz31}= $init->{z31};
            $init->{sz32}= $init->{z32};
            $init->{sz33}= $init->{z33};
            $zcosg= $zcosgl;
            $zsing= $zsingl;
            $zcosi= $zcosil;
            $zsini= $zsinil;
            $zcosh= $zcoshl*$init->{cnodm}+$zsinhl*$init->{snodm};
            $zsinh= $init->{snodm}*$zcoshl-$init->{cnodm}*$zsinhl;
            $cc= $c1l;
        }

    }
    $parm->{zmol}= fmod(4.7199672 + 0.2299715*$init->{day}-$init->{gam},
        &SGP_TWOPI);

    $parm->{zmos}= fmod(6.2565837 + 0.017201977*$init->{day},
        &SGP_TWOPI);
#* ---------------------------- DO SOLAR TERMS -------------------------
    $parm->{se2}=   2*$init->{ss1}*$init->{ss6};
    $parm->{se3}=   2*$init->{ss1}*$init->{ss7};
    $parm->{si2}=   2*$init->{ss2}*$init->{sz12};
    $parm->{si3}=   2*$init->{ss2}*($init->{sz13}-$init->{sz11});
    $parm->{sl2}=  -2*$init->{ss3}*$init->{sz2};
    $parm->{sl3}=  -2*$init->{ss3}*($init->{sz3}-$init->{sz1});
    $parm->{sl4}=  -2*$init->{ss3}*(-21-9*$init->{emsq})*$zes;
    $parm->{sgh2}=   2*$init->{ss4}*$init->{sz32};
    $parm->{sgh3}=   2*$init->{ss4}*($init->{sz33}-$init->{sz31});
    $parm->{sgh4}= -18*$init->{ss4}*$zes;
    $parm->{sh2}=  -2*$init->{ss2}*$init->{sz22};

    $parm->{sh3}=  -2*$init->{ss2}*($init->{sz23}-$init->{sz21});
#* ---------------------------- DO LUNAR TERMS -------------------------
    $parm->{ee2}=   2*$init->{s1}*$init->{s6};
    $parm->{e3}=   2*$init->{s1}*$init->{s7};
    $parm->{xi2}=   2*$init->{s2}*$init->{z12};
    $parm->{xi3}=   2*$init->{s2}*($init->{z13}-$init->{z11});
    $parm->{xl2}=  -2*$init->{s3}*$init->{z2};
    $parm->{xl3}=  -2*$init->{s3}*($init->{z3}-$init->{z1});
    $parm->{xl4}=  -2*$init->{s3}*(-21-9*$init->{emsq})*$zel;
    $parm->{xgh2}=   2*$init->{s4}*$init->{z32};
    $parm->{xgh3}=   2*$init->{s4}*($init->{z33}-$init->{z31});
    $parm->{xgh4}= -18*$init->{s4}*$zel;
    $parm->{xh2}=  -2*$init->{s2}*$init->{z22};

    $parm->{xh3}=  -2*$init->{s2}*($init->{z23}-$init->{z21});
#c        INCLUDE 'debug2.for'

    return;
}

#* -----------------------------------------------------------------------------
#*
#*                           SUBROUTINE DSINIT
#*
#*  This Subroutine provides Deep Space contributions to Mean Motion Dot due
#*    to geopotential resonance with half day and one day orbits.
#*
#*  Inputs        :
#*    Cosim, Sinim-
#*    Emsq        - Eccentricity squared
#*    Argpo       - Argument of Perigee
#*    S1, S2, S3, S4, S5      -
#*    Ss1, Ss2, Ss3, Ss4, Ss5 -
#*    Sz1, Sz3, Sz11, Sz13, Sz21, Sz23, Sz31, Sz33 -
#*    T           - Time
#*    Tc          -
#*    GSTo        - Greenwich sidereal time                   rad
#*    Mo          - Mean Anomaly
#*    MDot        - Mean Anomaly dot (rate)
#*    No          - Mean Motion
#*    nodeo       - right ascension of ascending node
#*    nodeDot     - right ascension of ascending node dot (rate)
#*    XPIDOT      -
#*    Z1, Z3, Z11, Z13, Z21, Z23, Z31, Z33 -
#*    Eccm        - Eccentricity
#*    Argpm       - Argument of perigee
#*    Inclm       - Inclination
#*    Mm          - Mean Anomaly
#*    Xn          - Mean Motion
#*    nodem       - right ascension of ascending node
#*
#*  Outputs       :
#*    Eccm        - Eccentricity
#*    Argpm       - Argument of perigee
#*    Inclm       - Inclination
#*    Mm          - Mean Anomaly
#*    Xn          - Mean motion
#*    nodem       - right ascension of ascending node
#*    IRez        - Resonance flags              0-none, 1-One day,  2-Half day
#*    Atime       -
#*    D2201, D2211, D3210, D3222, D4410, D4422, D5220, D5232, D5421, D5433       -
#*    Dedt        -
#*    Didt        -
#*    DMDT        -
#*    DNDT        -
#*    DNODT       -
#*    DOMDT       -
#*    Del1, Del2, Del3 -
#*    Ses  , Sghl , Sghs , Sgs  , Shl  , Shs  , Sis  , Sls
#*    THETA       -
#*    Xfact       -
#*    Xlamo       -
#*    Xli         -
#*    Xni
#*
#*  Locals        :
#*    ainv2       -
#*    aonv        -
#*    cosisq      -
#*    eoc         -
#*    f220, f221, f311, f321, f322, f330, f441, f442, f522, f523, f542, f543        -
#*    g200, g201, g211, g300, g310, g322, g410, g422, g520, g521, g532, g533        -
#*    sini2       -
#*    temp, temp1 -
#*    Theta       -
#*    xno2        -
#*
#*  Coupling      :
#*    getgravconst-
#*
#*  references    :
#*    hoots, roehrich, norad spacetrack report #3 1980
#*    hoots, norad spacetrack report #6 1986
#*    hoots, schumacher and glover 2004
#*    vallado, crawford, hujsak, kelso  2006
#*------------------------------------------------------------------------------

sub _r_dsinit {
    my ($self, $t, $tc) = @_;
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r}
        or confess "Programming error - Sgp4r not initialized";
    my $init = $parm->{init}
        or confess "Programming error - Sgp4r initialization not in progress";

#* -------------------------- Local Variables --------------------------
    my ($ainv2, $aonv, $cosisq, $eoc, $f220, $f221, $f311, $f321, $f322,
        $f330, $f441, $f442, $f522, $f523, $f542, $f543, $g200, $g201,
        $g211, $g300, $g310, $g322, $g410, $g422, $g520, $g521, $g532,
        $g533, $ses, $sgs, $sghl, $sghs, $shs, $shl, $sis, $sini2, $sls,
        $temp, $temp1, $theta, $xno2);

    my ($q22, $q31, $q33, $root22, $root44, $root54, $rptim, $root32,
        $root52, $znl, $zns, $emo, $emsqo);
#>>>>trw	INCLUDE 'ASTMATH.CMN'

    $q22= 1.7891679e-06;
    $q31= 2.1460748e-06;
    $q33= 2.2123015e-07;
    $root22= 1.7891679e-06;
    $root44= 7.3636953e-09;
    $root54= 2.1765803e-09;
    $rptim= 0.0043752690880113;
    $root32= 3.7393792e-07;
    $root52= 1.1428639e-07;
#>>>>trw	X2o3   = 2.0D0 / 3.0D0
    $znl= 0.00015835218;

    $zns= 1.19459e-05;

#>>>>trw	CALL getgravconst( whichconst, tumin, mu, radiusearthkm, xke, j2, j3, j4, j3oj2 )
#* ------------------------ DEEP SPACE INITIALIZATION ------------------
    $parm->{irez}= 0;
    if (($init->{xn} < 0.0052359877) && ($init->{xn} > 0.0034906585)) {
        $parm->{irez}= 1;
    }
    if (($init->{xn} >= 0.00826) && ($init->{xn} <= 0.00924) &&
        ($init->{eccm} >= 0.5)) {
        $parm->{irez}= 2;

    }
#* ---------------------------- DO SOLAR TERMS -------------------------
    $ses=  $init->{ss1}*$zns*$init->{ss5};
    $sis=  $init->{ss2}*$zns*($init->{sz11}+ $init->{sz13});
    $sls= -$zns*$init->{ss3}*($init->{sz1}+ $init->{sz3}- 14 -
        6*$init->{emsq});
    $sghs=  $init->{ss4}*$zns*($init->{sz31}+ $init->{sz33}- 6);
    $shs= -$zns*$init->{ss2}*($init->{sz21}+ $init->{sz23});
#c       sgp4fix for 180 deg incl
    if (($init->{inclm} < 0.052359877) || ($init->{inclm} >
        &SGP_PI-0.052359877)) {
        $shs= 0;
    }
    if ($init->{sinim} != 0) {
        $shs= $shs/$init->{sinim};
    }

    $sgs= $sghs- $init->{cosim}*$shs;
#* ----------------------------- DO LUNAR TERMS ------------------------
    $parm->{dedt}= $ses+ $init->{s1}*$znl*$init->{s5};
    $parm->{didt}= $sis+ $init->{s2}*$znl*($init->{z11}+ $init->{z13});
    $parm->{dmdt}= $sls- $znl*$init->{s3}*($init->{z1}+ $init->{z3}- 14
        - 6*$init->{emsq});
    $sghl= $init->{s4}*$znl*($init->{z31}+ $init->{z33}- 6);
    $shl= -$znl*$init->{s2}*($init->{z21}+ $init->{z23});
#c       sgp4fix for 180 deg incl
    if (($init->{inclm} < 0.052359877) || ($init->{inclm} >
        &SGP_PI-0.052359877)) {
        $shl= 0;
    }
    $parm->{domdt}= $sgs+$sghl;
    $parm->{dnodt}= $shs;
    if ($init->{sinim} !=  0) {
        $parm->{domdt}=
            $parm->{domdt}-$init->{cosim}/$init->{sinim}*$shl;
        $parm->{dnodt}= $parm->{dnodt}+$shl/$init->{sinim};

    }
#* --------------- CALCULATE DEEP SPACE RESONANCE EFFECTS --------------
    $init->{dndt}= 0;
    $theta= fmod($parm->{gsto}+ $tc*$rptim, &SGP_TWOPI);
    $init->{eccm}= $init->{eccm}+ $parm->{dedt}*$t;
    $init->{emsq}= $init->{eccm}**2;
    $init->{inclm}= $init->{inclm}+ $parm->{didt}*$t;
    $init->{argpm}= $init->{argpm}+ $parm->{domdt}*$t;
    $init->{nodem}= $init->{nodem}+ $parm->{dnodt}*$t;
    $init->{mm}= $init->{mm}+ $parm->{dmdt}*$t;
#c   sgp4fix for negative inclinations
#c   the following if statement should be commented out
#c           IF(Inclm .lt. 0.0D0) THEN
#c             Inclm  = -Inclm
#c             Argpm  = Argpm-PI
#c             nodem = nodem+PI
#c           ENDIF

#* ------------------ Initialize the resonance terms -------------------
    if ($parm->{irez} !=  0) {

        $aonv= ($init->{xn}/$parm->{xke})**&SGP_TOTHRD;
#* -------------- GEOPOTENTIAL RESONANCE FOR 12 HOUR ORBITS ------------
        if ($parm->{irez} ==  2) {
            $cosisq= $init->{cosim}*$init->{cosim};
            $emo= $init->{eccm};
            $emsqo= $init->{emsq};
            $init->{eccm}= $parm->{eccentricity};
            $init->{emsq}= $init->{eccsq};
            $eoc= $init->{eccm}*$init->{emsq};
            $g201= -0.306-($init->{eccm}-0.64)*0.44;
            if ($init->{eccm} <= 0.65) {
                $g211=   3.616 -  13.247*$init->{eccm}+ 
                    16.29*$init->{emsq};
                $g310= -19.302 + 117.39*$init->{eccm}-
                    228.419*$init->{emsq}+ 156.591*$eoc;
                $g322= -18.9068+ 109.7927*$init->{eccm}-
                    214.6334*$init->{emsq}+ 146.5816*$eoc;
                $g410= -41.122 + 242.694*$init->{eccm}-
                    471.094*$init->{emsq}+ 313.953*$eoc;
                $g422=-146.407 + 841.88*$init->{eccm}-
                    1629.014*$init->{emsq}+ 1083.435*$eoc;
                $g520=-532.114 + 3017.977*$init->{eccm}-
                    5740.032*$init->{emsq}+ 3708.276*$eoc;
            } else {
                $g211=  -72.099 +  331.819*$init->{eccm}- 
                    508.738*$init->{emsq}+ 266.724*$eoc;
                $g310= -346.844 + 1582.851*$init->{eccm}-
                    2415.925*$init->{emsq}+ 1246.113*$eoc;
                $g322= -342.585 + 1554.908*$init->{eccm}-
                    2366.899*$init->{emsq}+ 1215.972*$eoc;
                $g410=-1052.797 + 4758.686*$init->{eccm}-
                    7193.992*$init->{emsq}+ 3651.957*$eoc;
                $g422=-3581.69 + 16178.11*$init->{eccm}-
                    24462.77*$init->{emsq}+ 12422.52*$eoc;
                if ($init->{eccm} > 0.715) {
                    $g520=-5149.66 +
                        29936.92*$init->{eccm}-54087.36*$init->{emsq}+
                        31324.56*$eoc;
                } else {
                    $g520= 1464.74 -  4664.75*$init->{eccm}+
                        3763.64*$init->{emsq};
                }
            }
            if ($init->{eccm} < 0.7) {
                $g533= -919.2277 +
                    4988.61*$init->{eccm}-9064.77*$init->{emsq}+
                    5542.21*$eoc;
                $g521= -822.71072 +
                    4568.6173*$init->{eccm}-8491.4146*$init->{emsq}+
                    5337.524*$eoc;
                $g532= -853.666 +
                    4690.25*$init->{eccm}-8624.77*$init->{emsq}+
                    5341.4*$eoc;
            } else {
                $g533=-37995.78 +
                    161616.52*$init->{eccm}-229838.2*$init->{emsq}+
                    109377.94*$eoc;
                $g521=-51752.104 +
                    218913.95*$init->{eccm}-309468.16*$init->{emsq}+
                    146349.42*$eoc;
                $g532=-40023.88 +
                    170470.89*$init->{eccm}-242699.48*$init->{emsq}+
                    115605.82*$eoc;
            }
            $sini2=  $init->{sinim}*$init->{sinim};
            $f220=  0.75* (1+2*$init->{cosim}+$cosisq);
            $f221=  1.5*$sini2;
            $f321=  1.875*$init->{sinim}*
                (1-2*$init->{cosim}-3*$cosisq);
            $f322= -1.875*$init->{sinim}*
                (1+2*$init->{cosim}-3*$cosisq);
            $f441= 35*$sini2*$f220;
            $f442= 39.375*$sini2*$sini2;
            $f522=  9.84375*$init->{sinim}* ($sini2*
                (1-2*$init->{cosim}- 5*$cosisq)+0.33333333 *
                (-2+4*$init->{cosim}+ 6*$cosisq) );
            $f523=  $init->{sinim}* (4.92187512*$sini2*
                (-2-4*$init->{cosim}+ 10*$cosisq) + 6.56250012*
                (1+2*$init->{cosim}-3*$cosisq));
            $f542=  29.53125*$init->{sinim}*
                (2-8*$init->{cosim}+$cosisq*
                (-12+8*$init->{cosim}+10*$cosisq) );

            $f543= 29.53125*$init->{sinim}*
                (-2-8*$init->{cosim}+$cosisq*
                (12+8*$init->{cosim}-10*$cosisq) );
            $xno2=  $init->{xn}* $init->{xn};
            $ainv2=  $aonv* $aonv;
            $temp1=  3*$xno2*$ainv2;
            $temp=  $temp1*$root22;
            $parm->{d2201}=  $temp*$f220*$g201;
            $parm->{d2211}=  $temp*$f221*$g211;
            $temp1=  $temp1*$aonv;
            $temp=  $temp1*$root32;
            $parm->{d3210}=  $temp*$f321*$g310;
            $parm->{d3222}=  $temp*$f322*$g322;
            $temp1=  $temp1*$aonv;
            $temp=  2*$temp1*$root44;
            $parm->{d4410}=  $temp*$f441*$g410;
            $parm->{d4422}=  $temp*$f442*$g422;
            $temp1=  $temp1*$aonv;
            $temp=  $temp1*$root52;
            $parm->{d5220}=  $temp*$f522*$g520;
            $parm->{d5232}=  $temp*$f523*$g532;
            $temp=  2*$temp1*$root54;
            $parm->{d5421}=  $temp*$f542*$g521;
            $parm->{d5433}=  $temp*$f543*$g533;
            $parm->{xlamo}= 
                fmod($parm->{meananomaly}+$parm->{ascendingnode}+$parm->{ascendingnode}-$theta-$theta,
                &SGP_TWOPI);

            $parm->{xfact}= $parm->{mdot}+ $parm->{dmdt}+ 2 *
                ($parm->{nodedot}+$parm->{dnodt}-$rptim) -
                $parm->{meanmotion};
            $init->{eccm}= $emo;
            $init->{emsq}= $emsqo;

        }
        if ($parm->{irez} ==  1) {
#* -------------------- SYNCHRONOUS RESONANCE TERMS --------------------
            $g200= 1 + $init->{emsq}* (-2.5+0.8125*$init->{emsq});
            $g310= 1 + 2*$init->{emsq};
            $g300= 1 + $init->{emsq}* (-6+6.60937*$init->{emsq});
            $f220= 0.75 * (1+$init->{cosim}) * (1+$init->{cosim});
            $f311= 0.9375*$init->{sinim}*$init->{sinim}*
                (1+3*$init->{cosim}) - 0.75*(1+$init->{cosim});
            $f330= 1+$init->{cosim};
            $f330= 1.875*$f330*$f330*$f330;
            $parm->{del1}= 3*$init->{xn}*$init->{xn}*$aonv*$aonv;
            $parm->{del2}= 2*$parm->{del1}*$f220*$g200*$q22;
            $parm->{del3}= 3*$parm->{del1}*$f330*$g300*$q33*$aonv;
            $parm->{del1}= $parm->{del1}*$f311*$g310*$q31*$aonv;
            $parm->{xlamo}=
                fmod($parm->{meananomaly}+$parm->{ascendingnode}+$parm->{argumentofperigee}-$theta,
                &SGP_TWOPI);
            $parm->{xfact}= $parm->{mdot}+ $init->{xpidot}- $rptim+
                $parm->{dmdt}+ $parm->{domdt}+ $parm->{dnodt}-
                $parm->{meanmotion};

        }
#* ---------------- FOR SGP4, INITIALIZE THE INTEGRATOR ----------------
        $parm->{xli}= $parm->{xlamo};
        $parm->{xni}= $parm->{meanmotion};
        $parm->{atime}= 0;
        $init->{xn}= $parm->{meanmotion}+ $init->{dndt};

    }
#c        INCLUDE 'debug3.for'

    return;
}

#* -----------------------------------------------------------------------------
#*
#*                           SUBROUTINE DSPACE
#*
#*  This Subroutine provides deep space contributions to mean elements for
#*    perturbing third body.  these effects have been averaged over one
#*    revolution of the sun and moon.  for earth resonance effects, the
#*    effects have been averaged over no revolutions of the satellite.
#*    (mean motion)
#*
#*  author        : david vallado                  719-573-2600   28 jun 2005
#*
#*  inputs        :
#*    d2201, d2211, d3210, d3222, d4410, d4422, d5220, d5232, d5421, d5433       -
#*    dedt        -
#*    del1, del2, del3  -
#*    didt        -
#*    dmdt        -
#*    dnodt       -
#*    domdt       -
#*    irez        - flag for resonance           0-none, 1-one day, 2-half day
#*    argpo       - argument of perigee
#*    argpdot     - argument of perigee dot (rate)
#*    t           - time
#*    tc          -
#*    gsto        - gst
#*    xfact       -
#*    xlamo       -
#*    no          - mean motion
#*    atime       -
#*    em          - eccentricity
#*    ft          -
#*    argpm       - argument of perigee
#*    inclm       - inclination
#*    xli         -
#*    mm          - mean anomaly
#*    xni         - mean motion
#*    nodem       - right ascension of ascending node
#*
#*  outputs       :
#*    atime       -
#*    em          - eccentricity
#*    argpm       - argument of perigee
#*    inclm       - inclination
#*    xli         -
#*    mm          - mean anomaly
#*    xni         -
#*    nodem       - right ascension of ascending node
#*    dndt        -
#*    nm          - mean motion
#*
#*  locals        :
#*    delt        -
#*    ft          -
#*    theta       -
#*    x2li        -
#*    x2omi       -
#*    xl          -
#*    xldot       -
#*    xnddt       -
#*    xndt        -
#*    xomi        -
#*
#*  coupling      :
#*    none        -
#*
#*  references    :
#*    hoots, roehrich, norad spacetrack report #3 1980
#*    hoots, norad spacetrack report #6 1986
#*    hoots, schumacher and glover 2004
#*    vallado, crawford, hujsak, kelso  2006
#*------------------------------------------------------------------------------

sub _r_dspace {
    my ($self, $t, $tc, $atime, $eccm, $argpm, $inclm, $xli, $mm, $xni,
        $nodem, $dndt, $xn) = @_;
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r}
        or confess "Programming error - Sgp4r not initialized";

#* -------------------------- Local Variables --------------------------
    my ($iretn, $iret);
    my ($delt, $ft, $theta, $x2li, $x2omi, $xl, $xldot, $xnddt, $xndt,
        $xomi);

    my ($g22, $g32, $g44, $g52, $g54, $fasx2, $fasx4, $fasx6, $rptim,
        $step2, $stepn, $stepp);
#>>>>trw	INCLUDE 'ASTMATH.CMN'

#* ----------------------------- Constants -----------------------------
    $fasx2= 0.13130908;
    $fasx4= 2.8843198;
    $fasx6= 0.37448087;
    $g22= 5.7686396;
    $g32= 0.95240898;
    $g44= 1.8014998;
    $g52= 1.050833;
    $g54= 4.4108898;
    $rptim= 0.0043752690880113;
    $stepp=    720;
    $stepn=   -720;

    $step2= 259200;
#* --------------- CALCULATE DEEP SPACE RESONANCE EFFECTS --------------
    $$dndt= 0;
    $theta= fmod($parm->{gsto}+ $tc*$rptim, &SGP_TWOPI);

    $$eccm= $$eccm+ $parm->{dedt}*$t;
    $$inclm= $$inclm+ $parm->{didt}*$t;
    $$argpm= $$argpm+ $parm->{domdt}*$t;
    $$nodem= $$nodem+ $parm->{dnodt}*$t;

    $$mm= $$mm+ $parm->{dmdt}*$t;
#c   sgp4fix for negative inclinations
#c   the following if statement should be commented out
#c        IF(Inclm .lt. 0.0D0) THEN
#c            Inclm  = -Inclm
#c            Argpm  = Argpm-PI
#c            nodem = nodem+PI
#c          ENDIF

#c   sgp4fix for propagator problems
#c   the following integration works for negative time steps and periods
#c   the specific changes are unknown because the original code was so convoluted
    $ft= 0;

    $$atime= 0;
    if ($parm->{irez} !=  0) {
#* ----- UPDATE RESONANCES : NUMERICAL (EULER-MACLAURIN) INTEGRATION ---
#* ---------------------------- EPOCH RESTART --------------------------
        if ( ($$atime == 0)   ||  (($t >= 0)  &&  ($$atime < 0))  || 
            (($t < 0)  &&  ($$atime >= 0)) ) {
            if ($t >= 0) {
                $delt= $stepp;
            } else {
                $delt= $stepn;
            }
            $$atime= 0;
            $$xni= $parm->{meanmotion};
            $$xli= $parm->{xlamo};
        }
        $iretn= 381;
        $iret=   0;
        while ($iretn == 381) {
            if ( (abs($t) < abs($$atime)) || ($iret == 351) ) {
                if ($t >= 0) {
                    $delt= $stepn;
                } else {
                    $delt= $stepp;
                }
                $iret= 351;
                $iretn= 381;
            } else {
                if ($t > 0) {
                    $delt= $stepp;
                } else {
                    $delt= $stepn;
                }
                if (abs($t-$$atime) >= $stepp) {
                    $iret= 0;
                    $iretn= 381;
                } else {
                    $ft= $t-$$atime;
                    $iretn= 0;
                }

            }
#* --------------------------- DOT TERMS CALCULATED --------------------
#* ------------------- NEAR - SYNCHRONOUS RESONANCE TERMS --------------
            if ($parm->{irez} !=  2) {
                $xndt= $parm->{del1}*sin($$xli-$fasx2) +
                    $parm->{del2}*sin(2*($$xli-$fasx4)) +
                    $parm->{del3}*sin(3*($$xli-$fasx6));
                $xldot= $$xni+ $parm->{xfact};
                $xnddt= $parm->{del1}*cos($$xli-$fasx2) +
                    2*$parm->{del2}*cos(2*($$xli-$fasx4)) +
                    3*$parm->{del3}*cos(3*($$xli-$fasx6));
                $xnddt= $xnddt*$xldot;

            } else {
#* --------------------- NEAR - HALF-DAY RESONANCE TERMS ---------------
                $xomi= $parm->{argumentofperigee}+
                    $parm->{argpdot}*$$atime;
                $x2omi= $xomi+ $xomi;
                $x2li= $$xli+ $$xli;
                $xndt= $parm->{d2201}*sin($x2omi+$$xli-$g22) +
                    $parm->{d2211}*sin($$xli-$g22) +
                    $parm->{d3210}*sin($xomi+$$xli-$g32) +
                    $parm->{d3222}*sin(-$xomi+$$xli-$g32) +
                    $parm->{d4410}*sin($x2omi+$x2li-$g44)+
                    $parm->{d4422}*sin($x2li-$g44)+
                    $parm->{d5220}*sin($xomi+$$xli-$g52) +
                    $parm->{d5232}*sin(-$xomi+$$xli-$g52) +
                    $parm->{d5421}*sin($xomi+$x2li-$g54)+
                    $parm->{d5433}*sin(-$xomi+$x2li-$g54);
                $xldot= $$xni+$parm->{xfact};
                $xnddt= $parm->{d2201}*cos($x2omi+$$xli-$g22) +
                    $parm->{d2211}*cos($$xli-$g22)+
                    $parm->{d3210}*cos($xomi+$$xli-$g32) +
                    $parm->{d3222}*cos(-$xomi+$$xli-$g32) +
                    $parm->{d5220}*cos($xomi+$$xli-$g52) +
                    $parm->{d5232}*cos(-$xomi+$$xli-$g52) +
                    2*($parm->{d4410}*cos($x2omi+$x2li-$g44) +
                    $parm->{d4422}*cos($x2li-$g44) +
                    $parm->{d5421}*cos($xomi+$x2li-$g54) +
                    $parm->{d5433}*cos(-$xomi+$x2li-$g54));
                $xnddt= $xnddt*$xldot;

            }
#* ------------------------------- INTEGRATOR --------------------------
            if ($iretn == 381) {
                $$xli= $$xli+ $xldot*$delt+ $xndt*$step2;
                $$xni= $$xni+ $xndt*$delt+ $xnddt*$step2;
                $$atime= $$atime+ $delt;

            }

        }
        $$xn= $$xni+ $xndt*$ft+ $xnddt*$ft*$ft*0.5;
        $xl= $$xli+ $xldot*$ft+ $xndt*$ft*$ft*0.5;
        if ($parm->{irez} !=  1) {
            $$mm= $xl-2*$$nodem+2*$theta;
            $$dndt= $$xn-$parm->{meanmotion};
        } else {
            $$mm= $xl-$$nodem-$$argpm+$theta;
            $$dndt= $$xn-$parm->{meanmotion};

        }
        $$xn= $parm->{meanmotion}+ $$dndt;

    }
#c        INCLUDE 'debug4.for'

    return;
}

#* -----------------------------------------------------------------------------
#*
#*                           SUBROUTINE INITL
#*
#*  this subroutine initializes the spg4 propagator. all the initialization is
#*    consolidated here instead of having multiple loops inside other routines.
#*
#*  author        : david vallado                  719-573-2600   28 jun 2005
#*
#*  inputs        :
#*    ecco        - eccentricity                           0.0 - 1.0
#*    epoch       - epoch time in days from jan 0, 1950. 0 hr
#*    inclo       - inclination of satellite
#*    no          - mean motion of satellite
#*    satn        - satellite number
#*
#*  outputs       :
#*    ainv        - 1.0 / a
#*    ao          - semi major axis
#*    con41       -
#*    con42       - 1.0 - 5.0 cos(i)
#*    cosio       - cosine of inclination
#*    cosio2      - cosio squared
#*    eccsq       - eccentricity squared
#*    method      - flag for deep space                    'd', 'n'
#*    omeosq      - 1.0 - ecco * ecco
#*    posq        - semi-parameter squared
#*    rp          - radius of perigee
#*    rteosq      - square root of (1.0 - ecco*ecco)
#*    sinio       - sine of inclination
#*    gsto        - gst at time of observation               rad
#*    no          - mean motion of satellite
#*
#*  locals        :
#*    ak          -
#*    d1          -
#*    del         -
#*    adel        -
#*    po          -
#*
#*  coupling      :
#*    getgravconst-
#*
#*  references    :
#*    hoots, roehrich, norad spacetrack report #3 1980
#*    hoots, norad spacetrack report #6 1986
#*    hoots, schumacher and glover 2004
#*    vallado, crawford, hujsak, kelso  2006
#*------------------------------------------------------------------------------

sub _r_initl {
    my ($self) = @_;
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r}
        or confess "Programming error - Sgp4r not initialized";
    my $init = $parm->{init}
        or confess "Programming error - Sgp4r initialization not in progress";

#* -------------------------- Local Variables --------------------------
#cdav old way
#c        integer ids70
#c        real*8 ts70, ds70, tfrac, c1, thgr70, fk5r, c1p2p, thgr, thgro,
#c     &     twopi
#>>>>trw	INCLUDE 'ASTMATH.CMN'

#* ------------------------ WGS-72 EARTH CONSTANTS ---------------------

#>>>>trw	X2o3   = 2.0D0/3.0D0

#>>>>trw	CALL getgravconst( whichconst, tumin, mu, radiusearthkm, xke, j2, j3, j4, j3oj2 )
#* ----------------- CALCULATE AUXILLARY EPOCH QUANTITIES --------------
    $init->{eccsq}= $parm->{eccentricity}*$parm->{eccentricity};
    $init->{omeosq}= 1 - $init->{eccsq};
    $init->{rteosq}= sqrt($init->{omeosq});
    $init->{cosio}= cos($parm->{inclination});

    $init->{cosio2}= $init->{cosio}*$init->{cosio};
#* ---------------------- UN-KOZAI THE MEAN MOTION ---------------------
    my $ak=  ($parm->{xke}/$parm->{meanmotion})**&SGP_TOTHRD;
    my $d1=  0.75*$parm->{j2}* (3*$init->{cosio2}-1) /
        ($init->{rteosq}*$init->{omeosq});
    my $del=  $d1/($ak*$ak);
    my $adel=  $ak* ( 1 - $del*$del- $del* (1/3 + 134*$del*$del/ 81) );
    $del=  $d1/($adel*$adel);

    $parm->{meanmotion}=  $parm->{meanmotion}/(1 + $del);
    $init->{ao}=  ($parm->{xke}/$parm->{meanmotion})**&SGP_TOTHRD;
    $init->{sinio}=  sin($parm->{inclination});
    my $po=  $init->{ao}*$init->{omeosq};
    $init->{con42}=  1-5*$init->{cosio2};
    $parm->{con41}=  -$init->{con42}-$init->{cosio2}-$init->{cosio2};
    $init->{ainv}=  1/$init->{ao};
    $init->{posq}=  $po*$po;
    $init->{rp}=  $init->{ao}*(1-$parm->{eccentricity});

    $parm->{deep_space}=0;
#* ----------------- CALCULATE GREENWICH LOCATION AT EPOCH -------------
#cdav new approach using JD
    my $radperday= &SGP_TWOPI* 1.0027379093508;

    my $temp= $self->{ds50}+ 2433281.5;
    my $tut1= ( int($temp-0.5) + 0.5 - 2451545 ) / 36525;

    $parm->{gsto}= 1.75336855923327 + 628.331970688841*$tut1+
        6.77071394490334e-06*$tut1*$tut1-
        4.50876723431868e-10*$tut1*$tut1*$tut1+ $radperday*(
        $temp-0.5-int($temp-0.5) );
    $parm->{gsto}= fmod($parm->{gsto}, &SGP_TWOPI);
    if ( $parm->{gsto} <  0 ) {
        $parm->{gsto}= $parm->{gsto}+ &SGP_TWOPI;

    }
#*     CALCULATE NUMBER OF INTEGER DAYS SINCE 0 JAN 1970.
#cdav    old way
#c      TS70 =EPOCH-7305.D0
#c      IDS70=TS70 + 1.D-8
#c      DS70 =IDS70
#c      TFRAC=TS70-DS70
#*     CALCULATE GREENWICH LOCATION AT EPOCH
#c      C1    = 1.72027916940703639D-2
#c      THGR70= 1.7321343856509374D0
#c      FK5R  = 5.07551419432269442D-15
#c      twopi = 6.283185307179586D0
#c      C1P2P = C1+TWOPI
#c      THGR  = DMOD(THGR70+C1*DS70+C1P2P*TFRAC+TS70*TS70*FK5R,twopi)
#c      THGRO = DMOD(THGR,twopi)
#c      gsto  = thgro
#c      write(*,*) Satn,'  gst delta ', gsto-gsto1

#c        INCLUDE 'debug5.for'

    return;
}

#* -----------------------------------------------------------------------------
#*
#*                             SUBROUTINE SGP4INIT
#*
#*  This subroutine initializes variables for SGP4.
#*
#*  author        : david vallado                  719-573-2600   28 jun 2005
#*
#*  inputs        :
#*    satn        - satellite number
#*    bstar       - sgp4 type drag coefficient              kg/m2er
#*    ecco        - eccentricity
#*    epoch       - epoch time in days from jan 0, 1950. 0 hr
#*    argpo       - argument of perigee (output if ds)
#*    inclo       - inclination
#*    mo          - mean anomaly (output if ds)
#*    no          - mean motion
#*    nodeo      - right ascension of ascending node
#*
#*  outputs       :
#*    satrec      - common block values for subsequent calls
#*    return code - non-zero on error.
#*                   1 - mean elements, ecc >= 1.0 or ecc < -0.001 or a < 0.95 er
#*                   2 - mean motion less than 0.0
#*                   3 - pert elements, ecc < 0.0  or  ecc > 1.0
#*                   4 - semi-latus rectum < 0.0
#*                   5 - epoch elements are sub-orbital
#*                   6 - satellite has decayed
#*
#*  locals        :
#*    CNODM  , SNODM  , COSIM  , SINIM  , COSOMM , SINOMM
#*    Cc1sq  , Cc2    , Cc3
#*    Coef   , Coef1
#*    cosio4      -
#*    day         -
#*    dndt        -
#*    em          - eccentricity
#*    emsq        - eccentricity squared
#*    eeta        -
#*    etasq       -
#*    gam         -
#*    argpm       - argument of perigee
#*    ndem        -
#*    inclm       - inclination
#*    mm          - mean anomaly
#*    nm          - mean motion
#*    perige      - perigee
#*    pinvsq      -
#*    psisq       -
#*    qzms24      -
#*    rtemsq      -
#*    s1, s2, s3, s4, s5, s6, s7          -
#*    sfour       -
#*    ss1, ss2, ss3, ss4, ss5, ss6, ss7         -
#*    sz1, sz2, sz3
#*    sz11, sz12, sz13, sz21, sz22, sz23, sz31, sz32, sz33        -
#*    tc          -
#*    temp        -
#*    temp1, temp2, temp3       -
#*    tsi         -
#*    xpidot      -
#*    xhdot1      -
#*    z1, z2, z3          -
#*    z11, z12, z13, z21, z22, z23, z31, z32, z33         -
#*
#*  coupling      :
#*    getgravconst-
#*    initl       -
#*    dscom       -
#*    dpper       -
#*    dsinit      -
#*
#*  references    :
#*    hoots, roehrich, norad spacetrack report #3 1980
#*    hoots, norad spacetrack report #6 1986
#*    hoots, schumacher and glover 2004
#*    vallado, crawford, hujsak, kelso  2006
#* ---------------------------------------------------------------------------- }

sub _r_sgp4init {
    my ($self) = @_;
    my $oid = $self->get('id');
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r} = {};
    my $init = $parm->{init} = {};
    # The following is modified in _r_initl
    $parm->{meanmotion} = $self->{meanmotion};
    # The following may be modified for deep space
    $parm->{eccentricity} = $self->{eccentricity};
    $parm->{inclination} = $self->{inclination};
    $parm->{ascendingnode} = $self->{ascendingnode};
    $parm->{argumentofperigee} = $self->{argumentofperigee};
    $parm->{meananomaly} = $self->{meananomaly};

#>>>>trw    my ($t, @r, @v);
    my ($t);
#>>>>trw	INCLUDE 'SGP4.CMN'

#* -------------------------- Local Variables --------------------------

    my ($cc1sq, $cc2, $cc3, $coef, $coef1, $cosio4, $eeta, $etasq,
        $perige, $pinvsq, $psisq, $qzms24, $sfour, $tc, $temp, $temp1,
        $temp2, $temp3, $tsi, $xhdot1);
    my ($qzms2t, $ss, $temp4);
#>>>>trw	INCLUDE 'ASTMATH.CMN'

#* ---------------------------- INITIALIZATION -------------------------
    $parm->{deep_space}=0;
#c       clear sgp4 flag

    $self->{model_error}= &SGP4R_ERROR_0;
#c      sgp4fix - note the following variables are also passed directly via sgp4 common.
#c      it is possible to streamline the sgp4init call by deleting the "x"
#c      variables, but the user would need to set the common values first. we
#c      include the additional assignment in case twoline2rv is not used.

#>>>>trw	bstar  = xbstar
#>>>>trw	ecco   = xecco
#>>>>trw	argpo  = xargpo
#>>>>trw	inclo  = xinclo
#>>>>trw	mo     = xmo
#>>>>trw	no     = xno

#>>>>trw	nodeo  = xnodeo

    $self->_r_getgravconst();
    $ss= 78/$parm->{radiusearthkm}+ 1;
    $qzms2t= ((120-78)/$parm->{radiusearthkm}) ** 4;
#>>>>trw	X2o3   =  2.0D0 / 3.0D0

    $temp4=  1 + cos(&SGP_PI-1e-09);
#>>>>trw	Init = 'y'

    $t= 0;

    $self->{eccentricity} > 1
        and croak "Error - OID $oid Sgp4r TLE eccentricity > 1";
    $self->{eccentricity} < 0
        and croak "Error - OID $oid Sgp4r TLE eccentricity < 0";
    $self->{meanmotion} < 0
        and croak "Error - OID $oid Sgp4r TLE mean motion < 0";
    $self->_r_initl();
    if ($init->{rp} <  1) {
#c            Write(*,*) '# *** SATN',Satn,' EPOCH ELTS SUB-ORBITAL *** '
        $self->{model_error}= &SGP4R_ERROR_5;

    }
    if ($init->{omeosq} >=  0  ||  $parm->{meanmotion} >=  0) {
        $parm->{isimp}= 0;
        if ($init->{rp} <  (220/$parm->{radiusearthkm}+1)) {
            $parm->{isimp}= 1;
        }
        $sfour= $ss;
        $qzms24= $qzms2t;

        $perige= ($init->{rp}-1)*$parm->{radiusearthkm};
#* ----------- For perigees below 156 km, S and Qoms2t are altered -----
        if ($perige <  156) {
            $sfour= $perige-78;
            if ($perige <=  98) {
                $sfour= 20;
            }
            $qzms24= ( (120-$sfour)/$parm->{radiusearthkm})**4;
            $sfour= $sfour/$parm->{radiusearthkm}+ 1;
        }

        $pinvsq= 1/$init->{posq};
        $tsi= 1/($init->{ao}-$sfour);
        $parm->{eta}= $init->{ao}*$parm->{eccentricity}*$tsi;
        $etasq= $parm->{eta}*$parm->{eta};
        $eeta= $parm->{eccentricity}*$parm->{eta};
        $psisq= abs(1-$etasq);
        $coef= $qzms24*$tsi**4;
        $coef1= $coef/$psisq**3.5;
        $cc2= $coef1*$parm->{meanmotion}* ($init->{ao}*
            (1+1.5*$etasq+$eeta* (4+$etasq) )+0.375*
            $parm->{j2}*$tsi/$psisq*$parm->{con41}*(8+3*$etasq*(8+$etasq)));
        $parm->{cc1}= $self->{bstardrag}*$cc2;
        $cc3= 0;
        if ($parm->{eccentricity} >  0.0001) {
            $cc3=
                -2*$coef*$tsi*$parm->{j3oj2}*$parm->{meanmotion}*
		$init->{sinio}/$parm->{eccentricity};
        }
        $parm->{x1mth2}= 1-$init->{cosio2};
        $parm->{cc4}=
            2*$parm->{meanmotion}*$coef1*$init->{ao}*$init->{omeosq}*
	    ($parm->{eta}*(2+0.5*$etasq)
            +$parm->{eccentricity}*(0.5 + 2*$etasq) - $parm->{j2}*$tsi/
            ($init->{ao}*$psisq)* (-3*$parm->{con41}*(1-2*
            $eeta+$etasq*(1.5-0.5*$eeta))+0.75*$parm->{x1mth2}*
	    (2*$etasq-$eeta*(1+$etasq))*cos(2*$parm->{argumentofperigee})));
        $parm->{cc5}= 2*$coef1*$init->{ao}*$init->{omeosq}* (1 + 2.75*
            ($etasq+ $eeta) + $eeta*$etasq);
        $cosio4= $init->{cosio2}*$init->{cosio2};
        $temp1= 1.5*$parm->{j2}*$pinvsq*$parm->{meanmotion};
        $temp2= 0.5*$temp1*$parm->{j2}*$pinvsq;
        $temp3=
            -0.46875*$parm->{j4}*$pinvsq*$pinvsq*$parm->{meanmotion};
        $parm->{mdot}= $parm->{meanmotion}+
            0.5*$temp1*$init->{rteosq}*$parm->{con41}+ 0.0625*$temp2*
            $init->{rteosq}*(13 - 78*$init->{cosio2}+ 137*$cosio4);
        $parm->{argpdot}= -0.5*$temp1*$init->{con42}+ 0.0625*$temp2* (7
            - 114*$init->{cosio2}+
            395*$cosio4)+$temp3*(3-36*$init->{cosio2}+49*$cosio4);
        $xhdot1= -$temp1*$init->{cosio};
        $parm->{nodedot}= $xhdot1+(0.5*$temp2*(4-19*$init->{cosio2})+
            2*$temp3*(3 - 7*$init->{cosio2}))*$init->{cosio};
        $init->{xpidot}= $parm->{argpdot}+$parm->{nodedot};
        $parm->{omgcof}=
            $self->{bstardrag}*$cc3*cos($parm->{argumentofperigee});
        $parm->{xmcof}= 0;
        if ($parm->{eccentricity} >  0.0001) {
            $parm->{xmcof}= -&SGP_TOTHRD*$coef*$self->{bstardrag}/$eeta;
        }
        $parm->{xnodcf}= 3.5*$init->{omeosq}*$xhdot1*$parm->{cc1};
        $parm->{t2cof}= 1.5*$parm->{cc1};
#c           sgp4fix for divide by zero with xinco = 180 deg
        if (abs($init->{cosio}+1) >  1.5e-12) {
            $parm->{xlcof}= -0.25*$parm->{j3oj2}*$init->{sinio}*
                (3+5*$init->{cosio})/(1+$init->{cosio});
        } else {
            $parm->{xlcof}= -0.25*$parm->{j3oj2}*$init->{sinio}*
                (3+5*$init->{cosio})/$temp4;
        }
        $parm->{aycof}= -0.5*$parm->{j3oj2}*$init->{sinio};
        $parm->{delmo}= (1+$parm->{eta}*cos($parm->{meananomaly}))**3;
        $parm->{sinmao}= sin($parm->{meananomaly});

        $parm->{x7thm1}= 7*$init->{cosio2}-1;
#* ------------------------ Deep Space Initialization ------------------
        if ((&SGP_TWOPI/$parm->{meanmotion})  >=  225) {
            $parm->{deep_space}=1;
            $parm->{isimp}= 1;
            $tc= 0;
            $init->{inclm}= $parm->{inclination};
            $self->_r_dscom ($tc);

            $self->_r_dpper ($t, \$parm->{eccentricity},
                \$parm->{inclination}, \$parm->{ascendingnode},
                \$parm->{argumentofperigee}, \$parm->{meananomaly});
            $init->{argpm}= 0;
            $init->{nodem}= 0;

            $init->{mm}= 0;
            $self->_r_dsinit ($t, $tc);

        }
#* ------------ Set variables if not deep space or rp < 220 -------------
        if ( !  $parm->{isimp}) {
            $cc1sq= $parm->{cc1}*$parm->{cc1};
            $parm->{d2}= 4*$init->{ao}*$tsi*$cc1sq;
            $temp= $parm->{d2}*$tsi*$parm->{cc1}/ 3;
            $parm->{d3}= (17*$init->{ao}+ $sfour) * $temp;
            $parm->{d4}= 0.5*$temp*$init->{ao}*$tsi* (221*$init->{ao}+
                31*$sfour)*$parm->{cc1};
            $parm->{t3cof}= $parm->{d2}+ 2*$cc1sq;
            $parm->{t4cof}= 0.25*
                (3*$parm->{d3}+$parm->{cc1}*(12*$parm->{d2}+10*$cc1sq)
                );
            $parm->{t5cof}= 0.2* (3*$parm->{d4}+
                12*$parm->{cc1}*$parm->{d3}+ 6*$parm->{d2}*$parm->{d2}+
                15*$cc1sq* (2*$parm->{d2}+ $cc1sq) );

        }

    }

#>>>>trw	init = 'n'

#>>>>trw	CALL SGP4(whichconst, 0.0D0, r, v, error)
#c        INCLUDE 'debug6.for'

#>>>>trw	RETURN

    delete $parm->{init};
    return $parm;
}

#* -----------------------------------------------------------------------------
#*
#*                             SUBROUTINE SGP4
#*
#*  this procedure is the sgp4 prediction model from space command. this is an
#*    updated and combined version of sgp4 and sdp4, which were originally
#*    published separately in spacetrack report #3. this version follows the
#*    methodology from the aiaa paper (2006) describing the history and
#*    development of the code.
#*
#*  author        : david vallado                  719-573-2600   28 jun 2005
#*
#*  inputs        :
#*    satrec      - initialised structure from sgp4init() call.
#*    tsince      - time eince epoch (minutes)
#*
#*  outputs       :
#*    r           - position vector                     km
#*    v           - velocity                            km/sec
#*  return code - non-zero on error.
#*                   1 - mean elements, ecc >= 1.0 or ecc < -0.001 or a < 0.95 er
#*                   2 - mean motion less than 0.0
#*                   3 - pert elements, ecc < 0.0  or  ecc > 1.0
#*                   4 - semi-latus rectum < 0.0
#*                   5 - epoch elements are sub-orbital
#*                   6 - satellite has decayed
#*
#*  locals        :
#*    am          -
#*    axnl, aynl        -
#*    betal       -
#*    COSIM   , SINIM   , COSOMM  , SINOMM  , Cnod    , Snod    , Cos2u   ,
#*    Sin2u   , Coseo1  , Sineo1  , Cosi    , Sini    , Cosip   , Sinip   ,
#*    Cosisq  , Cossu   , Sinsu   , Cosu    , Sinu
#*    Delm        -
#*    Delomg      -
#*    Dndt        -
#*    Eccm        -
#*    EMSQ        -
#*    Ecose       -
#*    El2         -
#*    Eo1         -
#*    Eccp        -
#*    Esine       -
#*    Argpm       -
#*    Argpp       -
#*    Omgadf      -
#*    Pl          -
#*    R           -
#*    RTEMSQ      -
#*    Rdotl       -
#*    Rl          -
#*    Rvdot       -
#*    Rvdotl      -
#*    Su          -
#*    T2  , T3   , T4    , Tc
#*    Tem5, Temp , Temp1 , Temp2  , Tempa  , Tempe  , Templ
#*    U   , Ux   , Uy    , Uz     , Vx     , Vy     , Vz
#*    inclm       - inclination
#*    mm          - mean anomaly
#*    nm          - mean motion
#*    nodem       - longi of ascending node
#*    xinc        -
#*    xincp       -
#*    xl          -
#*    xlm         -
#*    mp          -
#*    xmdf        -
#*    xmx         -
#*    xmy         -
#*    nodedf     -
#*    xnode       -
#*    nodep      -
#*    np          -
#*
#*  coupling      :
#*    getgravconst-
#*    dpper
#*    dpspace
#*
#*  references    :
#*    hoots, roehrich, norad spacetrack report #3 1980
#*    hoots, norad spacetrack report #6 1986
#*    hoots, schumacher and glover 2004
#*    vallado, crawford, hujsak, kelso  2006
#*------------------------------------------------------------------------------

sub sgp4r {
    my ($self, $t) = @_;
    my $oid = $self->get('id');
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r} ||= $self->_r_sgp4init ();
    my $time = $t;
    $t = ($t - $self->{epoch}) / 60;

    my (@r, @v);
#>>>>trw	INCLUDE 'SGP4.CMN'

#* -------------------------- Local Variables --------------------------

    my ($am, $axnl, $aynl, $betal, $cosim, $cnod, $cos2u, $coseo1,
        $cosi, $cosip, $cosisq, $cossu, $cosu, $delm, $delomg, $eccm,
        $emsq, $ecose, $el2, $eo1, $eccp, $esine, $argpm, $argpp,
        $omgadf, $pl, $rdotl, $rl, $rvdot, $rvdotl, $sinim, $sin2u,
        $sineo1, $sini, $sinip, $sinsu, $sinu, $snod, $su, $t2, $t3,
        $t4, $tem5, $temp, $temp1, $temp2, $tempa, $tempe, $templ, $u,
        $ux, $uy, $uz, $vx, $vy, $vz, $inclm, $mm, $xn, $nodem, $xinc,
        $xincp, $xl, $xlm, $mp, $xmdf, $xmx, $xmy, $xnoddf, $xnode,
        $nodep, $tc, $dndt);
    my ($mr, $mv, $vkmpersec, $temp4);

    my ($iter);
#>>>>trw	INCLUDE 'ASTMATH.CMN'

#* ------------------------ WGS-72 EARTH CONSTANTS ---------------------
#* ---------------------- SET MATHEMATICAL CONSTANTS -------------------

#>>>>trw	X2O3   = 2.0D0/3.0D0
#c     Keep compiler ok for warnings on uninitialized variables
    $mr= 0;
    $coseo1= 1;

    $sineo1= 0;
#>>>>trw	CALL getgravconst( whichconst, tumin, mu, radiusearthkm, xke, j2, j3, j4, j3oj2 )
    $temp4=   1 + cos(&SGP_PI-1e-09);

    $vkmpersec=  $parm->{radiusearthkm}* $parm->{xke}/60;
#* ------------------------- CLEAR SGP4 ERROR FLAG ---------------------

    $self->{model_error}= &SGP4R_ERROR_0;
#* ----------- UPDATE FOR SECULAR GRAVITY AND ATMOSPHERIC DRAG ---------
    $xmdf= $parm->{meananomaly}+ $parm->{mdot}*$t;
    $omgadf= $parm->{argumentofperigee}+ $parm->{argpdot}*$t;
    $xnoddf= $parm->{ascendingnode}+ $parm->{nodedot}*$t;
    $argpm= $omgadf;
    $mm= $xmdf;
    $t2= $t*$t;
    $nodem= $xnoddf+ $parm->{xnodcf}*$t2;
    $tempa= 1 - $parm->{cc1}*$t;
    $tempe= $self->{bstardrag}*$parm->{cc4}*$t;
    $templ= $parm->{t2cof}*$t2;
    if ( !  $parm->{isimp}) {
        $delomg= $parm->{omgcof}*$t;
        $delm= $parm->{xmcof}*(( 1+$parm->{eta}*cos($xmdf)
            )**3-$parm->{delmo});
        $temp= $delomg+ $delm;
        $mm= $xmdf+ $temp;
        $argpm= $omgadf- $temp;
        $t3= $t2*$t;
        $t4= $t3*$t;
        $tempa= $tempa- $parm->{d2}*$t2- $parm->{d3}*$t3-
            $parm->{d4}*$t4;
        $tempe= $tempe+ $self->{bstardrag}*$parm->{cc5}*(sin($mm) -
            $parm->{sinmao});
        $templ= $templ+ $parm->{t3cof}*$t3+ $t4*($parm->{t4cof}+
            $t*$parm->{t5cof});
    }
    $xn= $parm->{meanmotion};
    $eccm= $parm->{eccentricity};
    $inclm= $parm->{inclination};
    if ($parm->{deep_space}) {
        $tc= $t;
        $self->_r_dspace ($t, $tc, \$parm->{atime}, \$eccm, \$argpm,
            \$inclm, \$parm->{xli}, \$mm, \$parm->{xni}, \$nodem,
            \$dndt, \$xn);

    }
#c     mean motion less than 0.0
    if ($xn <=  0) {
        $self->{model_error}= &SGP4R_ERROR_2;
        croak "Error - OID $oid ", &SGP4R_ERROR_MEAN_MOTION;
    }
    $am= ($parm->{xke}/$xn)**&SGP_TOTHRD*$tempa**2;
    $xn= $parm->{xke}/$am**1.5;
    $eccm= $eccm-$tempe;
    $self->{debug}
	and warn "Debug - OID $oid sgp4r effective eccentricity $eccm\n";
#c   fix tolerance for error recognition
    if ($eccm >=  1  ||  $eccm < -0.001  ||  $am <  0.95) {
#c         write(6,*) '# Error 1, Eccm = ',  Eccm, ' AM = ', AM
        $self->{model_error} = &SGP4R_ERROR_1;
	my $tfmt = '%d-%b-%Y %H:%M:%S';
	my @data = "Error - OID $oid " . &SGP4R_ERROR_MEAN_ECCEN;
	push @data, "eccentricity = $eccm";
	foreach my $thing (qw{universal epoch effective}) {
	    if (defined ( my $value = $self->can($thing) ?
		    $self->$thing() :
		    $self->get($thing))) {
		local $@ = undef;
		my $diag = eval {
		    strftime( "$thing = $tfmt", gmtime $value ) };
		defined $diag or $diag = "$thing = $value";
		push @data, $diag;
	    } else {
		push @data, "$thing is undefined";
	    }
	}
	croak join '; ', @data
    }
    if ($eccm <  0) {
        $eccm= 1e-06
    }
    $mm= $mm+$parm->{meanmotion}*$templ;
    $xlm= $mm+$argpm+$nodem;
    $emsq= $eccm*$eccm;
    $temp= 1 - $emsq;
    $nodem= fmod($nodem, &SGP_TWOPI);
    $argpm= fmod($argpm, &SGP_TWOPI);
    $xlm= fmod($xlm, &SGP_TWOPI);

    $mm= fmod($xlm- $argpm- $nodem, &SGP_TWOPI);
#* --------------------- COMPUTE EXTRA MEAN QUANTITIES -----------------
    $sinim= sin($inclm);

    $cosim= cos($inclm);
#* ------------------------ ADD LUNAR-SOLAR PERIODICS ------------------
    $eccp= $eccm;
    $xincp= $inclm;
    $argpp= $argpm;
    $nodep= $nodem;
    $mp= $mm;
    $sinip= $sinim;
    $cosip= $cosim;
    if ($parm->{deep_space}) {
        $self->_r_dpper ($t, \$eccp, \$xincp, \$nodep, \$argpp, \$mp);
        if ($xincp <  0) {
            $xincp= -$xincp;
            $nodep= $nodep+ &SGP_PI;
            $argpp= $argpp- &SGP_PI;
        }
        if ($eccp <  0  ||  $eccp >  1) {
            $self->{model_error}= &SGP4R_ERROR_3;
            croak "Error - OID $oid ", &SGP4R_ERROR_INST_ECCEN;
        }

    }
#* ------------------------ LONG PERIOD PERIODICS ----------------------
    if ($parm->{deep_space}) {
        $sinip=  sin($xincp);
        $cosip=  cos($xincp);
        $parm->{aycof}= -0.5*$parm->{j3oj2}*$sinip;
#c         sgp4fix for divide by zero with xincp = 180 deg
        if (abs($cosip+1) >  1.5e-12) {
            $parm->{xlcof}= -0.25*$parm->{j3oj2}*$sinip*
                (3+5*$cosip)/(1+$cosip);
        } else {
            $parm->{xlcof}= -0.25*$parm->{j3oj2}*$sinip*
                (3+5*$cosip)/$temp4;
        }
    }
    $axnl= $eccp*cos($argpp);
    $temp= 1 / ($am*(1-$eccp*$eccp));
    $aynl= $eccp*sin($argpp) + $temp*$parm->{aycof};

    $xl= $mp+ $argpp+ $nodep+ $temp*$parm->{xlcof}*$axnl;
#* ------------------------- SOLVE KEPLER'S EQUATION -------------------
    $u= fmod($xl-$nodep, &SGP_TWOPI);
    $eo1= $u;
    $iter=0;
#c   sgp4fix for kepler iteration
#c   the following iteration needs better limits on corrections
    $temp= 9999.9;
    while (($temp >= 1e-12) && ($iter < 10)) {
        $iter=$iter+1;
        $sineo1= sin($eo1);
        $coseo1= cos($eo1);
        $tem5= 1 - $coseo1*$axnl- $sineo1*$aynl;
        $tem5= ($u- $aynl*$coseo1+ $axnl*$sineo1- $eo1) / $tem5;
        $temp= abs($tem5);
        if ($temp > 1) {
            $tem5=$tem5/$temp
        }
        $eo1= $eo1+$tem5;

    }
#* ----------------- SHORT PERIOD PRELIMINARY QUANTITIES ---------------
    $ecose= $axnl*$coseo1+$aynl*$sineo1;
    $esine= $axnl*$sineo1-$aynl*$coseo1;
    $el2= $axnl*$axnl+$aynl*$aynl;
    $pl= $am*(1-$el2);
#c     semi-latus rectum < 0.0
    if ( $pl <  0 ) {
        $self->{model_error}= &SGP4R_ERROR_4;
        croak "Error - OID $oid ", &SGP4R_ERROR_LATUSRECTUM;
    } else {
        $rl= $am*(1-$ecose);
        $rdotl= sqrt($am)*$esine/$rl;
        $rvdotl= sqrt($pl)/$rl;
        $betal= sqrt(1-$el2);
        $temp= $esine/(1+$betal);
        $sinu= $am/$rl*($sineo1-$aynl-$axnl*$temp);
        $cosu= $am/$rl*($coseo1-$axnl+$aynl*$temp);
        $su= atan2($sinu, $cosu);
        $sin2u= ($cosu+$cosu)*$sinu;
        $cos2u= 1-2*$sinu*$sinu;
        $temp= 1/$pl;
        $temp1= 0.5*$parm->{j2}*$temp;

        $temp2= $temp1*$temp;
#* ------------------ UPDATE FOR SHORT PERIOD PERIODICS ----------------
        if ($parm->{deep_space}) {
            $cosisq= $cosip*$cosip;
            $parm->{con41}= 3*$cosisq- 1;
            $parm->{x1mth2}= 1 - $cosisq;
            $parm->{x7thm1}= 7*$cosisq- 1;
        }
        $mr= $rl*(1 - 1.5*$temp2*$betal*$parm->{con41}) +
            0.5*$temp1*$parm->{x1mth2}*$cos2u;
        $su= $su- 0.25*$temp2*$parm->{x7thm1}*$sin2u;
        $xnode= $nodep+ 1.5*$temp2*$cosip*$sin2u;
        $xinc= $xincp+ 1.5*$temp2*$cosip*$sinip*$cos2u;
        $mv= $rdotl- $xn*$temp1*$parm->{x1mth2}*$sin2u/ $parm->{xke};

        $rvdot= $rvdotl+ $xn*$temp1*
            ($parm->{x1mth2}*$cos2u+1.5*$parm->{con41}) / $parm->{xke};
#* ------------------------- ORIENTATION VECTORS -----------------------
        $sinsu=  sin($su);
        $cossu=  cos($su);
        $snod=  sin($xnode);
        $cnod=  cos($xnode);
        $sini=  sin($xinc);
        $cosi=  cos($xinc);
        $xmx= -$snod*$cosi;
        $xmy=  $cnod*$cosi;
        $ux=  $xmx*$sinsu+ $cnod*$cossu;
        $uy=  $xmy*$sinsu+ $snod*$cossu;
        $uz=  $sini*$sinsu;
        $vx=  $xmx*$cossu- $cnod*$sinsu;
        $vy=  $xmy*$cossu- $snod*$sinsu;

        $vz=  $sini*$cossu;
#* ----------------------- POSITION AND VELOCITY -----------------------
        $r[1] = $mr*$ux* $parm->{radiusearthkm};
        $r[2] = $mr*$uy* $parm->{radiusearthkm};
        $r[3] = $mr*$uz* $parm->{radiusearthkm};
        $v[1] = ($mv*$ux+ $rvdot*$vx) * $vkmpersec;
        $v[2] = ($mv*$uy+ $rvdot*$vy) * $vkmpersec;
        $v[3] = ($mv*$uz+ $rvdot*$vz) * $vkmpersec;

    }
#* --------------------------- ERROR PROCESSING ------------------------
#c     sgp4fix for decaying satellites
    if ($mr <  1) {
#c          write(*,*) '# decay condition ',mr
        $self->{model_error}= &SGP4R_ERROR_6;

    }
#c        INCLUDE 'debug7.for'

#>>>>trw	RETURN

    $self->__universal( $time );
    $self->eci (@r[1..3], @v[1..3]);
    $self->equinox_dynamical ($self->{epoch_dynamical});
    return $self;
}

=begin comment

The following code was converted from the Fortran reference
implementation, but is not used by this code.

#* -----------------------------------------------------------------------------
#*
#*                           FUNCTION GSTIME
#*
#*  This function finds the Greenwich SIDEREAL time.  Notice just the INTEGER
#*    part of the Julian Date is used for the Julian centuries calculation.
#*    We use radper Solar day because we're multiplying by 0-24 solar hours.
#*
#*  Author        : David Vallado                  719-573-2600    1 Mar 2001
#*
#*  Inputs          Description                    Range / Units
#*    JD          - Julian Date                    days from 4713 BC
#*
#*  OutPuts       :
#*    GSTIME      - Greenwich SIDEREAL Time        0 to 2Pi rad
#*
#*  Locals        :
#*    Temp        - Temporary variable for reals   rad
#*    TUT1        - Julian Centuries from the
#*                  Jan 1, 2000 12 h epoch (UT1)
#*
#*  Coupling      :
#*
#*  References    :
#*    Vallado       2007, 194, Eq 3-45
#* -----------------------------------------------------------------------------

sub _r_gstime {
    my ($jd) = @_;
    my $gstime;
#* ----------------------------  Locals  -------------------------------

    my ($temp, $tut1);
#>>>>trw	INCLUDE 'astmath.cmn'

    $tut1= ( $$jd- 2451545 ) / 36525;
    $temp= - 6.2e-06*$tut1*$tut1*$tut1+ 0.093104*$tut1*$tut1+
        (876600*3600 + 8640184.812866)*$tut1+ 67310.54841;

    $temp= fmod($temp*&SGP_DE2RA/240, &SGP_TWOPI);
    if ( $temp <  0 ) {
        $temp= $temp+ &SGP_TWOPI;

    }

    $gstime= $temp;
    return $gstime;
}

=end comment

=cut

#* -----------------------------------------------------------------------------
#*
#*                           function getgravconst
#*
#*  this function gets constants for the propagator. note that mu is identified to
#*    facilitiate comparisons with newer models.
#*
#*  author        : david vallado                  719-573-2600   21 jul 2006
#*
#*  inputs        :
#*    whichconst  - which set of constants to use  721, 72, 84
#*
#*  outputs       :
#*    tumin       - minutes in one time unit
#*    mu          - earth gravitational parameter
#*    radiusearthkm - radius of the earth in km
#*    xke         - reciprocal of tumin
#*    j2, j3, j4  - un-normalized zonal harmonic values
#*    j3oj2       - j3 divided by j2
#*
#*  locals        :
#*
#*  coupling      :
#*
#*  references    :
#*    norad spacetrack report #3
#*    vallado, crawford, hujsak, kelso  2006
#*  ----------------------------------------------------------------------------

sub _r_getgravconst {
    my ($self) = @_;
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r}
        or confess "Programming error - Sgp4r not initialized";

    if ($self->{gravconst_r} == 721) {
        $parm->{radiusearthkm}= 6378.135;
        $parm->{xke}= 0.0743669161;
        $parm->{mu}= 398600.79964;
        $parm->{tumin}= 1 / $parm->{xke};
        $parm->{j2}=   0.001082616;
        $parm->{j3}=  -2.53881e-06;
        $parm->{j4}=  -1.65597e-06;
        $parm->{j3oj2}=  $parm->{j3}/ $parm->{j2};
    }

    if ($self->{gravconst_r} == 72) {
        $parm->{mu}= 398600.8;
        $parm->{radiusearthkm}= 6378.135;
        $parm->{xke}= 60 / sqrt($parm->{radiusearthkm}**3/$parm->{mu});
        $parm->{tumin}= 1 / $parm->{xke};
        $parm->{j2}=   0.001082616;
        $parm->{j3}=  -2.53881e-06;
        $parm->{j4}=  -1.65597e-06;
        $parm->{j3oj2}=  $parm->{j3}/ $parm->{j2};
    }

    if ($self->{gravconst_r} == 84) {
        $parm->{mu}= 398600.5;
        $parm->{radiusearthkm}= 6378.137;
        $parm->{xke}= 60 / sqrt($parm->{radiusearthkm}**3/$parm->{mu});
        $parm->{tumin}= 1 / $parm->{xke};
        $parm->{j2}=   0.00108262998905;
        $parm->{j3}=  -2.53215306e-06;
        $parm->{j4}=  -1.61098761e-06;
        $parm->{j3oj2}=  $parm->{j3}/ $parm->{j2};

    }
    return;
}

##### end of sgp4unit.for

=begin comment

# Used for debugging

sub _r_dump {
    my $self = shift;
    no warnings qw{uninitialized};
    my $parm = $self->{&TLE_INIT}{TLE_sgp4r}
	or confess "Programming error - Sgp4r not initialized";
    my $fh = IO::File->new('perldump.out', '>>')
	or croak "Failed to open perldump.out: $!";
    print $fh ' ========== sgp4r initialization', "\n";
    print $fh ' SatNum = ', $self->get ('id'), "\n";
    print $fh ' ...', "\n";
    print $fh ' Bstar = ', $self->{bstardrag}, "\n";
    print $fh ' Ecco = ', $parm->{eccentricity}, "\n";
    print $fh ' Inclo = ', $parm->{inclination}, "\n";
    print $fh ' nodeo = ', $parm->{ascendingnode}, "\n";
    print $fh ' Argpo = ', $parm->{argumentofperigee}, "\n";
    print $fh ' No = ', $parm->{meanmotion}, "\n";
    print $fh ' Mo = ', $parm->{meananomaly}, "\n";
    print $fh ' NDot = ', '????', "\n";
    print $fh ' NDDot = ', '????', "\n";
    print $fh ' alta = ', 'not computed; unused?', "\n";
    print $fh ' altp = ', 'not computed; unused?', "\n";
    print $fh ' a = ', 'not computed; unused?', "\n";
    print $fh ' ...', "\n";
    print $fh ' ----', "\n";
    print $fh ' Aycof = ', $parm->{aycof}, "\n";
    print $fh ' CON41 = ', $parm->{con41}, "\n";
    print $fh ' Cc1 = ', $parm->{cc1}, "\n";
    print $fh ' Cc4 = ', $parm->{cc4}, "\n";
    print $fh ' Cc5 = ', $parm->{cc5}, "\n";
    print $fh ' D2 = ', $parm->{d2}, "\n";
    print $fh ' D3 = ', $parm->{d3}, "\n";
    print $fh ' D4 = ', $parm->{d4}, "\n";
    print $fh ' Delmo = ', $parm->{delmo}, "\n";
    print $fh ' Eta = ', $parm->{eta}, "\n";
    print $fh ' ArgpDot = ', $parm->{argpdot}, "\n";
    print $fh ' Omgcof = ', $parm->{omgcof}, "\n";
    print $fh ' Sinmao = ', $parm->{sinmao}, "\n";
    print $fh ' T2cof = ', $parm->{t2cof}, "\n";
    print $fh ' T3cof = ', $parm->{t3cof}, "\n";
    print $fh ' T4cof = ', $parm->{t4cof}, "\n";
    print $fh ' T5cof = ', $parm->{t5cof}, "\n";
    print $fh ' X1mth2 = ', $parm->{x1mth2}, "\n";
    print $fh ' MDot = ', $parm->{mdot}, "\n";
    print $fh ' nodeDot = ', $parm->{nodedot}, "\n";
    print $fh ' Xlcof = ', $parm->{xlcof}, "\n";
    print $fh ' Xmcof = ', $parm->{xmcof}, "\n";
    print $fh ' Xnodcf = ', $parm->{xnodcf}, "\n";
    print $fh ' ----', "\n";
    print $fh ' D2201 = ', $parm->{d2201}, "\n";
    print $fh ' D2211 = ', $parm->{d2211}, "\n";
    print $fh ' D3210 = ', $parm->{d3210}, "\n";
    print $fh ' D3222 = ', $parm->{d3222}, "\n";
    print $fh ' D4410 = ', $parm->{d4410}, "\n";
    print $fh ' D4422 = ', $parm->{d4422}, "\n";
    print $fh ' D5220 = ', $parm->{d5220}, "\n";
    print $fh ' D5232 = ', $parm->{d5232}, "\n";
    print $fh ' D5421 = ', $parm->{d5421}, "\n";
    print $fh ' D5433 = ', $parm->{d5433}, "\n";
    print $fh ' Dedt = ', $parm->{dedt}, "\n";
    print $fh ' Del1 = ', $parm->{del1}, "\n";
    print $fh ' Del2 = ', $parm->{del2}, "\n";
    print $fh ' Del3 = ', $parm->{del3}, "\n";
    print $fh ' Didt = ', $parm->{didt}, "\n";
    print $fh ' Dmdt = ', $parm->{dmdt}, "\n";
    print $fh ' Dnodt = ', $parm->{dnodt}, "\n";
    print $fh ' Domdt = ', $parm->{domdt}, "\n";
    print $fh ' E3 = ', $parm->{e3}, "\n";
    print $fh ' Ee2 = ', $parm->{ee2}, "\n";
    print $fh ' Peo = ', $parm->{peo}, "\n";
    print $fh ' Pgho = ', $parm->{pgho}, "\n";
    print $fh ' Pho = ', $parm->{pho}, "\n";
    print $fh ' Pinco = ', $parm->{pinco}, "\n";
    print $fh ' Plo = ', $parm->{plo}, "\n";
    print $fh ' Se2 = ', $parm->{se2}, "\n";
    print $fh ' Se3 = ', $parm->{se3}, "\n";
    print $fh ' Sgh2 = ', $parm->{sgh2}, "\n";
    print $fh ' Sgh3 = ', $parm->{sgh3}, "\n";
    print $fh ' Sgh4 = ', $parm->{sgh4}, "\n";
    print $fh ' Sh2 = ', $parm->{sh2}, "\n";
    print $fh ' Sh3 = ', $parm->{sh3}, "\n";
    print $fh ' Si2 = ', $parm->{si2}, "\n";
    print $fh ' Si3 = ', $parm->{si3}, "\n";
    print $fh ' Sl2 = ', $parm->{sl2}, "\n";
    print $fh ' Sl3 = ', $parm->{sl3}, "\n";
    print $fh ' Sl4 = ', $parm->{sl4}, "\n";
    print $fh ' GSTo = ', $parm->{gsto}, "\n";
    print $fh ' Xfact = ', $parm->{xfact}, "\n";
    print $fh ' Xgh2 = ', $parm->{xgh2}, "\n";
    print $fh ' Xgh3 = ', $parm->{xgh3}, "\n";
    print $fh ' Xgh4 = ', $parm->{xgh4}, "\n";
    print $fh ' Xh2 = ', $parm->{xh2}, "\n";
    print $fh ' Xh3 = ', $parm->{xh3}, "\n";
    print $fh ' Xi2 = ', $parm->{xi2}, "\n";
    print $fh ' Xi3 = ', $parm->{xi3}, "\n";
    print $fh ' Xl2 = ', $parm->{xl2}, "\n";
    print $fh ' Xl3 = ', $parm->{xl3}, "\n";
    print $fh ' Xl4 = ', $parm->{xl4}, "\n";
    print $fh ' Xlamo = ', $parm->{xlamo}, "\n";
    print $fh ' Zmol = ', $parm->{zmol}, "\n";
    print $fh ' Zmos = ', $parm->{zmos}, "\n";
    print $fh ' Atime = ', $parm->{atime}, "\n";
    print $fh ' Xli = ', $parm->{xli}, "\n";
    print $fh ' Xni = ', $parm->{xni}, "\n";
    print $fh ' IRez = ', $parm->{irez}, "\n";
    print $fh ' Isimp = ', $parm->{isimp}, "\n";
    print $fh ' Init = ', $parm->{init}, "\n";
    print $fh ' Method = ', ($parm->{deep_space} ? 'd' : 'n'), "\n";
    return;
}

=end comment

=cut

# Elevation of the illuminating body as seen from the satellite at the
# given time.
sub __sun_elev_from_sat {
    my ( $self, $time ) = @_;
    if ( defined $time ) {
	$self->universal( $time );
    } else {
	$time = $self->universal();
    }
    return ( $self->azel_offset(
	    $self->get( 'illum' )->universal( $time ),
	    $self->get( 'edge_of_earths_shadow' ),
	) )[1] - $self->dip();
}

=item $text = $tle->tle_verbose(...);

This method returns a verbose version of the TLE data, with one data
field per line, labeled. The optional arguments are key-value pairs
affecting the formatting of the output. The only key implemented at the
moment is

 date_format
   specifies the strftime() format used for dates
   (default: '%d-%b-%Y %H:%M:%S').

=cut

sub tle_verbose {
    my ($self, %args) = @_;
    my $dtfmt = $args{date_format} || '%d-%b-%Y %H:%M:%S';
    my $semimajor = $self->get('semimajor');	# Of reference ellipsoid.

    my $result = <<EOD;
NORAD ID: @{[$self->get ('id')]}
    Name: @{[$self->get ('name') || 'unspecified']}
    International launch designator: @{[$self->get ('international')]}
    Epoch of data: @{[strftime $dtfmt, gmtime $self->get ('epoch')]} GMT
EOD
    if (defined (my $effective = $self->get('effective'))) {
	$result .= <<EOD;
    Effective date: @{[strftime $dtfmt, gmtime $effective]} GMT
EOD
    }
    $result .= <<EOD;
    Classification status: @{[$self->get ('classification')]}
    Mean motion: @{[rad2deg ($self->get ('meanmotion'))]} degrees/minute
    First derivative of motion: @{[rad2deg ($self->get ('firstderivative'))]} degrees/minute squared
    Second derivative of motion: @{[rad2deg ($self->get ('secondderivative'))]} degrees/minute cubed
    B Star drag term: @{[$self->get ('bstardrag')]}
    Ephemeris type: @{[$self->get ('ephemeristype')]}
    Inclination of orbit: @{[rad2deg ($self->get ('inclination'))]} degrees
    Right ascension of ascending node: @{[rad2deg ($self->get ('ascendingnode'))]} degrees
    Eccentricity: @{[$self->get ('eccentricity')]}
    Argument of perigee: @{[rad2deg ($self->get ('argumentofperigee'))]} degrees from ascending node
    Mean anomaly: @{[rad2deg ($self->get ('meananomaly'))]} degrees
    Element set number: @{[$self->get ('elementnumber')]}
    Revolutions at epoch: @{[$self->get ('revolutionsatepoch')]}
    Period (derived): @{[$self->period()]} seconds
    Semimajor axis (derived): @{[$self->semimajor()]} kilometers
    Altitude at perigee (derived): @{[$self->periapsis() - $semimajor]} kilometers
    Altitude at apogee (derived): @{[$self->apoapsis() - $semimajor]} kilometers
EOD
    return $result;
}

=item $hash_ref = $tle->TO_JSON();

Despite its name, this method B<does not> convert the object to JSON.
What it does instead is to return a reference to a hash that the
L<JSON|JSON> class will use to encode the object into JSON. The possible
keys are, to the extent possible, those used by the Space Track REST
interface.

In order to get L<JSON|JSON> to use this hook you need to instantiate a
L<JSON|JSON> object and turn on the conversion of blessed objects, like
so:

 my $json = JSON->new()->convert_blessed( 1 );
 print $json->encode( $tle );

The returned keys are a mish-mash of the keys returned by the Space
Track C<satcat> and C<tle> classes, plus others that are not maintained
by Space Track. Since the Space Track keys are all upper case, I have
made the non-Space Track keys all lower case.

At this point I am not going to document the keys returned by this
method, but they are generally self-explanatory. I find the most cryptic
one is C<{INTLDES}>, which is the International Launch Designator,
encoded with a four-digit year.

=cut

{

    my %json_map = (
	ARG_OF_PERICENTER	=> sub {
	    my ( $self ) = @_;
	    return rad2deg( $self->get( 'argumentofperigee' ) );
	},
	BSTAR		=> 'bstardrag',
	CLASSIFICATION_TYPE	=> 'classification',
	COMMENT		=> sub {
	    return 'Generated by ' . __PACKAGE__ . ' v' . $VERSION;
	},
	CREATION_DATE	=> sub {
	    return format_space_track_json_time( time );
	},
	ECCENTRICITY	=> 'eccentricity',
	ELEMENT_SET_NO	=> 'elementnumber',
	EPHEMERIS_TYPE	=> 'ephemeristype',
	EPOCH		=> sub {
	    my ( $self ) = @_;
	    return format_space_track_json_time( floor(  $self->get( 'epoch' ) ) );
	},
	EPOCH_MICROSECONDS	=> sub {
	    my ( $self ) = @_;
	    my $epoch = sprintf '%.6f', $self->get( 'epoch' );
	    $epoch =~ s/ [^.]* [.] //smx;
	    return $epoch;
	},
	FILE		=> 'file',
	INCLINATION	=> sub {
	    my ( $self ) = @_;
	    return rad2deg( $self->get( 'inclination' ) );
	},
	INTLDES		=> sub {
	    my ( $self ) = @_;
	    my $year = $self->get( 'launch_year' );
	    my $num = $self->get( 'launch_num' );
	    my $part = $self->get( 'launch_piece' );
	    # As of August 27 2012, this is no longer yyyy-lllp, it is
	    # yylllp, same as it has always been in the TLE format.
	    $year %= 100;
	    foreach ( $year, $num, $part ) {
		defined $_
		    and $_ =~ m/ \S /smx
		    or return;
	    }
	    return sprintf '%02d%03d%s', $year, $num, $part;	# ditto
	},
	LAUNCH_NUM	=> 'launch_num',
	LAUNCH_PIECE	=> 'launch_piece',
	LAUNCH_YEAR	=> 'launch_year',
	MEAN_ANOMALY	=> sub {
	    my ( $self ) = @_;
	    return rad2deg( $self->get( 'meananomaly' ) );
	},
	MEAN_MOTION	=> sub {
	    my ( $self ) = @_;
	    return $self->get( 'meanmotion' ) * SGP_XMNPDA / TWOPI;
	},
	MEAN_MOTION_DDOT	=> sub {
	    my ( $self ) = @_;
	    return $self->get(
		'secondderivative'
	    ) * SGP_XMNPDA * SGP_XMNPDA * SGP_XMNPDA / TWOPI;
	},
	MEAN_MOTION_DOT	=> sub {
	    my ( $self ) = @_;
	    return $self->get(
		'firstderivative'
	    ) * SGP_XMNPDA * SGP_XMNPDA / TWOPI;
	},
	NORAD_CAT_ID	=> 'id',
	OBJECT_NAME	=> 'name',
	OBJECT_NUMBER	=> 'id',
	OBJECT_TYPE	=> sub {
	    my ( $self ) = @_;
	    return uc $self->body_type();
	},
	ORDINAL		=> 'ordinal',
	ORIGINATOR	=> 'originator',
	RA_OF_ASC_NODE	=> sub {
	    my ( $self ) = @_;
	    return rad2deg( $self->get( 'ascendingnode' ) );
	},
	RCSVALUE	=> 'rcs',
	REV_AT_EPOCH	=> 'revolutionsatepoch',
	TLE_LINE0	=> sub {
	    my ( $self ) = @_;
	    my $name = $self->get( 'name' );
	    defined $name
		and $name = "0 $name";
	    return $name;
	},
	# TLE_LINE1 is handled programmatically
	# TLE_LINE2 is handled programmatically
	effective_date	=> sub {
	    my ( $self ) = @_;
	    return format_space_track_json_time( $self->get( 'effective' ) );
	},
	intrinsic_magnitude	=> 'intrinsic_magnitude',
    );

    # This guy is to be used by subclasses so they don't have to
    # implement their own converter. The arguments (after the invocant)
    # are a reference to the mapping hash and an optional reference to
    # a hash to populate. The return is a hash reference, which will be
    # the one provided if there _was_ one provided.

    # The mapping hash's keys are the keys to be provided in the output.
    # The values are either the Astro::Coord::ECI::TLE attributes
    # corresponding to those keys, or a code reference which computes
    # the value. If a code reference, it is called with the invocant and
    # the JSON key. No matter where they come from, values which are
    # undef or '' will not appear in the output hash.

    sub __to_json {
	my ( $self, $mapping, $rslt ) = @_;
	$rslt ||= {};

	foreach my $key ( keys %{ $mapping } ) {
	    my $map = $mapping->{$key};
	    my $val = CODE_REF eq ref $map ?
		$map->( $self, $key ) :
		$self->get( $map );
	    defined $val
		and $val ne ''
		and $rslt->{$key} = $val;
	}
	return $rslt;
    }

    sub TO_JSON {
	my ( $self ) = @_;
	my $rslt = $self->__to_json( \%json_map );

	if ( defined ( my $tle = $self->get( 'tle' ) ) ) {
	    chomp $tle;
	    my @lines = split "\n", $tle;
	    unshift @lines, '' while @lines < 3;
	    foreach my $line ( 1, 2 ) {
		defined $lines[$line]
		    and $lines[$line] =~ m/ \S /smx
		    and $rslt->{"TLE_LINE$line"} = $lines[$line];
	    }
	}

	return $rslt;
    }

}

{
    my $have_json;
    my @required = qw{
	NORAD_CAT_ID
	EPOCH
	MEAN_MOTION
	ECCENTRICITY
	INCLINATION
	RA_OF_ASC_NODE
	ARG_OF_PERICENTER
	MEAN_ANOMALY
	EPHEMERIS_TYPE
	CLASSIFICATION_TYPE
	ELEMENT_SET_NO
	REV_AT_EPOCH
	BSTAR
	MEAN_MOTION_DOT
	MEAN_MOTION_DDOT
    };
    my %json_map = (
	INTLDES		=> 'international',
	NORAD_CAT_ID	=> 'id',
	OBJECT_NAME	=> 'name',
	RCSVALUE	=> 'rcs',
#	LAUNCH_YEAR	=> 'launch_year',
#	LAUNCH_NUM	=> 'launch_num',
#	LAUNCH_PIECE	=> 'launch_piece',
#	COMMENT		=> sub {
#	    return 'Generated by ' . __PACKAGE__ . ' v' . $VERSION;
#	},
#	CREATION_DATE	=> sub {
#	    return format_space_track_json_time( time );
#	},
	EPOCH		=> 'epoch',
	FILE		=> 'file',
	MEAN_MOTION	=> 'meanmotion',
	ECCENTRICITY	=> 'eccentricity',
	INCLINATION	=> 'inclination',
	RA_OF_ASC_NODE	=> 'ascendingnode',
	ARG_OF_PERICENTER	=> 'argumentofperigee',
	MEAN_ANOMALY	=> 'meananomaly',
	EPHEMERIS_TYPE	=> 'ephemeristype',
	CLASSIFICATION_TYPE	=> 'classification',
	ELEMENT_SET_NO	=> 'elementnumber',
	REV_AT_EPOCH	=> 'revolutionsatepoch',
	BSTAR		=> 'bstardrag',
	MEAN_MOTION_DOT	=> 'firstderivative',
	MEAN_MOTION_DDOT	=> 'secondderivative',
	OBJECT_TYPE	=> 'object_type',
	ORDINAL		=> 'ordinal',
	ORIGINATOR	=> 'originator',
	effective_date	=> 'effective',
	intrinsic_magnitude	=> 'intrinsic_magnitude',
    );

    sub _decode_json_time {
	my ( $string ) = @_;
	$string =~ m{ \A \s*
	    ( [0-9]+ ) [^0-9]+ ( [0-9]+ ) [^0-9]+ ( [0-9]+ ) [^0-9]+
	    ( [0-9]+ ) [^0-9]+ ( [0-9]+ ) [^0-9]+ ( [0-9]+ )
		(?: ( [.] [0-9]* ) )?
	    \s* \z }smx
	    or return;
	my @time = ( $1, $2, $3, $4, $5, $6 );
	my $frac = $7;
	$time[0] = __tle_year_to_Gregorian_year( $time[0] );
	$time[1] -= 1;
	my $rslt = greg_time_gm( reverse @time );
	defined $frac
	    and $frac ne '.'
	    and $rslt += $frac;
	return $rslt;
    }

    sub _parse_json {
	my ( undef, @args ) = @_;	# Invocant unused
	defined $have_json
	    or $have_json = eval {
	    require JSON;
	    1;
	} ? 1 : 0;
	$have_json
	    or croak 'Can not load JSON';
	my $json = JSON->new()->utf8( 1 );
	my $attrs = HASH_REF eq ref $args[0] ? shift @args : {};
	my @rslt;

	foreach my $arg ( @args ) {
	    my $decode = $json->decode( $arg );

	    foreach my $hash ( ARRAY_REF eq ref $decode ? @{ $decode } :
		$decode ) {

		my $class = $hash->{astro_coord_eci_class} || __PACKAGE__;
		load_module( $class );
		push @rslt, $class->__from_json( $hash, $attrs );

	    }
	}

	return @rslt;
    }

    sub __from_json {
	my ( $class, $hash, $attrs ) = @_;

	$attrs ||= {};

	if ( exists $hash->{SATNAME} ) {	# TODO Deprecated
	    warnings::enabled( 'deprecated' )
		and croak 'The SATNAME JSON key is deprecated ',
		    'in favor of the OBJECT_NAME key';
	    exists $hash->{OBJECT_NAME}
		or $hash->{OBJECT_NAME} = $hash->{SATNAME};
	    delete $hash->{SATNAME};
	}

	foreach my $key ( @required ) {
	    defined $hash->{$key}
		or return;
	}

	defined $hash->{INTLDES}
	    and $hash->{INTLDES} =~
		s/ \A [0-9]{2} ( [0-9]{2} ) - /$1/smx;

	foreach my $key ( qw{ EPOCH effective_date } ) {
	    defined $hash->{$key}
		and $hash->{$key} = _decode_json_time( $hash->{$key} );
	}
	defined $hash->{EPOCH_MICROSECONDS}
	    and $hash->{EPOCH} += $hash->{EPOCH_MICROSECONDS} /
		1_000_000;

	foreach my $key ( qw{
		ARG_OF_PERICENTER INCLINATION MEAN_ANOMALY
		RA_OF_ASC_NODE
	    } ) {
	    $hash->{$key} *= SGP_DE2RA;
	}

	{
	    my $temp = SGP_TWOPI;
	    foreach my $key ( qw{
		    MEAN_MOTION MEAN_MOTION_DOT MEAN_MOTION_DDOT
		} ) {
		$temp /= SGP_XMNPDA;
		$hash->{$key} *= $temp;
	    }
	}

	my %tle = %{ $attrs };
	foreach my $key ( keys %{ $hash } ) {
	    my $value = $hash->{$key};
	    my $attr = $json_map{$key}
		or next;
	    $tle{$attr} = $value;
	}

	return $class->new( %tle );
    }
}

=item $valid = $tle->validate($options, $time ...);

This method checks to see if the currently-selected model can be run
successfully. If so, it returns 1; if not, it returns 0.

The $options argument is itself optional. If passed, it is a reference
to a hash of option names and values. At the moment the only option used
is

 quiet => 1 to suppress output to STDERR.

If the C<quiet> option is not specified, or is specified as a false
value, validation failures will produce output to STDERR.

Each $time argument is adjusted by passing it through C<<
$tle->max_effective_date >>, and the distinct adjusted times are sorted
into ascending order. The currently-selected model is run at each of the
times thus computed. The return is 0 if any run fails, or 1 if they all
succeed.

If there are no $time arguments, the model is run at the effective date
if that is specified, or the epoch if the effective date is not
specified.

=cut

sub validate {
    my ($self, @args) = @_;
    my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
    my %args;
    if (@args) {
	%args = map { ( $self->max_effective_date( $_ ) => 1 ) } @args;
    } else {
	$args{$self->get('effective') || $self->get('epoch')} = 1;
    }
    eval {
	foreach my $time ( sort { $a <=> $b } keys %args ) {
	    $self->universal( $time );
	}
	1;
    } and return 1;
    $opt->{quiet} or $@ and warn $@;
    return 0;
}

#######################################################################

#	_actan

#	This function wraps the atan2 function, and normalizes the
#	result to the range 0 < result < 2 * pi.

sub _actan {
    my $rslt = atan2 ($_[0], $_[1]);
    $rslt < 0 and $rslt += SGP_TWOPI;
    return $rslt;
}

#	_convert_out

#	Convert model results to kilometers and kilometers per second.

sub _convert_out {
    my ($self, @args) = @_;
    $args[0] *= (SGP_XKMPER / SGP_AE);		# x
    $args[1] *= (SGP_XKMPER / SGP_AE);		# y
    $args[2] *= (SGP_XKMPER / SGP_AE);		# z
    $args[3] *= (SGP_XKMPER / SGP_AE * SGP_XMNPDA / SECSPERDAY);	# dx/dt
    $args[4] *= (SGP_XKMPER / SGP_AE * SGP_XMNPDA / SECSPERDAY);	# dy/dt
    $args[5] *= (SGP_XKMPER / SGP_AE * SGP_XMNPDA / SECSPERDAY);	# dz/dt
    $self->__universal( pop @args );
    $self->eci (@args);

    $self->equinox_dynamical ($self->{epoch_dynamical});

    return $self;
}

# Called by pass() to find the illumination. The arguments are the sun
# object (or nothing), the time, and a reference to the pass information
# hash. The return is either nothing (if $sun is not defined) or
# ( illumination => $illum ).
sub _find_illumination {
    my ( $sun, $when, $info ) = @_;
    $sun
	or return;
    my $illum = $info->[0]{illumination};
    foreach my $evt ( @{ $info } ) {
	$evt->{time} > $when
	    and last;
	$illum = $evt->{illumination};
    }
    return ( illumination	=> $illum );
}

# Called by pass() to calculate azimuth, elevation, and range. The
# arguments are the TLE object, the station object, and the time. If the
# TLE's 'lazy_pass_position' attribute is true, nothing is returned.
# Otherwise the azimuth, elevation, and range are calculated and
# returned as three name/value pairs (i.e. a six-element list).
sub _find_position {
    my ( $tle, $sta, $when ) = @_;
    $tle->get( 'lazy_pass_position' )
	and return;
    $tle->universal( $when );
    my ( $azimuth, $elevation, $range ) = $sta->azel( $tle );
    return (
	azimuth	=> $azimuth,
	elevation	=> $elevation,
	range		=> $range,
    );
}

# Initial value of the 'inertial' attribute. TLEs are assumed to be
# inertial until set otherwise.

sub __initial_inertial{ return 1 };

# Unsupported, experimental, and subject to change or retraction without
# notice. The intent is to provide a way for the Astro::App::Satpass2
# 'list' command to pick an appropriate template to format each line of
# the listing based on the object being listed.
sub __list_type {
    my ( $self ) = @_;
    return $self->{inertial} ? 'inertial' : 'fixed';
}

# _looks_like_real
#
# This returns a boolean which is true if the input looks like a real
# number and is false otherwise. It is based on looks_like_number, but
# excludes things like NaN, and Inf.
sub _looks_like_real {
    my ( $number ) = @_;
    looks_like_number( $number )
	or return;
    $number =~ m/ \A nan \z /smxi
	and return;
    $number =~ m/ \A [+-]? inf (?: inity )? \z /smxi
	and return;
    return 1;
}

# *equinox_dynamical = \&Astro::Coord::ECI::equinox_dynamical;

#	$text = $self->_make_tle();
#
#	This method manufactures a TLE. It's a 'real' TLE if the 'name'
#	attribute is not set, and a 'NASA' TLE (i.e. the 'T' stands for
#	'three') if the 'name' attribute is set. The output is intended
#	to be equivalent to the TLE (if any) that initialized the
#	object, not identical to it. This method is used to manufacture
#	a TLE in the case where $self->get('tle') was called but the
#	object was not initialized by the parse() method.

{

    my %hack = (
	effective => sub {
##	    my ( $self, $name, $value ) = @_;
	    my ( undef, undef, $value ) = @_;	# Invocant & name unused
	    my $whole = floor($value);
	    my ($sec, $min, $hr, undef, undef, $year, undef, $yday) =
		gmtime $value;
	    my $effective = 
		sprintf '%04d/%03d/%02d:%02d:%06.3f',
		$year + 1900, $yday + 1, $hr, $min,
		$sec + ($value - $whole);
	    $effective =~ s/ [.]? 0+ \z //smx;
	    return ( '--effective', $effective );
	},
	rcs => sub {
##	    my ( $self, $name, $value ) = @_;
	    my ( undef, undef, $value ) = @_;	# Invocant & name unused
	    return ( '--rcs', $value );
	},
    );

    my @required_fields = qw{
	firstderivative secondderivative bstardrag inclination
	ascendingnode eccentricity argumentofperigee meananomaly
	meanmotion revolutionsatepoch
    };

    sub _make_tle {
	my $self = shift;
	my $output;

	my $oid = $self->get('id');
	my $name = $self->get( 'name' );
	my @line0;

	if ( defined $name ) {
	    $name =~ s/ \s+ \z //smx;
	    $name ne ''
		and push @line0, substr $name, 0, 24;
	}

	if ( my $code = $self->can( '__encode_operational_status' ) ) {
	    push @line0, sprintf '[%s]', $code->( $self, 'status' );
	}

	foreach my $name ( sort keys %hack ) {
	    defined( my $value = $self->get( $name ) ) or next;
	    push @line0, $hack{$name}->( $self, $name, $value );
	}
	@line0 and $output .= join (' ', @line0) . "\n";

	my %ele;
	{
	    my @missing_fields;
	    foreach ( @required_fields ) {
		defined( $ele{$_} = $self->get( $_ ) )
		    and next;
		push @missing_fields, $_;
	    }

	    if ( @missing_fields ) {
		# If all required fields are missing we presume it is
		# deliberate, and return nothing.
		@required_fields == @missing_fields
		    and return undef;	## no critic (ProhibitExplicitReturnUndef)
		# Otherwise we croak with an error
		croak 'Can not generate TLE for ',
		    defined $oid ? $oid : $name,
		    '; undefined attribute(s) ',
		    join ', ', @missing_fields;
	    }
	    my $temp = SGP_TWOPI;
	    foreach (qw{meanmotion firstderivative secondderivative}) {
		$temp /= SGP_XMNPDA;
		$ele{$_} /= $temp;
	    }
	    foreach (qw{ascendingnode argumentofperigee meananomaly
			inclination}) {
		$ele{$_} /= SGP_DE2RA;
	    }
	    foreach my $key (qw{eccentricity}) {
		local $_ = sprintf '%.7f', $ele{$key};
		s/.*?\.//;
		$ele{$key} = $_;
	    }
	    $ele{epoch} = $self->__make_tle_epoch();
	    $ele{firstderivative} = sprintf (
		'%.8f', $ele{firstderivative});
	    $ele{firstderivative} =~ s/([-+]?)[\s0]*\./$1./;
	    foreach my $key (qw{secondderivative bstardrag}) {
		if ($ele{$key}) {
		    local $_ = sprintf '%.4e', $ele{$key};
		    s/\.//;
		    my ($mantissa, $exponent) = split 'e', $_;
		    $exponent++;
		    $ele{$key} = sprintf '%s%+1d', $mantissa, $exponent;
		} else {
		    $ele{$key} = '00000-0';
		}
	    }
	}
	$output .= _make_tle_checksum ('1%6s%s %-8s %-14s %10s %8s %8s %s %4s',
	    $oid, $self->get('classification'),
	    $self->get('international'),
	    ( map { $ele{$_} } qw{ epoch firstderivative
		secondderivative bstardrag} ),
	    $self->get('ephemeristype'), $self->get('elementnumber'),
	);
	$output .= _make_tle_checksum ('2%6s%9.4f%9.4f %-7s%9.4f%9.4f%12.8f%5s',
	    $oid, ( map { $ele{$_} } qw{ inclination ascendingnode
		eccentricity argumentofperigee meananomaly meanmotion
		revolutionsatepoch } ),
	);
	return $output;
    }
}

sub __make_tle_epoch {
    my ( $self ) = @_;
    my $epoch = $self->get('epoch');
    my $epoch_dayfrac = sprintf '%.8f', ($epoch / SECSPERDAY);
    $epoch_dayfrac =~ s/.*?\././;
    my $epoch_daynum = strftime '%y%j', gmtime ($epoch);
    return $epoch_daynum . $epoch_dayfrac;
}

#	$output = _make_tle_checksum($fmt ...);
#
#	This subroutine calls sprintf using the first argument as a
#	format and the rest as arguments. It then computes the TLE-style
#	checksum, appends it to the output, slaps a newline on the end
#	of the whole thing, and returns it.

sub _make_tle_checksum {
    my ($fmt, @args) = @_;
    my $buffer = sprintf $fmt, @args;
    my $sum = 0;
    foreach (split '', $buffer) {
	if ($_ eq '-') {
	    $sum++;
	} elsif ( m/ [0-9] /smx ) {
	    $sum += $_;
	}
    }
    $sum = $sum % 10;
    return sprintf "%-68s%i\n", substr ($buffer, 0, 68), $sum;
}

#	_normalize_oid
#
#	Normalize an OID by expanding it to five digits.

sub _normalize_oid {
    my ( $oid ) = @_;
    $oid =~ m/ [^0-9] /smx
	and return $oid;
    return sprintf '%05d', $oid;
}

#	_set_illum

#	Setting the {illum} attribute is complex enough that the code
#	got pulled out into its own subroutine. As with all mutators,
#	the arguments are the object reference, the attribute name, and
#	the new value.

__PACKAGE__->alias (sun => 'Astro::Coord::ECI::Sun');
__PACKAGE__->alias (moon => 'Astro::Coord::ECI::Moon');
sub _set_illum {
    my ($self, $name, $body) = @_;
    unless (ref $body) {
	$type_map{$body} and $body = $type_map{$body};
	load_module ($body);
    }
    embodies ($body, 'Astro::Coord::ECI') or croak <<eod;
Error - The illuminating body must be an Astro::Coord::ECI, or a
        subclass thereof, or the words 'sun' or 'moon', which are
	handled as special cases. You tried to use a
	'@{[ref $body || $body]}'.
eod
    ref $body or $body = $body->new ();
    $self->{$name} = $body;
    return 0;
}

sub _set_intldes {
    my ( $self, $name, $val ) = @_;

    if ( defined $val && $val =~ m/ \S /smx ) {

	my $working = $val;

	$working =~ s/ \s+ \z //smx;
	$working =~ s/ \s /0/smxg;

	foreach my $re (
	    qr< ( [0-9]+ ) - ( [0-9]+ ) ( .+ ) >smx,
	    qr< ( [0-9]{2} ) ( [0-9]{3} ) ( .+ ) >smx,
	) {
	    $working =~ m/ \A $re \z /smx
		or next;
	    my ( $year, $num, $piece ) = ( $1, $2, $3 );

	    $year < 100
		and $year += $year < 57 ? 2000 : 1900;

	    $self->{launch_year} = $year;
	    $self->{launch_num} = $num;
	    $self->{launch_piece} = $piece;

	    $self->{$name} = $val;

	    return 0;
	}

    }

    # We bypass the public interface to avoid thrashing

    $self->{launch_year} =
	$self->{launch_num} =
	$self->{launch_piece} = undef;

    $self->{$name} = $val;

    return 0;
}

{
    my %intldes_valid = (
	launch_year	=> sub {
	    my ( $val ) = @_;
	    $val =~ RE_ALL_DIGITS
		and $val <= 9999
		or croak 'Invalid launch_year';
	    $val < 100
		and $val += $val < 57 ? 2000 : 1900;
	    return $val + 0;
	},
	launch_num	=> sub {
	    my ( $val ) = @_;
	    $val =~ RE_ALL_DIGITS
		and $val < 1000
		or croak 'Invalid launch_num';
	    return $val + 0;
	},
	launch_piece	=> sub {
	    my ( $val ) = @_;
	    $val =~ m/ \A [[:alpha:]]+ \z /smx
		or croak 'Invalid launch_piece';
	    return uc $val;
	},
    );

    my $value_or_empty = sub {
	my ( $self, $name ) = @_;
	return defined $self->{$name} ? $self->{$name} : '';
    };

    sub _set_intldes_part {
	my ( $self, $name, $val ) = @_;

	$self->{$name} = defined $val ?
	    $intldes_valid{$name}->( $val ) :
	    $val;

	my %intldes;
	foreach my $key ( qw{ launch_year launch_num launch_piece } ) {
	    $intldes{$key} = $value_or_empty->( $self, $key );
	}
	$intldes{launch_year} eq ''
	    or $intldes{launch_year} %= 100;

	my $tplt = join '',
	    ( $intldes{launch_year} eq '' ? '%2s' : '%02d' ),
	    ( $intldes{launch_num} eq '' ? '%3s' : '%03d' ),
	    '%s';
	$self->{international} = sprintf $tplt, map { $intldes{$_} }
	    qw{ launch_year launch_num launch_piece };

	return 0;
    }

}

# _set_object_type
#
# This acts as a mutator for the object type.
{
    my %name_to_type;
    my @number_to_type;
    foreach my $type (
	BODY_TYPE_UNKNOWN,
	BODY_TYPE_DEBRIS,
	BODY_TYPE_ROCKET_BODY,
	BODY_TYPE_PAYLOAD,
    ) {
	$number_to_type[$type] = $type;
	$name_to_type{ fold_case( $type ) } = $type;
    }
    sub _set_object_type {
	my ( $self, $name, $value ) = @_;
	if ( defined $value ) {
	    if ( $value =~ RE_ALL_DIGITS ) {
		$self->{$name} = $number_to_type[$value];
	    } else {
		$self->{$name} = $name_to_type{ fold_case( $value ) };
	    }
	    unless ( defined $self->{$name} ) {
		carp "Invalid $name '$value'; setting to unknown";
		$self->{$name} = BODY_TYPE_UNKNOWN;
	    }
	} else {
	    $self->{$name} = undef;
	}
	return 0;
    }
}

# _set_optional_float_no_reinit
#
# This acts as a mutator for any attribute whose value is either undef
# or a floating-point number, and which does not cause the model to be
# renitialized when its value changes. We disallow NaN.

sub _set_optional_float_no_reinit {
    my ( $self, $name, $value ) = @_;
    if ( defined $value && ! _looks_like_real( $value ) ) {
	carp "Invalid $name '$value'; must be a float or undef";
	$value = undef;
    }
    $self->{$name} = $value;
    return 0;
}

# _set_optional_unsigned_integer_no_reinit
#
# This acts as a mutator for any attribute whose value is either undef
# or an unsigned integer, and which does not cause the model to be
# reinitialized when its value changes.

sub _set_optional_unsigned_integer_no_reinit {
    my ( $self, $name, $value ) = @_;
    if ( defined $value && $value =~ m/ [^0-9] /smx ) {
	carp "Invalid $name '$value'; must be unsigned integer or undef";
	$value = undef;
    }
    $self->{$name} = $value;
    return 0;
}

sub _next_elevation_screen {
    my ( $sta, $pass_step, @args ) = @_;
    ref $sta
	or confess 'Programming error - station not a reference';
    my ( $suntim, $dawn ) = $sta->next_elevation( @args );
    defined $suntim
	or confess 'Programming error - time of next elevation undefined';
    $dawn or $pass_step = - $pass_step;
    my $sun_screen = $suntim + $pass_step / 2;
    return ( $suntim, $dawn, $sun_screen,
	$dawn ? $sun_screen : $suntim,
    );
}

#######################################################################

#	Initialization of aliases and status

{
    # The following classes initialize themselves on load.
    local $@ = undef;
    eval {	## no critic (RequireCheckingReturnValueOfEval)
	require Astro::Coord::ECI::TLE::Iridium;
    };
}

# The following is all the Celestrak visual list that have magnitudes in
# either McCants' vsnames.mag or quicksat.mag files, with the former
# being preferred. The QuickSat magnitudes assume a different
# illumination and phase angle, and are adjsted by adding 1.4. These
# data are generated by the following:
#
#   $ eg/visual -merge
#
# Last-Modified: Thu, 17 Jun 2021 18:30:16 GMT

# The following constants are unsupported, and may be modified or
# revoked at any time. They exist to support
# xt/author/magnitude_status.t
use constant _CELESTRAK_VISUAL => 'Thu, 17 Jun 2021 18:30:16 GMT';
use constant _MCCANTS_VSNAMES  => 'Thu, 25 May 2017 00:30:11 GMT';
use constant _MCCANTS_QUICKSAT => 'Mon, 14 Sep 2020 13:12:56 GMT';

%magnitude_table = (
  '00694' => 3.5,
  '00733' => 5.0,
  '00877' => 5.0,
  '02802' => 5.5,
  '03230' => 6.0,
  '03597' => 6.5,
  '03598' => 5.0,
  '03669' => 9.0,
  '04327' => 6.5,
  '04814' => 5.0,
  '05118' => 5.0,
  '05560' => 5.0,
  '05730' => 5.0,
  '06073' => 6.4,
  '06153' => 6.0,
  '06155' => 5.0,
  '07004' => 5.0,
  '08063' => 5.5,
  '08459' => 6.0,
  '10114' => 5.5,
  '10861' => 5.0,
  '10967' => 4.0,
  '11251' => 5.4,
  '11267' => 5.5,
  '11574' => 5.0,
  '11672' => 5.0,
  '11822' => 5.5,
  '11849' => 5.5,
  '11933' => 5.0,
  '12054' => 4.0,
  '12139' => 5.0,
  '12154' => 5.5,
  '12155' => 5.0,
  '12389' => 4.5,
  '12465' => 5.0,
  '12585' => 6.0,
  '12904' => 5.0,
  '13068' => 5.0,
  '13154' => 5.5,
  '13402' => 6.0,
  '13403' => 5.0,
  '13552' => 4.9,
  '13553' => 5.4,
  '13819' => 5.5,
  '14032' => 4.4,
  '14208' => 4.9,
  '14372' => 5.5,
  '14484' => 5.0,
  '14699' => 5.0,
  '14819' => 5.5,
  '14820' => 5.5,
  '15354' => 5.0,
  '15483' => 5.5,
  '15494' => 4.4,
  '15772' => 5.0,
  '15945' => 5.5,
  '16111' => 5.0,
  '16182' => 4.0,
  '16496' => 5.5,
  '16719' => 4.9,
  '16792' => 5.5,
  '16882' => 5.5,
  '16908' => 5.0,
  '17295' => 5.0,
  '17567' => 5.5,
  '17589' => 5.5,
  '17590' => 4.0,
  '17912' => 5.5,
  '17973' => 5.0,
  '18153' => 5.5,
  '18187' => 5.0,
  '18421' => 4.9,
  '18749' => 5.5,
  '18958' => 5.5,
  '19046' => 5.0,
  '19120' => 3.5,
  '19210' => 4.5,
  '19257' => 5.5,
  '19573' => 5.0,
  '19574' => 5.0,
  '19650' => 3.5,
  '20261' => 6.0,
  '20262' => 6.4,
  '20303' => 4.9,
  '20323' => 5.5,
  '20443' => 4.9,
  '20453' => 5.5,
  '20465' => 5.0,
  '20466' => 5.0,
  '20511' => 5.0,
  '20580' => 3.0,
  '20625' => 3.5,
  '20663' => 5.5,
  '20666' => 5.5,
  '20775' => 5.0,
  '21088' => 5.0,
  '21397' => 5.5,
  '21422' => 5.0,
  '21423' => 5.5,
  '21574' => 6.0,
  '21610' => 4.5,
  '21819' => 5.5,
  '21820' => 5.5,
  '21876' => 5.5,
  '21938' => 5.0,
  '21949' => 5.4,
  '22219' => 4.4,
  '22220' => 3.5,
  '22236' => 4.4,
  '22285' => 3.5,
  '22286' => 5.0,
  '22566' => 3.5,
  '22626' => 5.0,
  '22803' => 3.5,
  '22830' => 5.0,
  '23087' => 5.0,
  '23088' => 3.5,
  '23343' => 3.5,
  '23405' => 3.5,
  '23560' => 4.5,
  '23561' => 4.5,
  '23705' => 3.5,
  '24298' => 3.5,
  '24680' => 5.5,
  '25063' => 4.5,
  '25064' => 5.0,
  '25400' => 3.5,
  '25407' => 3.5,
  '25544' => -1.8, # From Heavens-Above
  '25723' => 5.0,
  '25732' => 5.0,
  '25860' => 4.5,
  '25861' => 3.5,
  '25876' => 4.9,
  '25977' => 6.4,
  '25979' => 4.5,
  '25994' => 3.5,
  '26070' => 3.5,
  '26102' => 6.4,
  '26473' => 3.5,
  '26474' => 3.5,
  '26874' => 4.5,
  '26905' => 4.4,
  '26906' => 3.5,
  '26907' => 4.4,
  '26934' => 4.5,
  '27006' => 3.5,
  '27386' => 4.5,
  '27387' => 4.0,
  '27421' => 5.5,
  '27422' => 4.5,
  '27424' => 4.0,
  '27432' => 4.5,
  '27550' => 5.5,
  '27597' => 3.5,
  '27601' => 3.5,
  '27640' => 5.5,
  '27665' => 5.5,
  '27698' => 4.5,
  '28059' => 5.5,
  '28096' => 3.5,
  '28222' => 5.0,
  '28230' => 5.0,
  '28353' => 3.5,
  '28376' => 5.0,
  '28415' => 5.0,
  '28480' => 4.5,
  '28499' => 4.5,
  '28538' => 3.5,
  '28646' => 3.5,
  '28647' => 3.5,
  '28738' => 4.0,
  '28773' => 5.0,
  '28888' => 4.4,
  '28931' => 3.9,
  '28932' => 4.5,
  '28939' => 6.9,
  '29093' => 4.0,
  '29228' => 4.5,
  '29252' => 5.5,
  '29393' => 4.5,
  '29507' => 3.5,
  '29659' => 5.5,
  '30586' => 5.5,
  '30587' => 5.5,
  '30778' => 4.0,
  '31114' => 4.0,
  '31598' => 4.5,
  '31702' => 3.5,
  '31789' => 6.4,
  '31792' => 4.0,
  '31793' => 3.5,
  '31798' => 5.5,
  '32053' => 5.5,
  '32284' => 5.5,
  '32290' => 5.5,
  '32376' => 5.5,
  '32751' => 6.0,
  '33053' => 6.0,
  '33106' => 5.5,
  '33245' => 5.5,
  '33272' => 4.5,
  '33410' => 4.0,
  '33412' => 6.5,
  '33500' => 3.5,
  '33505' => 5.5,
  '34602' => 6.5,
  '34840' => 5.5,
  '36089' => 3.5,
  '36095' => 3.5,
  '36104' => 5.5,
  '36105' => 4.2,
  '36123' => 5.5,
  '36125' => 4.5,
  '36416' => 4.5,
  '36520' => 5.5,
  '36597' => 5.0,
  '36800' => 5.5,
  '36835' => 4.5,
  '37181' => 5.5,
  '37215' => 4.5,
  '37216' => 6.5,
  '37253' => 3.5,
  '37348' => 4.5,
  '37673' => 4.0,
  '37731' => 3.5,
  '37766' => 4.5,
  '37782' => 4.0,
  '37814' => 4.2,
  '37932' => 5.0,
  '37942' => 4.0,
  '37955' => 4.2,
  '38039' => 4.5,
  '38109' => 4.0,
  '38341' => 4.5,
  '38355' => 4.5,
  '38737' => 5.0,
  '38755' => 5.5,
  '38758' => 4.5,
  '38770' => 3.5,
  '38773' => 4.5,
  '38862' => 4.5,
  '39000' => 4.0,
  '39014' => 4.5,
  '39019' => 4.5,
  '39063' => 4.0,
  '39203' => 4.5,
  '39364' => 4.5,
  '40354' => 4.9,
  '40382' => 3.4,
  '41395' => 3.9,
  '42689' => 4.9,
  '48274' => 3.2, # From Heavens-Above
);

1;

__END__

=back

=head2 Attributes

This class has the following additional public attributes. The
description gives the data type. It may also give one of the following
if applicable:

parse - if the attribute is set by the parse() method;

read-only - if the attribute is read-only;

static - if the attribute may be set on the class as well as an object.

Note that the orbital elements provided by NORAD are tweaked for use by
the models implemented by this class. If you plug them in to the
same-named parameters of other models, your mileage may vary
significantly.

=over

=item appulse (numeric, static)

This attribute contains the angle of the widest appulse to be reported
by the pass() method, in radians.

The default is equivalent to 10 degrees.

=item argumentofperigee (numeric, parse)

This attribute contains the argument of perigee (angular distance from
ascending node to perigee) of the orbit, in radians.

=item ascendingnode (numeric, parse)

This attribute contains the right ascension of the ascending node
of the orbit at the epoch, in radians.

=item backdate (boolean, static)

This attribute determines whether the pass() method will go back before
the epoch of the data. If false, the pass() method will silently adjust
its start time forward. If this places the start time after the end
time, an empty list is returned.

B<Note> that this is a change from the behavior of
Astro::Coord::ECI::TLE version 0.010, which threw an exception if the
backdate adjustment placed the start time after the end time.

The default is 1 (i.e. true).

=item bstardrag (numeric, parse)

This attribute contains the B* drag term, decoded into a number.

=item classification (string, parse)

This attribute contains the security classification. You should
expect to see only the value 'U', for 'Unclassified.'

=item ds50 (numeric, readonly, parse)

This attribute contains the C<epoch>, in days since 1950.
Setting the C<epoch> also modifies this attribute.

=item eccentricity (numeric, parse)

This attribute contains the orbital eccentricity, with the
implied decimal point inserted.

=item effective (numeric, parse)

This attribute contains the effective date of the TLE, as a Perl time in
seconds since the epoch. As a convenience, it can be set in the format
used by NASA to specify this, as year/day/hour:minute:second, where all
fields are numeric, and the day is the day number of the year, January 1
being 1, and December 31 being either 365 or 366.

=item elementnumber (numeric, parse)

This attribute contains the element set number of the data set. In
theory, this gets incremented every time a data set is issued.

=item ephemeristype (numeric, parse)

This attribute records a field in the data set which is supposed to
specify which model to use with this data. In practice, it seems
always to be zero.

=item epoch (numeric, parse)

This attribute contains the epoch of the orbital elements - that is,
the 'as-of' date and time - as a Perl date. Setting this attribute
also modifies the epoch_dynamical and ds50 attributes.

=item epoch_dynamical (numeric, readonly, parse)

This attribute contains the dynamical time corresponding to the
C<epoch>. Setting the C<epoch> also modifies this attribute.

=item file (numeric)

This attribute contains the file number of the TLE data. It is typically
present only if the TLE object was parsed from a Space Track JSON file;
otherwise it is undefined.

=item firstderivative (numeric, parse)

This attribute contains the first time derivative of the mean
motion, in radians per minute squared.

=item geometric (boolean, static)

Tells the pass() method whether to calculate rise and set relative
to the geometric horizon (if true) or the horizon attribute (if
false)

The default is 0 (i.e. false).

=item gravconst_r (numeric, static)

Tells the sgp4r() method which set of gravitational constants to use.
Legal values are:

 72 - Use WGS-72 values;
 721 - Use old WGS-72 values;
 84 - Use WGS-84 values.

The 'old WGS-72 values' appear from the code comments to be those
embedded in the original SGP4 model given in "Space Track Report Number
3".

B<Note well> that "Revisiting Spacetrack Report #3" says "We use  WGS-72
as the default value." It does not state whether it means the values
specified by 72 or the values specified by 721, but the former gives
results closer to the test results included with the code.

Comparing the positions computed by this code to the positions given in
the published test results, the following maximum deviations are found,
depending on the gravconst_r value used:

 72 - 4 mm (oid 23333, X at epoch)
 721 - 57 cm (OID 28350, X at 1320 minutes from epoch)
 84 - 3.22 km (OID 23333, X at epoch)

The default is 72, to agree with "Revisiting Spacetrack Report #3".

=item id (numeric, parse)

This attribute contains the NORAD SATCAT catalog ID.

=item illum (string, static)

This attribute specifies the source of illumination for the body, for
the purpose of detecting things like Iridium flares. This is
distinguished from the parent class' C<'sun'> attribute, which is used
to determine night or day.

You may specify the class name C<'Astro::Coord::ECI'> or the name of any
subclass (though in practice only C<'Astro::Coord::ECI::Sun'> or
C<'Astro::Coord::ECI::Moon'> will do anything useful), or an alias()
thereof, or you may specify an object of the appropriate class. When you
access this attribute, you get an object.

In addition to the full class names, 'sun' and 'moon' are set up as
aliases for L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun> and
L<Astro::Coord::ECI::Moon|Astro::Coord::ECI::Moon> respectively. Other
aliases can be set up using the alias() mechanism.  The value 'sun' (or
something equivalent) is probably the only useful value, but I know
people have looked into Iridium 'Moon flares', so I exposed the
attribute.

The default is 'sun'.

=item interval (numeric, static)

If positive, this attribute specifies that the pass() method return
positions at this interval (in seconds) across the sky. The associated
event code of these will be PASS_EVENT_NONE. If zero or negative, pass()
will only return times when some event of interest occurs.

The default is 0.

=item inclination (numeric, parse)

This attribute contains the orbital inclination in radians.

=item international (string, parse)

This attribute contains the international launch designator.
This consists of three parts: a two-digit number (with leading zero if
needed) giving the last two digits of the launch year (in the range
1957-2056); a three-digit number (with leading zeros if needed) giving
the order of the launch within the year, and one to three letters
designating the "part" of the launch, with payload(s) getting the
first letters, and spent boosters, debris, etc getting the rest.

=item intrinsic_magnitude (numeric or undef)

If defined, this is the typical magnitude of the body at half phase and
range 1000 kilometers, when illuminated by the Sun. I am not sure how
standard this definition really is.  This is the definition used by Ted
Molczan, but Mike McCants' Quicksat data uses maximum magnitude full
phase.

=item lazy_pass_position (boolean, static)

This attribute tells the pass() method that the C<{azimuth}>,
C<{elevation}>, and C<{range}> keys in the pass event hashes need not
be generated.

This attribute was intended for the case where the user wants event
positions in coordinate systems other than, or in addition to, azimuth,
elevation, and range. In this case, it may be faster for the user to set
this attribute, and then compute the event positions after the C<pass()>
method has generated the events. Note that if you do this, you will have
to call C<universal()> on the event's C<{body}>, passing it the event's
C<{time}>, before retrieving the coordinates you want.

The default is 0 (i.e. false).

=item meananomaly (numeric, parse)

This attribute contains the mean orbital anomaly at the epoch, in
radians. In slightly less technical terms, this is the angular
distance a body in a circular orbit of the same period (that is
what the 'mean' means) would be from perigee at the epoch, measured
in the plane of the orbit.

=item meanmotion (numeric, parse)

This attribute contains the mean motion of the body, in radians per
minute.

=item model (string, static)

This attribute contains the name of the model to be run (i.e. the name
of the method to be called) when the time_set() method is called, or a
false value if no model is to be run. Legal model names are: model,
model4, model4r, model8, null, sgp, sgp4, sgp4r, sgp8, sdp4, and sdp8.

The default is 'model'. Setting the value on the class changes the
default.

=item model_error (number)

The sgp4r() model sets this to the number of the error encountered, with
0 representing success. See the documentation to that model for the
values set. All other models simply set this to undef. This is B<not> a
read-only attribute, so the interested user can clear the value if
desired.

The default is undef.

=item name (string, parse (three-line sets only))

This attribute contains the common name of the body.

=item object_type

This attribute contains the object type of the TLE data. It is typically
present only if the TLE object was parsed from a Space Track JSON file;
otherwise it is undefined. However, if it is defined it will be returned
by the C<body_type()> method.

When setting this, possible values are those returned by C<body_type()>
-- either the dualvar constants themselves, or the numeric or
case-insensitive strings corresponding to them. Whatever is set, what is
stored and returned will be one of the C<BODY_TYPE_*> constants. Any
unrecognized value will be stored as C<BODY_TYPE_UNKNOWN>, with a warning.

=item ordinal (numeric)

This attribute contains the ordinal number of the TLE data. It is
typically present only if the TLE object was parsed from a Space Track
JSON file; otherwise it is undefined.

=item originator (string)

This attribute contains the name of the originator of the TLE data. It
is typically present only if the TLE object was parsed from a Space
Track JSON file; otherwise it is undefined.

=item pass_variant (bits)

This attribute tweaks the pass output as specified by its value, which
should be the bitwise 'or' (i.e. C<|>) of the following values:

* C<PASS_VARIANT_VISIBLE_EVENTS> - Specifies that events which are not
visible (that is, which take place either during daylight or with the
body in shadow) are not reported. Illumination changes, however, are
always reported. This has no effect unless the C<visible> attribute is
true.

* C<PASS_VARIANT_FAKE_MAX> - Specifies that if
C<PASS_VARIANT_VISIBLE_EVENTS> filters out the max, a new max event, at
the same time as either the first or last reported event, will be
inserted. This has no effect unless C<PASS_VARIANT_VISIBLE_EVENTS> is
specified, and the C<visible> attribute is true.

* C<PASS_VARIANT_START_END> - Specifies that the first and last events
of the pass are to be identified as C<PASS_EVENT_START> and
C<PASS_EVENT_END> respectively. If the C<visible> attribute is true and
C<PASS_VARIANT_VISIBLE_EVENTS> is in effect, C<PASS_EVENT_START> will
replace either C<PASS_EVENT_RISE> or C<PASS_EVENT_LIT>, and
C<PASS_EVENT_END> will replace either C<PASS_EVENT_SET>,
C<PASS_EVENT_SHADOWED>, or C<PASS_EVENT_DAY>. Otherwise, they replace
C<PASS_EVENT_RISE> and C<PASS_EVENT_SET> respectively.

* C<PASS_VARIANT_NO_ILLUMINATION> - Specifies that no illumination
calculations are to be made at all. This means no C<PASS_EVENT_LIT>,
C<PASS_EVENT_SHADOWED>, or C<PASS_EVENT_DAY> events are generated, and
that the C<illumination> key on other events will not be present. I find
that setting this (with C<< visible => 0 >>) saves about 20% in wall
clock time versus not setting it. Your mileage may, of course, vary.
This has no effect unless the C<visible> attribute is false.

* C<PASS_VARIANT_TRUNCATE> - Specifies that any pass in progress at the
beginning or end of the calculation interval is to be truncated to the
interval. If the calculation interval starts with the body already above
the horizon, the initial event of that pass will be C<PASS_EVENT_START>
rather than C<PASS_EVENT_RISE>. Similarly, if the calculation interval
ends with the body still above the horizon, the final event of that pass
will be C<PASS_EVENT_END>. With this variant in effect, 'passes' will be
computed for synchronous satellites. This variant is to be considered
B<experimental.>

* C<PASS_VARIANT_BRIGHTEST> - Specifies that the the moment the
satellite is brightest be computed as part of the pass statistics. The
computation is to the nearest second, and is not done if
C<PASS_VARIANT_NO_ILLUMINATION> is set, the satellite has no intrinsic
magnitude set, or the satellite is not illuminated during the pass.

* C<PASS_VARIANT_NONE> - Specifies that no pass variant processing take
place.

The above constants are not exported by default, but are exported by the
C<:constants> tag.

The default is C<PASS_VARIANT_NONE>

=item rcs (string, parse)

This attribute represents the radar cross-section of the body, in square
meters.

=item reblessable (boolean)

This attribute says whether the rebless() method is allowed to rebless
this object. If false, the object will not be reblessed when its
id changes.

Note that if this attribute is false, setting it true will cause the
object to be reblessed.

The default is true (i.e. 1).

=item revolutionsatepoch (numeric, parse)

This attribute contains number of revolutions the body has made since
launch, at the epoch.

=item secondderivative (numeric, parse)

This attribute contains the second time derivative of the mean
motion, in radians per minute cubed.

=item pass_threshold (numeric or undef)

If defined, this attribute defines the elevation in radians that the
satellite must reach above the horizon for its passes to be reported. If
the C<visible> attribute is true, the satellite must be visible above
this elevation.

If undefined, any pass above the horizon will be reported (i.e. you get
the same behavior as before this attribute was introduced in version
0.046.)

B<Note> a slight change in the behavior of this attribute from version
0.046. In that version, it did not matter whether the satellite was
visible, even if the C<visible> attribute was true.

You might use this attribute if you want to use a nominal horizon of .35
radians (20 degrees), but are only interested in passes that reach an
elevation of .70 radians (40 degrees).

The default is C<undef>.

=item tle (string, readonly, parse)

This attribute contains the input data used by the parse() method to
generate this object. If the object was not created by the parse()
method, a (hopefully) equivalent TLE will be constructed and returned if
enough attributes have been set, otherwise an exception will be raised.

=item visible (boolean, static)

This attribute tells the pass() method whether to report only passes
which are illuminated (if true) or all passes (if false).

The default is 1 (i.e. true).

=back

=head1 ACKNOWLEDGMENTS

The author wishes to acknowledge the following individuals.

Dominik Brodowski (L<https://www.brodo.de/>), whose SGP C-lib
(available at L<https://www.brodo.de/space/sgp/>) provided a
reference implementation that I could easily run, and pick
apart to help get my own code working. Dominik based his work
on Dr. Kelso's Pascal implementation.

Felix R. Hoots and Ronald L. Roehric, the authors of "SPACETRACK
REPORT NO. 3 - Models for Propagation of NORAD Element Sets,"
which provided the basis for the Astro::Coord::ECI::TLE module.

David A. Vallado, Paul Crawford, Richard Hujsak, and T. S. Kelso, the
authors of "Revisiting Spacetrack Report #3", presented at the 2006
AIAA/AAS Astrodynamics Specialist Conference.

Dr. T. S. Kelso, who made these two key reports available at
L<http://celestrak.com/NORAD/documentation/spacetrk.pdf> and
L<http://celestrak.com/publications/AIAA/2006-6753/> respectively. Dr.
Kelso's Two-Line Element Set Format FAQ
(L<http://celestrak.com/columns/v04n03/>) was also extremely helpful, as
was his discussion of the coordinate system used
(L<http://celestrak.com/columns/v02n01/>) and (indirectly) his Pascal
implementation of these models.

The TLE data used in testing the C<sgp4r> model are from "Revisiting
Spacetrack Report #3" (made available at the CelesTrak web site as cited
above), and are used with the kind permission of Dr. Kelso.

=head1 SEE ALSO

I am aware of no other modules that perform calculations with NORAD
orbital element sets. The L<Astro::Coords|Astro::Coords> package by Tim
Jenness provides calculations using orbital elements, but the NORAD
elements are tweaked for use by the models implemented in this package.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-satpass>,
L<https://github.com/trwyant/perl-Astro-Coord-ECI/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
