=head1 NAME

Astro::Coord::ECI::Moon - Compute the position of the Moon.

=head1 SYNOPSIS

 use Astro::Coord::ECI;
 use Astro::Coord::ECI::Moon;
 use Astro::Coord::ECI::Utils qw{deg2rad};
 
 # 1600 Pennsylvania Ave, Washington DC USA
 # latitude 38.899 N, longitude 77.038 W,
 # altitude 16.68 meters above sea level
 my $lat = deg2rad (38.899);    # Radians
 my $long = deg2rad (-77.038);  # Radians
 my $alt = 16.68 / 1000;        # Kilometers
 my $moon = Astro::Coord::ECI::Moon->new ();
 my $sta = Astro::Coord::ECI->
     universal (time ())->
     geodetic ($lat, $long, $alt);
 my ($time, $rise) = $sta->next_elevation ($moon);
 print "Moon @{[$rise ? 'rise' : 'set']} is ",
     scalar localtime $time, "\n";

=head1 DESCRIPTION

This module implements the position of the Moon as a function of time,
as described in Jean Meeus' "Astronomical Algorithms," second edition.
It is a subclass of L<Astro::Coord::ECI|Astro::Coord::ECI>, with the id,
name, and diameter attributes initialized appropriately, and the
time_set() method overridden to compute the position of the Moon at the
given time.

=head2 Methods

The following methods should be considered public:

=over

=cut

package Astro::Coord::ECI::Moon;

use strict;
use warnings;

our $VERSION = '0.128';

use base qw{Astro::Coord::ECI};

use Astro::Coord::ECI::Utils qw{ @CARP_NOT :mainstream };
use Carp;
use POSIX qw{floor strftime};

#	Load the periodic terms from the table.

my %terms;
{	# Begin local symbol block.
my $where;
local $_ = undef;	# while (<>) ... does not localize $_.
while (<DATA>) {
    chomp;
    s/ \A \s+ //smx;
    s/ \s+ \z //smx;
    next unless $_;
    next if m/ \A \s* [#] /smx;
    s/^-// and do {
	last if $_ eq 'end';
	$where = $terms{$_} ||= [];
	next;
	};
    s/_//g;
    push @$where, [split '\s+', $_];
    }
}	# End local symbol block.

my %static = (
    id => 'Moon',
    name => 'Moon',
    diameter => 3476,
);

my $weaken = eval {
    require Scalar::Util;
    Scalar::Util->can('weaken');
};

our $Singleton = $weaken;

my %object;	# By class

=item $moon = Astro::Coord::ECI::Moon->new ();

This method instantiates an object to represent the coordinates of the
Moon. This is a subclass of Astro::Coord::ECI, with the id and name
attributes set to 'Moon', and the diameter attribute set to 3476 km
per Jean Meeus' "Astronomical Algorithms", 2nd Edition, Appendix I,
page 407.

Any arguments are passed to the set() method once the object has been
instantiated. Yes, you can override the "hard-wired" id and name in
this way.

If C<$Astro::Coord::ECI::Moon::Singleton> is true, you get a singleton
object; that is, only one object is instantiated and subsequent calls to
C<new()> just return that object. If higher-accuracy subclasses are ever
implemented, there will be one singleton for each class.

The singleton logic only works if L<Scalar::Util|Scalar::Util> exports
C<weaken()>. If it does not, the setting of
C<$Astro::Coord::ECI::Moon::Singleton> is silently ignored. The default
is true if L<Scalar::Util|Scalar::Util> can be loaded and exports
C<weaken()>, and false otherwise.

=cut

sub new {
    my ($class, @args) = @_;
    ref $class and $class = ref $class;
    if ( $Singleton && $weaken && __classisa( $class, __PACKAGE__ ) ) {
	my $self;
	if ( $self = $object{$class} ) {
	    $self->set( @args ) if @args;
	    return $self;
	} else {
	    $self = $object{$class} = $class->SUPER::new (%static, @args);
	    $weaken->( $object{$class} );
	    return $self;
	}
    } else {
	return $class->SUPER::new (%static, @args);
    }
}

=item @almanac = $moon->almanac ($station, $start, $end);

This method produces almanac data for the Moon for the given observing
station, between the given start and end times. The station is assumed
to be Earth-Fixed - that is, you can't do this for something in orbit.

The C<$station> argument may be omitted if the C<station> attribute has
been set. That is, this method can also be called as

 @almanac = $moon->almanac( $start, $end )

The start time defaults to the current time setting of the $moon
object, and the end time defaults to a day after the start time.

