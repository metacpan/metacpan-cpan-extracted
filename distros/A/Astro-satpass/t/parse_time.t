package main;

use strict;
use warnings;

my ( $mock_time );

BEGIN {
    eval {
	require Test::More;
	Test::More->VERSION( 0.88 );	# Because of done_testing()
	Test::More->import();
	1;
    } or do {
	print "1..0 # skip Test::More 0.88 required for test.\n";
	exit;
    };

    $mock_time = eval {
	require Test::MockTime;
	Test::MockTime->import( qw{ set_fixed_time restore_time } );
	1;
    };
}

use Astro::Coord::ECI::Utils qw{ :time };

if ( $mock_time && Time::y2038->can( 'VERSION' ) ) {

    # This is yukky, but we have to do it because if
    # Astro::Coord::ECI::Utils was able to import Time::y2038, the
    # relevant core routines have already been overridden in that
    # module's namespace, and Test::MockTime's CORE::GLOBAL override
    # will not be seen.

    no warnings qw{ redefine once };	## no critic (ProhibitNoWarnings)
    *Astro::Coord::ECI::Utils::time = \&Test::MockTime::time;
    *Astro::Coord::ECI::Utils::localtime = \&Test::MockTime::localtime;
    *Astro::Coord::ECI::Utils::gmtime = \&Test::MockTime::gmtime;

}

sub gmt (@);
sub lcl (@);

plan tests => 63;

lcl '20090702162337',		37, 23, 16, 2, 6, 2009;
gmt '20090702162337Z',		37, 23, 16, 2, 6, 2009;
lcl '200907021623',		0, 23, 16, 2, 6, 2009;
gmt '200907021623Z',		0, 23, 16, 2, 6, 2009;
lcl '2009070216',		0, 0, 16, 2, 6, 2009;
gmt '2009070216Z',		0, 0, 16, 2, 6, 2009;
lcl '20090702',		0, 0, 0, 2, 6, 2009;
gmt '20090702Z',		0, 0, 0, 2, 6, 2009;
lcl '200907',			0, 0, 0, 1, 6, 2009;
gmt '200907Z',			0, 0, 0, 1, 6, 2009;
lcl '2009',			0, 0, 0, 1, 0, 2009;
gmt '2009Z',			0, 0, 0, 1, 0, 2009;

lcl '20090102162337',		37, 23, 16, 2, 0, 2009;
gmt '20090102162337Z',		37, 23, 16, 2, 0, 2009;
lcl '200901021623',		0, 23, 16, 2, 0, 2009;
gmt '200901021623Z',		0, 23, 16, 2, 0, 2009;
lcl '2009010216',		0, 0, 16, 2, 0, 2009;
gmt '2009010216Z',		0, 0, 16, 2, 0, 2009;
lcl '20090102',			0, 0, 0, 2, 0, 2009;
gmt '20090102Z',		0, 0, 0, 2, 0, 2009;
lcl '200901',			0, 0, 0, 1, 0, 2009;
gmt '200901Z',			0, 0, 0, 1, 0, 2009;

gmt '20090102162337+00',	37, 23, 16, 2, 0, 2009;
gmt '20090102162337+0030',	37, 53, 15, 2, 0, 2009;
gmt '20090102162337+01',	37, 23, 15, 2, 0, 2009;
gmt '20090102162337-0030',	37, 53, 16, 2, 0, 2009;
gmt '20090102162337-01',	37, 23, 17, 2, 0, 2009;

lcl '20090102T162337',		37, 23, 16, 2, 0, 2009;
gmt '20090102T162337Z',		37, 23, 16, 2, 0, 2009;

lcl '2009/1/2 16:23:37',	37, 23, 16, 2, 0, 2009;
gmt '2009/1/2 16:23:37 Z',	37, 23, 16, 2, 0, 2009;
lcl '2009/1/2 16:23',		0, 23, 16, 2, 0, 2009;
gmt '2009/1/2 16:23 Z',		0, 23, 16, 2, 0, 2009;
lcl '2009/1/2 16',		0, 0, 16, 2, 0, 2009;
gmt '2009/1/2 16 Z',		0, 0, 16, 2, 0, 2009;
lcl '2009/1/2',			0, 0, 0, 2, 0, 2009;
gmt '2009/1/2 Z',		0, 0, 0, 2, 0, 2009;
lcl '2009/1',			0, 0, 0, 1, 0, 2009;
gmt '2009/1 Z',			0, 0, 0, 1, 0, 2009;
lcl '2009',			0, 0, 0, 1, 0, 2009;
gmt '2009 Z',			0, 0, 0, 1, 0, 2009;

lcl '09/1/2 16:23:37',		37, 23, 16, 2, 0, 2009;
gmt '09/1/2 16:23:37 Z',	37, 23, 16, 2, 0, 2009;
lcl '09/1/2 16:23',		0, 23, 16, 2, 0, 2009;
gmt '09/1/2 16:23 Z',		0, 23, 16, 2, 0, 2009;
lcl '09/1/2 16',		0, 0, 16, 2, 0, 2009;
gmt '09/1/2 16 Z',		0, 0, 16, 2, 0, 2009;
lcl '09/1/2',			0, 0, 0, 2, 0, 2009;
gmt '09/1/2 Z',			0, 0, 0, 2, 0, 2009;
lcl '09/1',			0, 0, 0, 1, 0, 2009;
gmt '09/1 Z',			0, 0, 0, 1, 0, 2009;

SKIP: {

    $mock_time or skip 'Unable to load Test::MockTime', 12;

    set_fixed_time('2009-07-01T06:00:00Z');

    gmt 'yesterday Z',		0, 0, 0, 30, 5, 2009;
    gmt 'yesterday 9:30Z',	0, 30, 9, 30, 5, 2009;
    gmt 'today Z',		0, 0, 0, 1, 6, 2009;
    gmt 'today 9:30Z',		0, 30, 9, 1, 6, 2009;
    gmt 'tomorrow Z',		0, 0, 0, 2, 6, 2009;
    gmt 'tomorrow 9:30Z',	0, 30, 9, 2, 6, 2009;

    restore_time();
    set_fixed_time( time_local( 0, 0, 6, 1, 6, 2009 ) );

    lcl 'yesterday',		0, 0, 0, 30, 5, 2009;
    lcl 'yesterday 9:30',	0, 30, 9, 30, 5, 2009;
    lcl 'today',		0, 0, 0, 1, 6, 2009;
    lcl 'today 9:30',		0, 30, 9, 1, 6, 2009;
    lcl 'tomorrow',		0, 0, 0, 2, 6, 2009;
    lcl 'tomorrow 9:30',	0, 30, 9, 2, 6, 2009;

    restore_time();

}

sub gmt (@) {	## no critic (RequireArgUnpacking)
    my ( $string, @gmt ) = @_;
    my $want = time_gm( @gmt );
    my $got;
    eval {
	$got = Astro::Coord::ECI::Utils::__parse_time_iso_8601( $string );
	1;
    } or do {
	$got = $@;
    };
    @_ = ( $got, $want, "$string => " . gmtime( $want ) . ' GMT' );
    goto &is;
}

sub lcl (@) {	## no critic (RequireArgUnpacking)
    my ( $string, @local ) = @_;
    my $want = time_local( @local );
    my $got;
    eval {
	$got = Astro::Coord::ECI::Utils::__parse_time_iso_8601( $string );
	1;
    } or do {
	$got = $	@;
    };
    @_ = ( $got, $want, "$string => " . localtime( $want ) . ' local' );
    goto &is;
}

1;

# ex: set textwidth=72 :
