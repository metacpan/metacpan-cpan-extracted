package main;

use strict;
use warnings;

use Astro::App::Satpass2::ParseTime;
use Test::More 0.88;

use lib qw{ inc };

use My::Module::Test::App;

BEGIN {

    local $@ = undef;

    eval {

	no warnings qw{ deprecated once };
	require Date::Manip::DM5;

	# Force Date::Manip 5 backend if we have Date::Manip 6.
	local $Date::Manip::Backend = 'DM5';

	require Date::Manip;

	1;
    } or plan skip_all => 'Date::Manip 5 not available';

    $^O eq 'MSWin32'
	and plan skip_all => 'Date::Manip 5 tests fail under Windows';

    require Astro::Coord::ECI::Utils;
    Astro::Coord::ECI::Utils->VERSION( '0.112' );
    Astro::Coord::ECI::Utils->import( qw{ greg_time_gm greg_time_local } );

}

dump_date_manip_init();

# The following is a hook for the author test that forces this to run
# under Date::Manip 5.54. We want the author test to fail if we get
# version 6.

our $DATE_MANIP_5_REALLY;

if ( $DATE_MANIP_5_REALLY ) {
    ( my $ver = Date::Manip->VERSION() ) =~ s/ _ //smxg;
    cmp_ok $ver, '<', 6, 'Date::Manip version is really less than 6';
}

klass( 'Astro::App::Satpass2::ParseTime' );

call_m( new => class => 'Astro::App::Satpass2::ParseTime::Date::Manip',
    INSTANTIATE, 'Instantiate' );

isa_ok invocant, 'Astro::App::Satpass2::ParseTime::Date::Manip::v5';

isa_ok invocant, 'Astro::App::Satpass2::ParseTime';

call_m( 'delegate',
    'Astro::App::Satpass2::ParseTime::Date::Manip::v5',
    'Delegate is Astro::App::Satpass2::ParseTime::Date::Manip::v5' );

call_m( use_perltime => TRUE, 'Uses perltime' );

call_m( parse => '20100202T120000Z',
    greg_time_gm( 0, 0, 12, 2, 1, 2010 ),
    'Parse noon on Groundhog Day 2010' );

my $base = greg_time_gm( 0, 0, 0, 1, 3, 2009 );	# April 1, 2009 GMT;
use constant ONE_DAY => 86400;			# One day, in seconds.
use constant HALF_DAY => 43200;			# 12 hours, in seconds.

call_m( base => $base, TRUE, 'Set base time to 01-Apr-2009 GMT' );

call_m( parse => '+0', $base, 'Parse of +0 returns base time' );

call_m( parse => '+1', $base + ONE_DAY,
    'Parse of +1 returns one day later than base time' );

call_m( parse => '+0', $base + ONE_DAY,
    'Parse of +0 now returns one day later than base time' );

call_m( 'reset', TRUE, 'Reset to base time' );

call_m( parse => '+0', $base, 'Parse of +0 returns base time again' );

call_m( parse => '+0 12', $base + HALF_DAY,
    q{Parse of '+0 12' returns base time plus 12 hours} );

call_m( 'reset', TRUE, 'Reset to base time again' );

call_m( parse => '-0', $base, 'Parse of -0 returns base time' );

call_m( parse => '-0 12', $base - HALF_DAY,
    'Parse of \'-0 12\' returns 12 hours before base time' );

call_m( perltime => 1, TRUE, 'Set perltime true' );

SKIP: {

    Time::y2038->can( 'timegm' )
	and skip 'Time::y2038 has problems with summer/winter time', 2;

    call_m( parse => '20090101T000000',
	greg_time_local( 0, 0, 0, 1, 0, 2009 ),
	'Parse ISO-8601 20090101T000000' )
	or dump_date_manip();

    call_m( parse => '20090701T000000',
	greg_time_local( 0, 0, 0, 1, 6, 2009 ),
	'Parse ISO-8601 20090701T000000' )
	or dump_date_manip();

}

call_m( perltime => 0, TRUE, 'Set perltime false' );

my $time_gm = greg_time_gm( 0, 0, 0, 1, 0, 2009 );
call_m( parse => '20090101T000000Z',
    $time_gm,
    'Parse ISO-8601 20090101T000000Z' )
    or dump_date_manip( $time_gm );

$time_gm = greg_time_gm( 0, 0, 0, 1, 6, 2009 );
call_m( parse => '20090701T000000Z',
    $time_gm,
    'Parse ISO-8601 20090701T000000Z' )
    or dump_date_manip( $time_gm );

done_testing;

1;

# ex: set textwidth=72 :
