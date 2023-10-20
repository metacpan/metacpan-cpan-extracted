package main;

use strict;
use warnings;

use POSIX qw{strftime floor};
use Test::More 0.88;	# Because of done_testing()
use Time::Local;

##use constant ASTRONOMICAL_UNIT => 149_597_870; # Meeus, Appendix 1, pg 407
##use constant EQUATORIALRADIUS => 6378.14;	# Meeus page 82.
##use constant PERL2000 => timegm( 0, 0, 12, 1, 0, 2000 );
use constant TIMFMT => '%d-%b-%Y %H:%M:%S';
use constant PI	=> atan2 0, -1;

use constant ARRAY_REF	=> ref [];
use constant HASH_REF	=> ref {};

use constant HAS_UNICODE_SUPPORT	=> "$]" > 5.008001;

=begin comment

# I wish I could do this, but the two-arg binmode requires Perl 5.8.

if ( HAS_UNICODE_SUPPORT ) {
    my $builder = Test::More->builder();
    binmode $builder->failure_output(), ':encoding(utf-8)';
}

=end comment

=cut

require_ok 'Astro::Coord::ECI::Utils'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI::Utils';

require_ok 'Astro::Coord::ECI'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI';

instantiate( 'Astro::Coord::ECI' )
    or BAIL_OUT 'Can not instantiate Astro::Coord::ECI';

require_ok 'Astro::Coord::ECI::Moon'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI::Moon';

require_ok 'Astro::Coord::ECI::Star'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI::Star';

require_ok 'Astro::Coord::ECI::Sun'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI::Sun';

require_ok 'Astro::Coord::ECI::TLE'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI::TLE';

require_ok 'Astro::Coord::ECI::TLE::Set'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI::Set';

instantiate( 'Astro::Coord::ECI::TLE::Set' )
    or BAIL_OUT 'Can not instantiate Astro::Coord::ECI::Set';

u_cmp_eql( deg2rad => 45, .7853981634, '%.10f', 'deg2rad( 45 )' );

u_cmp_eql( deg2rad => undef, undef, undef, 'deg2rad( undef )' );

u_cmp_eql( rad2deg => 1, 57.295779513, '%.9f', 'rad2deg( 1 )' );

u_cmp_eql( rad2deg => undef, undef, undef, 'rad2deg( undef )' );

SKIP: {

    HAS_UNICODE_SUPPORT
	or skip "Perl $] has insufficient Unicode support", 1;
    u_cmp_eql( rad2dms => 1, qq<57\N{U+00B0}17'44".806>, { test => 'is' },
	'rad2dms( 1 )' );
}

u_cmp_eql( rad2dms => undef, undef, undef, 'rad2dms( undef )' );

u_cmp_eql( rad2hms => 1, '3h49m10s.987', { test => 'is' }, 'rad2hms( 1 )' );

u_cmp_eql( rad2hms => undef, undef, undef, 'rad2hms( undef )' );

u_cmp_eql( acos => 1, 0, '%.6f', 'acos( 1 )' );

u_cmp_eql( acos => 0, atan2( 1, 0 ), '%.6f', 'acos( 0 )' );

u_cmp_eql( asin => 0, 0, '%.6f', 'asin( 0 )' );

u_cmp_eql( asin => 1, atan2( 1, 0 ), '%.6f', 'asin( 1 )' );

u_cmp_eql( jday2000 => timegm( 0, 0, 12, 1, 0, 100 ), 0,
    undef, 'jday2000: Noon Jan 1 2000 => 0 (Meeus pg 62)' );

u_cmp_eql( jday2000 => timegm( 0, 0, 0, 1, 0, 99 ), -365.5,
    undef, 'jday2000: Midnight Jan 1 1999 => -365.5 (Meeus pg 62)' );

u_cmp_eql( julianday => timegm( 0, 0, 12, 1, 0, 100 ), 2451545.0,
    undef, 'julianday: Noon Jan 1 2000 => 2451545 (Meeus pg 62)' );

u_cmp_eql( julianday => timegm( 0, 0, 12, 1, 0, 100 ), 2451545.0,
    undef, 'julianday: Midnight Jan 1 1999 => 2451179.5 (Meeus pg 62)' );