The almanac data consists of a list of list references. Each list
reference points to a list containing the following elements:

 [0] => time
 [1] => event (string)
 [2] => detail (integer)
 [3] => description (string)

The @almanac list is returned sorted by time.

The following events, details, and descriptions are at least
potentially returned:

 horizon: 0 = Moon set, 1 = Moon rise;
 transit: 1 = Moon transits meridian;
 quarter: 0 = new moon, 1 = first quarter,
          2 = full moon, 3 = last quarter.

=cut

sub __almanac_event_type_iterator {
    my ( $self, $station ) = @_;

    my $inx = 0;

    my $horizon = $station->__get_almanac_horizon();

    my @events = (
	[ $station, next_elevation => [ $self, $horizon, 1 ],
	    horizon	=> '__horizon_name' ],
	[ $station, next_meridian => [ $self ],
	    transit	=> '__transit_name' ],
	[ $self, next_quarter => [], quarter => '__quarter_name' ],
    );

    return sub {
	$inx < @events
	    and return @{ $events[$inx++] };
	return;
    };
}

use Astro::Coord::ECI::Mixin qw{ almanac };

=item @almanac = $moon->almanac_hash($station, $start, $end);

This convenience method wraps $moon->almanac(), but returns a list of
hash references, sort of like Astro::Coord::ECI::TLE->pass()
does. The hashes contain the following keys:

  {almanac} => {
    {event} => the event type;
    {detail} => the event detail (typically 0 or 1);
    {description} => the event description;
  }
  {body} => the original object ($moon);
  {station} => the observing station;
  {time} => the time the quarter occurred.

The {time}, {event}, {detail}, and {description} keys correspond to
elements 0 through 3 of the list returned by almanac().

=cut

use Astro::Coord::ECI::Mixin qw{ almanac_hash };

=item $coord2 = $coord->clone ();

If singleton objects are enabled, this override of the superclass'
method simply returns the invocant. Otherwise it does a deep clone of an
object, producing a different but identical object.

Prior to version 0.099_01 it always returned a clone. Yes,
this is a change in long-standing functionality, but a long-standing bug
is still a bug.

=cut

sub clone {
    my ( $self ) = @_;
    $Singleton
	and $weaken
	and return $self;
    return $self->SUPER::clone();
}

=item $elevation = $moon->correct_for_refraction( $elevation )

This override of the superclass' method simply returns the elevation
passed to it. Since the Moon has no atmosphere to speak of, there should
be no diffraction to speak of either.

See the L<Astro::Coord::ECI|Astro::Coord::ECI> C<azel()> and
C<azel_offset()> documentation for whether this class'
C<correct_for_refraction()> method is actually called by those methods.

=cut

sub correct_for_refraction {
    my ( undef, $elevation ) = @_;	# Invocant unused
    return $elevation;
}

=item ($time, $quarter, $desc) = $moon->next_quarter ($want);

This method calculates the time of the next quarter-phase of the Moon
after the current time setting of the $moon object. The returns are the
time, which quarter-phase it is as a number from 0 (new moon) to
3 (last quarter), and a string describing the phase. If called in
scalar context, you just get the time.

The optional $want argument says which phase you want.

As a side effect, the time of the $moon object ends up set to the
returned time.

The method of calculation is successive approximation, and actually
returns the second B<after> the quarter.

=cut

use constant NEXT_QUARTER_INCREMENT => 86400 * 6;	# 6 days.

*__next_quarter_coordinate = __PACKAGE__->can( 
    'phase' );

use Astro::Coord::ECI::Mixin qw{ next_quarter };

=item $hash_reference = $moon->next_quarter_hash($want);

This convenience method wraps $moon->next_quarter(), but returns the
data in a hash reference, sort of like Astro::Coord::ECI::TLE->pass()
does. The hash contains the following keys:

  {body} => the original object ($moon);
  {almanac} => {
    {event} => 'quarter',
    {detail} => the quarter number (0 through 3);
    {description} => the quarter description;
  }
  {time} => the time the quarter occurred.

The {time}, {detail}, and {description} keys correspond to elements 0
through 2 of the list returned by next_quarter().

=cut

use Astro::Coord::ECI::Mixin qw{ next_quarter_hash };

=item $period = $moon->period ()

This method returns the sidereal period of the Moon, per Appendix I
(pg 408) of Jean Meeus' "Astronomical Algorithms," 2nd edition.

=cut

sub period {return 2360591.5968}	# 27.321662 * 86400

sub __horizon_name_tplt {
    my ( $self ) = @_;
    return $self->__object_is_self_named() ?
	[ '%s set', '%s rise' ] :
	$self->SUPER::__horizon_name_tplt();
}

sub __quarter_name {
    my ( $self, $event, $tplt ) = @_;
    $tplt ||= [ 'New %s', 'First quarter %s', 'Full %s', 'Last quarter %s' ];
    return $self->__event_name( $event, $tplt );
}

=item ($phase, $illum) = $moon->phase ($time);

This method calculates the current phase of the moon and its illuminated
fraction. If the time is omitted, the current time of the $moon object
is used.

The phase is returned as a number from C<0> to C<2 * PI> radians, with
C<0> being New Moon, C<PI / 2> being First Quarter, and so on. The
illuminated fraction is a number from C<0> (New Moon) to C<1> (Full
Moon).

If called in scalar context, you get the phase.

This can be called as a class method, but if you do this the time
must be specified.

Jean Meeus' "Astronomical Algorithms", 2nd Edition, Chapter 49 page
349, defines the phases of the moon in terms of the difference between
the geocentric longitudes of the Moon and Sun - specifically, that
new, first quarter, full, and last quarter are the moments when this
difference is 0, 90, 180, and 270 degrees respectively.

Not quite above reproach, this module simply defines the phase of the
Moon as the difference between these two quantities, even if it is not
a multiple of 90 degrees. This is different than the "phase angle" of
the Moon, which Meeus defines as the elongation of the Earth from the
Sun, as seen from the Moon. Because we take the "phase angle" as just
pi - the phase (in radians), we introduce an error of about 0.3% in
the illumination calculation.

=cut

sub phase {
    my ($self, $time) = @_;

    (ref $self || $time) or croak <<eod;
Error - You must specify a time if you call phase() as a class method.
eod

    $self = $self->new () unless ref $self;

    $self->universal ($time) if $time;

    my $sun = $self->get( 'sun' )->universal( $self->universal() );

    my (undef, $longs) = $sun->ecliptic ();
    my (undef, $longm) = $self->ecliptic ();

    my $phase = mod2pi ($longm - $longs);
    return wantarray ? ($phase, (1 + cos ($self->PI - $phase)) / 2) : $phase;
}

=item $moon->time_set ()

This method sets coordinates of the object to the coordinates of the
Moon at the object's currently-set universal time.  The velocity
components are arbitrarily set to 0, since Meeus' algorithm does not
provide this information. The 'equinox_dynamical' attribute is set to
the currently-set dynamical time.

Although there's no reason this method can't be called directly, it
exists to take advantage of the hook in the B<Astro::Coord::ECI>
object, to allow the position of the Moon to be computed when the
object's time is set.

The computation comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 47, pages 337ff. Meeus gives the accuracy as 10
seconds of arc in latitude, and 4 seconds of arc in longitude. He
credits the algorithm to M. Chalpront-Touze and J. Chalpront, "The
Lunar Ephemeris ELP 2000" from I<Astronomy and Astrophysics> volume
124, pp 50-62 (1983), but the formulae for the mean arguments to
J. Chalpront, M. Chalpront-Touze, and G. Francou, I<Introduction dans
ELP 2000-82B de nouvelles valeurs des parametres orbitaux de la Lune
et du barycentre Terre-Lune>, Paris, January 1998.

=cut