u_cmp_eql( jcent2000 => timegm( 0, 0, 0, 10, 3, 87 ), -.127296372348,
    '%.12f', 'jcent2000: Midnight Nov 3 1987: Meeus ex 12.a pg 88' );

u_cmp_eql( jcent2000 => timegm( 0, 21, 19, 10, 3, 87 ), -.12727430,
    '%.8f', 'jcent2000: 19:21 Nov 3 1987: Meeus ex 12.b pg 89' );

u_cmp_eql( thetag => timegm( 0, 0, 0, 10, 3, 87 ), 3.450397,
    '%.6f', 'thetag: Midnight Nov 3 1987: Meeus ex 12.a pg 88' );

u_cmp_eql( thetag => timegm( 0, 21, 19, 10, 3, 87 ), 2.246900,
    '%.6f', 'thetag: 19:21 Nov 3 1987: Meeus ex 12.b pg 89' );

u_cmp_eql( theta0 => timegm( 0, 21, 19, 10, 3, 87 ), 3.450397,
    '%.6f', 'theta0: 19:21 Nov 3 1987: Meeus ex 12.b pg 89' );

u_cmp_eql( omega => timegm( 0, 0, 0, 10, 3, 87 ), .19640,
    '%.5f', 'omega: Midnight Nov 3 1987: Meeus ex 22.a' );

# TODO drop the following

=begin comment

u_cmp_eql( nutation_in_longitude => timegm( 0, 0, 0, 10, 3, 87 ),
    -1.8364e-5, '%.5f',	# Tolerance .5 seconds of arc
    'nutation_in_longitude: Midnight Nov 3 1987: Meeus ex 22.a' );

u_cmp_eql( nutation_in_obliquity => timegm( 0, 0, 0, 10, 3, 87 ),
    4.5781e-5, '%.6f',	# Tolerance .1 seconds of arc
    'nutation_in_obliquity: Midnight Nov 3 1987: Meeus ex 22.a' );

u_cmp_eql( obliquity => timegm( 0, 0, 0, 10, 3, 87 ), 0.409167475225493,
    '%.5f', 'obliquity: Midnight Nov 3 1987: Meeus ex 22.a' );

u_cmp_eql( equation_of_time => timegm( 0, 0, 0, 13, 9, 92 ),
    13 * 60 + 42.7, '%.1f',	# Tolerance .1 second
    'equation_of_time: Midnight Oct 13 1992: Meeus ex 28b' );

=end comment

=cut

# TODO drop the preceding

u_cmp_eql( add_magnitudes => [ 4.73, 5.22, 5.60 ], 3.93, '%.2f',
    'add_magnitudes: Meeus ex 56.b' );

u_cmp_eql( intensity_to_magnitude => 500, -6.75, '%.2f',
    'intensity_to_magnitude: 500: Meeus ex 56.e' );

u_cmp_eql( atmospheric_extinction => [
    0.174532925199433,	# 80 degrees below zenith, in radians elevation
    0,			# Height above sea level, kilometers
], 1.59, '%.2f',
'atmospheric_extinction: elev 10 deg, hgt 0 km: Green tbl 1a' );

u_cmp_eql( atmospheric_extinction => [
    0.785398163397448,	# 45 degrees below zenith, in radians elevation
    .5,			# Height above sea level, kilometers
], 0.34, '%.2f',
'atmospheric_extinction: elev 45 deg, hgt 0.5 km: Green tbl 1a' );

u_cmp_eql( atmospheric_extinction => [
    1.55334303427495,	# 1 degree below zenith, in radians elevation
    1,			# Height above sea level, kilometers
], 0.21, '%.2f',
'atmospheric_extinction: elev 45 deg, hgt 0.5 km: Green tbl 1a' );

u_cmp_eql( date2jd => [ 4.81, 9, 57 ], 2436116.31,
    '%.2f', 'date2jd: Oct 4.81, 1957: Meeus pp 60ff' );

u_cmp_eql( date2jd => [ 12, 27, 0, -1567 ], 1842713,
    '%.2f', 'date2jd: Noon Jan 27 AD 333: Meeus pp 60ff' );

u_cmp_eql( jd2date => 2436116.31, [ 0, 4.81 ], '%.2f',
    'jd2date: day of jd 2436116.31: Meeus pp 60ff' );

u_cmp_eql( jd2date => 2436116.31, [ 1, 9 ], '%.2f',
    'jd2date: month of jd 2436116.31: Meeus pp 60ff' );

u_cmp_eql( jd2date => 2436116.31, [ 2, 57 ], '%.2f',
    'jd2date: year of jd 2436116.31: Meeus pp 60ff' );

u_cmp_eql( jd2date => 1842713.0, [ 0, 27.5 ], '%.2f',
    'jd2date: day of jd 1842713.0: Meeus pp 60ff' );

u_cmp_eql( jd2date => 1842713.0, [ 1, 0 ], '%.2f',
    'jd2date: month of jd 1842713.0: Meeus pp 60ff' );

u_cmp_eql( jd2date => 1842713.0, [ 2, -1567 ], '%.2f',
    'jd2date: year of jd 1842713.0: Meeus pp 60ff' );

u_cmp_eql( jd2date => 1507900.13, [ 0, 28.63 ], '%.2f',
    'jd2date: day of jd 1507900.13: Meeus pp 60ff' );

u_cmp_eql( jd2date => 1507900.13, [ 1, 4 ], '%.2f',
    'jd2date: month of jd 1507900.13: Meeus pp 60ff' );

u_cmp_eql( jd2date => 1507900.13, [ 2, -2484 ], '%.2f',
    'jd2date: year of jd 1507900.13: Meeus pp 60ff' );

use constant PERL2000 => timegm( 0, 0, 12, 1, 0, 2000 );

u_cmp_eql( date2epoch => [ 12, 1, 0, 100 ], PERL2000, '%.1f',
    'date2epoch: Noon Jan 1 2000' );

u_cmp_eql( epoch2datetime => PERL2000, [ 0, 0 ], '%.1f',
    'epoch2datetime: seconds of PERL2000' );

u_cmp_eql( epoch2datetime => PERL2000, [ 1, 0 ], '%.1f',
    'epoch2datetime: minutes of PERL2000' );

u_cmp_eql( epoch2datetime => PERL2000, [ 2, 12 ], '%.1f',
    'epoch2datetime: hours of PERL2000' );

u_cmp_eql( epoch2datetime => PERL2000, [ 3, 1 ], '%.1f',
    'epoch2datetime: days of PERL2000' );

u_cmp_eql( epoch2datetime => PERL2000, [ 4, 0 ], '%.1f',
    'epoch2datetime: months of PERL2000' );

u_cmp_eql( epoch2datetime => PERL2000, [ 5, 100 ], '%.1f',
    'epoch2datetime: years of PERL2000' );

u_cmp_eql( jd2datetime => 2434923.5, [ 0, 0 ], '%1f',
    'jd2datetime: seconds of 2434923.5: Meeus ex 7.e.' );

u_cmp_eql( jd2datetime => 2434923.5, [ 1, 0 ], '%1f',
    'jd2datetime: minutes of 2434923.5: Meeus ex 7.e.' );

u_cmp_eql( jd2datetime => 2434923.5, [ 2, 0 ], '%1f',
    'jd2datetime: hours of 2434923.5: Meeus ex 7.e.' );

u_cmp_eql( jd2datetime => 2434923.5, [ 3, 30 ], '%1f',
    'jd2datetime: days of 2434923.5: Meeus ex 7.e.' );

u_cmp_eql( jd2datetime => 2434923.5, [ 4, 5 ], '%1f',
    'jd2datetime: months of 2434923.5: Meeus ex 7.e.' );

u_cmp_eql( jd2datetime => 2434923.5, [ 5, 54 ], '%1f',
    'jd2datetime: years of 2434923.5: Meeus ex 7.e.' );

u_cmp_eql( jd2datetime => 2434923.5, [ 6, 3 ], '%1f',
    'jd2datetime: weekday of 2434923.5: Meeus ex 7.e.' );

u_cmp_eql( jd2datetime => 2443826.5, [ 0, 0 ], '%1f',
    'jd2datetime: seconds of 2443826.5: Meeus ex 7.f.' );