sub time_set {
    my $self = shift;

    my $time = $self->dynamical;

    my $T = jcent2000 ($time);			# Meeus (22.1)

#	Moon's mean longitude.

    my $Lprime = mod2pi (deg2rad (			# Meeus (47.1)
	(((- ($T / 65_194_000) +
	1 / 538_841) * $T - 0.0015786) * $T +
	481267.88123421) * $T + 218.3164477));

#	Moon's mean elongation.

    my $D = mod2pi (deg2rad (((($T / 113_065_000 +	# Meeus (47.2)
	1 / 545_868) * $T - 0.0018819) * $T +
	445267.1114034) * $T + 297.8501921));

#	Sun's mean anomaly.

    my $M = mod2pi (deg2rad ((($T / 24_490_000 -		# Meeus (47.3)
	0.000_1536) * $T + 35999.050_2909) * $T +
	357.5291092));

#	Moon's mean anomaly.

    my $Mprime = mod2pi (deg2rad ((((- $T / 14_712_000 +	# Meeus (47.4)
	1 / 69_699) * $T + 0.008_7414) * $T +
	477198.867_5055) * $T + 134.963_3964));

#	Moon's argument of latitude (mean distance
#	from ascending node).

    my $F = mod2pi (deg2rad (((($T / 863_310_000 -	# Meeus (47.5)
	1 / 3_526_000) * $T - 0.003_6539) * $T +
	483202.017_5233) * $T + 93.272_0950));

#	Eccentricity correction factor.

    my $E = (- 0.000_0074 * $T - 0.002_516) * $T + 1;	# Meeus (47.6)
    my @efac = (1, $E, $E * $E);

#	Compute "further arguments".

    my $A1 = mod2pi (deg2rad (131.849 * $T + 119.75));		# Venus
    my $A2 = mod2pi (deg2rad (479264.290 * $T + 53.09));	# Jupiter
    my $A3 = mod2pi (deg2rad (481266.484 * $T + 313.45));	# undocumented

#	Compute periodic terms for longitude (sigma l) and
#	distance (sigma r).

    my ($sigmal, $sigmar) = (0, 0);
    foreach (@{$terms{lr}}) {
	my ($mulD, $mulM, $mulMprime, $mulF, $sincof, $coscof) = @$_;
	if ($mulM) {
	    my $corr = $efac[abs $mulM] || confess <<eod;
Programming error - M multiple greater than 2.
eod
	    $sincof *= $corr;
	    $coscof *= $corr;
	}
	my $arg = $D * $mulD + $M * $mulM + $Mprime * $mulMprime +
	    $F * $mulF;
	$sigmal += $sincof * sin ($arg);
	$sigmar += $coscof * cos ($arg);
    }

#	Compute periodic terms for latitude (sigma b).

    my $sigmab = 0;
    foreach (@{$terms{b}}) {
	my ($mulD, $mulM, $mulMprime, $mulF, $sincof) = @$_;
	if ($mulM) {
	    my $corr = $efac[abs $mulM] || confess <<eod;
Programming error - M multiple greater than 2.
eod
	    $sincof *= $corr;
	}
	my $arg = $D * $mulD + $M * $mulM + $Mprime * $mulMprime +
	    $F * $mulF;
	$sigmab += $sincof * sin ($arg);
    }

#	Add other terms

    $sigmal += 3958 * sin ($A1) + 1962 * sin ($Lprime - $F) +
	318 * sin ($A2);
    $sigmab += - 2235 * sin ($Lprime) + 382 * sin ($A3) +
	175 * sin ($A1 - $F) + 175 * sin ($A1 + $F) +
	127 * sin ($Lprime - $Mprime) - 115 * sin ($Lprime + $Mprime);

#	Coordinates of Moon (finally!)

    my $lambda = deg2rad ($sigmal / 1_000_000) + $Lprime;
    my $beta = deg2rad ($sigmab / 1_000_000);
    my $delta = $sigmar / 1000 + 385_000.56;

#	Correct longitude for nutation (from Chapter 22, pg 144).

    $lambda += ( $self->nutation( $time ) )[0];

    $self->ecliptic ($beta, mod2pi( $lambda ), $delta);
    ## $self->set (equinox_dynamical => $time);
    $self->equinox_dynamical ($time);
    return $self;
}

# The moon is normally positioned in inertial coordinates.

sub __initial_inertial { return 1 }

1;

=back

=head2 Historical Calculations

This class was written for the purpose of calculating whether the Moon
was visible from given point on the Earth (or in space) at a given time
in or reasonably close to the present. I can not say how accurate it is
at times far from the present.

See
L<Historical Calculations|Astro::Coord::ECI::Sun/Historical Calculations>
in the L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun> documentation
for a discussion of input and output time conversion.

=head1 ACKNOWLEDGMENTS

The author wishes to acknowledge Jean Meeus, whose book "Astronomical
Algorithms" (second edition) formed the basis for this module.

=head1 SEE ALSO

The L<Astro::Coord::ECI::OVERVIEW|Astro::Coord::ECI::OVERVIEW>
documentation for a discussion of how the pieces/parts of this
distribution go together and how to use them.

L<Astro::MoonPhase|Astro::MoonPhase> by Brett Hamilton, which contains a
function-based module to compute the current phase, distance and angular
diameter of the Moon, as well as the angular diameter and distance of
the Sun.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-satpass>,
L<https://github.com/trwyant/perl-Astro-Coord-ECI/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