u_cmp_eql( jd2datetime => 2443826.5, [ 1, 0 ], '%1f',
    'jd2datetime: minutes of 2443826.5: Meeus ex 7.f.' );

u_cmp_eql( jd2datetime => 2443826.5, [ 2, 0 ], '%1f',
    'jd2datetime: hours of 2443826.5: Meeus ex 7.f.' );

u_cmp_eql( jd2datetime => 2443826.5, [ 3, 14 ], '%1f',
    'jd2datetime: days of 2443826.5: Meeus ex 7.f.' );

u_cmp_eql( jd2datetime => 2443826.5, [ 4, 10 ], '%1f',
    'jd2datetime: months of 2443826.5: Meeus ex 7.f.' );

u_cmp_eql( jd2datetime => 2443826.5, [ 5, 78 ], '%1f',
    'jd2datetime: years of 2443826.5: Meeus ex 7.f.' );

u_cmp_eql( jd2datetime => 2443826.5, [ 7, 317 ], '%1f',
    'jd2datetime: year day of 2443826.5: Meeus ex 7.f.' );

u_cmp_eql( jd2datetime => 2447273.5, [ 0, 0 ], '%1f',
    'jd2datetime: seconds of 2447273.5: Meeus ex 7.g.' );

u_cmp_eql( jd2datetime => 2447273.5, [ 1, 0 ], '%1f',
    'jd2datetime: minutes of 2447273.5: Meeus ex 7.g.' );

u_cmp_eql( jd2datetime => 2447273.5, [ 2, 0 ], '%1f',
    'jd2datetime: hours of 2447273.5: Meeus ex 7.g.' );

u_cmp_eql( jd2datetime => 2447273.5, [ 3, 22 ], '%1f',
    'jd2datetime: days of 2447273.5: Meeus ex 7.g.' );

u_cmp_eql( jd2datetime => 2447273.5, [ 4, 3 ], '%1f',
    'jd2datetime: months of 2447273.5: Meeus ex 7.g.' );

u_cmp_eql( jd2datetime => 2447273.5, [ 5, 88 ], '%1f',
    'jd2datetime: years of 2447273.5: Meeus ex 7.g.' );

u_cmp_eql( jd2datetime => 2447273.5, [ 7, 112 ], '%1f',
    'jd2datetime: year day of 2447273.5: Meeus ex 7.g.' );

u_cmp_eql( keplers_equation => [
    0.0872664625997165, 0.100, 1.74532925199433e-08,
], 0.0969458666450593, '%.6f',
    'keplers_equation: M = 5 deg, e = 0.100 to 0.000001 deg: Meeus ex 30.b' );

u_cmp_eql( distsq => [ [ 3, 4 ], [ 0, 0 ] ], 25, undef,
    'distsq( [ 3, 4 ] )' );

u_cmp_eql( vector_magnitude => [ [ 3, 4 ] ], 5, undef,
    'vector_magnitude( [ 3, 4 ] )' );

u_cmp_eql( vector_unitize => [ [ 3, 4 ] ], [ 0, .6 ], undef,
    'vector_unitize( [ 3, 4 ] ): X component' );

u_cmp_eql( vector_unitize => [ [ 3, 4 ] ], [ 1, .8 ], undef,
    'vector_unitize( [ 3, 4 ] ): Y component' );

u_cmp_eql( vector_dot_product => [ [ 1, 2, 3 ], [ 6, 5, 4 ] ], 28, undef,
    'vector_dot_product( [ 1, 2, 3 ], [ 6, 5, 4 ] )' );

u_cmp_eql( vector_cross_product => [ [ 1, 2, 3 ], [ 6, 5, 4 ] ],
    [ 0, -7 ], undef,
    'vector_cross_product( [ 1, 2, 3 ], [ 6, 5, 4 ] ): X component' );

u_cmp_eql( vector_cross_product => [ [ 1, 2, 3 ], [ 6, 5, 4 ] ],
    [ 1, 14 ], undef,
    'vector_cross_product( [ 1, 2, 3 ], [ 6, 5, 4 ] ): Y component' );

u_cmp_eql( vector_cross_product => [ [ 1, 2, 3 ], [ 6, 5, 4 ] ],
    [ 2, -7 ], undef,
    'vector_cross_product( [ 1, 2, 3 ], [ 6, 5, 4 ] ): Z component' );

u_cmp_eql( find_first_true => [
    0, 1, sub{ sin( $_[0] ) >= sin( .5 ) }, .0001 ], .5, '%.4f',
    'find_first_true looking for sin( $x ) >= sin( .5 )' );

u_cmp_eql( format_space_track_json_time => timegm( 0, 0, 0, 1, 3, 114 ),
    '2014-04-01 00:00:00', '%s', 'Format Space Track JSON time' );

u_cmp_eql( __format_epoch_time_usec => [
	timegm( 5, 4, 3, 1, 3, 114 ) + .25, '%F %T' ],
    '2014-04-01 03:04:05.250000', '%s',
    'Format epoch time with microseconds' );

note <<EOD;
The following test is from the example in the IDL Astronomy User's
Library source for posang().
EOD

TODO: {
#    local $TODO = 'position_angle() is a work-in-progress';

    note <<EOD;
This is one of the few of Meeus' formulae where he does not provide a
worked example. I am unable to duplicate the IDL Astronomy User's
Library posang() sample results, but neither is PyAstronomy's
positionAngle(), which claims to derive from the IDL implementation.
http://www.backyard-astro.com/deepsky/top100/07.html gives the position
angle from Mizar to Alcor as 72 degrees. PyAstronomy calculates 71 and a
bit using their SIMBAD positions as of July 21 2019, so I am testing
against that number.
EOD

    u_cmp_eql( position_angle => [
	deg_to_rad( 200.98141867 ),
	deg_to_rad(  54.92535197 ),
	deg_to_rad( 201.3064076387 ),
	deg_to_rad(  54.9879596614 ),
    ], deg_to_rad( 71.32015 ), '%.6f', 'position angle Alcor wrt Mizar' );
}

done_testing;

sub instantiate {
    my ( $class ) = @_;
    my $pass = eval {
	$class->new();
    };
    @_ = ( $pass, "Instantiate $class" );
    goto &ok;
}

sub deg_to_rad {
    my ( $deg ) = @_;
    return $deg * PI / 180;
}

sub u_cmp_eql {
    my ( $sub, $arg, $want, $tplt, $title ) = @_;
    my $opt;
    if ( HASH_REF eq ref $tplt ) {
	$opt = { %{ $tplt } };	# Shallow clone
	$tplt = $opt->{template};
    } else {
	$opt = {};
    }
    $opt->{test} ||= ( defined $tplt && '%s' eq $tplt ) ? 'is' : 'numeric';
    ARRAY_REF eq ref $arg
	or $arg = [ $arg ];
    if ( my $code = Astro::Coord::ECI::Utils->can( $sub ) ) {
	my $got;
	if ( ARRAY_REF eq ref $want ) {
	    ( my $inx, $want ) = @{ $want };
	    my @rslt;
	    {
		# The following package() statement seems to be the most
		# convenient way to get warnings and errors reported
		# where the test occurs rather than here.
		package Astro::Coord::ECI::Utils;
		@rslt = $code->( @{ $arg } );
	    }
	    if ( 1 == @rslt && ARRAY_REF eq ref $rslt[0] ) {
		$got = $rslt[0][$inx];
	    } else {
		$got = $rslt[$inx];
	    }
	} else {
	    # See above for the rationale for the package() statement.
	    package Astro::Coord::ECI::Utils;
	    $got = $code->( @{ $arg } );
	}
	if ( ! defined $want ) {
	    @_ = ( $got, $want, $title );
	    goto &is;
	} else {
	    defined $tplt
		and ( $want, $got ) = map { sprintf $tplt, $_ } ( $want, $got );
	    if ( 'is' eq $opt->{test} ) {
		@_ = ( $got, $want, $title );
		goto &is;
	    } elsif ( 'numeric' eq $opt->{test} ) {
		@_ = ( $got, '==', $want, $title );
		goto &cmp_ok;
	    } else {
		die "Unknown test type '$opt->{test}'";
	    }
	}
    } else {
	@_ = "Astro::Coord::ECI::Utils does not have subroutine $sub()";
	goto &fail;
    }
}

1;

# ex: set filetype=perl textwidth=72 :