__DATA__
# Source: Jean Meeus' "Astronomical Algorithms", Table 47.A pg. 339-340.
-lr
0  0  1  0	6_288_774	-20_905_355
2  0 -1  0	1_274_027	 -3_699_111
2  0  0  0	  658_314	 -2_955_968
0  0  2  0	  213_618	   -569_925
0  1  0  0	 -185_116	     48_888
0  0  0  2	 -114_332	     -3_149
2  0 -2  0	   58_793	    246_158
2 -1 -1  0	   57_066	   -152_138
2  0  1  0	   53_322	   -170_733
2 -1  0  0	   45_758	   -204_586
0  1 -1  0	  -40_923	   -129_620
1  0  0  0	  -34_720	    108_743
0  1  1  0	  -30_383	    104_755
2  0  0 -2	   15_327	     10_321
0  0  1  2	  -12_528	          0
0  0  1 -2	   10_980	     79_661
4  0 -1  0	   10_675	    -34_782
0  0  3  0	   10_034	    -23_210
4  0 -2  0	    8_548	    -21_636
2  1 -1  0	   -7_888	     24_208
2  1  0  0	   -6_766	     30_824
1  0 -1  0	   -5_163	     -8_379
1  1  0  0	    4_987	    -16_675
2 -1  1  0	    4_036	    -12_831
2  0  2  0	    3_994	    -10_445
4  0  0  0	    3_861	    -11_650
2  0 -3  0	    3_665	     14_403
0  1 -2  0	   -2_689	     -7_003
2  0 -1  2	   -2_602	          0
2 -1 -2  0	    2_390	     10_056
1  0  1  0	   -2_348	      6_322
2 -2  0  0	    2_236	     -9_884
0  1  2  0	   -2_120	      5_751
0  2  0  0	   -2_069	          0
2 -2 -1  0	    2_048	     -4_950
2  0  1 -2	   -1_773	      4_130
2  0  0  2	   -1_595	          0
4 -1 -1  0	    1_215	     -3_958
0  0  2  2	   -1_110	          0
3  0 -1  0	     -892	      3_258
2  1  1  0	     -810	      2_616
4 -1 -2  0	      759	     -1_897
0  2 -1  0	     -713	     -2_117
2  2 -1  0	     -700	      2_354
2  1 -2  0	      691	          0
2 -1  0 -2	      596	          0
4  0  1  0	      549	     -1_423
0  0  4  0	      537	     -1_117
4 -1  0  0	      520	     -1_571
1  0 -2  0	     -487	     -1_739
2  1  0 -2	     -399	          0
0  0  2 -2	     -381	     -4_421
1  1  1  0	      351	          0
3  0 -2  0	     -340	          0
4  0 -3  0	      330	          0
2 -1  2  0	      327	          0
0  2  1  0	     -323	      1_165
1  1 -1  0	      299	          0
2  0  3  0	      294	          0
2  0 -1 -2	        0	      8_752
# Source: Jean Meeus' "Astronomical Algorithms", Table 47.B pg. 341.
-b
#>>> I have an error in the sigma b result versus the book
#>>> solution when working Meeus' example 47.a on page 342.
#>>> The book gives -3229126, and I get -3228669.6
0  0  0  1	5_128_122
0  0  1  1	  280_602
0  0  1 -1	  277_693
2  0  0 -1	  173_237
2  0 -1  1	   55_413
2  0 -1 -1	   46_271
2  0  0  1	   32_573
0  0  2  1	   17_198
2  0  1 -1	    9_266
0  0  2 -1	    8_822
2 -1  0 -1	    8_216
2  0 -2 -1	    4_324
2  0  1  1	    4_200
2  1  0 -1	   -3_359
2 -1 -1  1	    2_463
2 -1  0  1	    2_211
2 -1 -1 -1	    2_065
0  1 -1 -1	   -1_870
4  0 -1 -1	    1_828
0  1  0  1	   -1_794
0  0  0  3	   -1_749
0  1 -1  1	   -1_565
1  0  0  1	   -1_491
0  1  1  1	   -1_475
0  1  1 -1	   -1_410
0  1  0 -1	   -1_344
1  0  0 -1	   -1_335
0  0  3  1	    1_107
4  0  0 -1	    1_021
4  0 -1  1	      833
0  0  1 -3	      777
4  0 -2  1	      671
2  0  0 -3	      607
2  0  2 -1	      596
2 -1  1 -1	      491
2  0 -2  1	     -451
0  0  3 -1	      439
2  0  2  1	      422
2  0 -3 -1	      421
2  1 -1  1	     -366
2  1  0  1	     -351
4  0  0  1	      331
2 -1  1  1	      315
2 -2  0 -1	      302
0  0  1  3	     -283
2  1  1 -1	     -229
1  1  0 -1	      223
1  1  0  1	      223
0  1 -2 -1	     -220
2  1 -1 -1	     -220
1  0  1  1	     -185
2 -1 -2 -1	      181
0  1  2  1	     -177
4  0 -2 -1	      176
4 -1 -1 -1	      166
1  0  1 -1	     -164
4  0  1 -1	      132
1  0 -1 -1	     -119
4 -1  0 -1	      115
2 -2  0  1	      107

# ex: set textwidth=72 :
