package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;
use My::Module::Test::App;
use Astro::App::Satpass2::Utils qw{ HAVE_DATETIME };

BEGIN {

    # Workaround for bug (well, _I_ think it's a bug) introduced into
    # Date::Manip with 6.34, while fixing RT #78566. My bug report is RT
    # #80435.
    my $path = $ENV{PATH};
    local $ENV{PATH} = $path;

    eval {
	# The following localizations are to force the Date::Manip 6
	# backend
	local $ENV{DATE_MANIP} = 'DM6';
	local $Date::Manip::Backend = 'DM6';
	require Date::Manip;
	1;
    } or plan skip_all => 'Date::Manip not available';

    my $ver = Date::Manip->VERSION();
    Date::Manip->import();
    ( my $test = $ver ) =~ s/ _ //smxg;
    $test >= 6
	or plan skip_all =>
	    "Date::Manip $ver installed; this test is for 6.00 or greater";

    $] >= 5.010
	or plan skip_all =>
	    "Date::Manip version 6 backend not available under Perl $]";

    if ( HAVE_DATETIME ) {

	*greg_time_gm = \&dt_greg_time_gm;
	*greg_time_local = \&dt_greg_time_local;

	local $@ = undef;

	my ( $dm_zone, $dt_zone );
	eval {
	    $dm_zone = Date::Manip::Date_TimeZone();
	    require DateTime::TimeZone;
	    $dt_zone = DateTime::TimeZone->new( name => 'local')->name();
	    1;
	} and lc $dm_zone ne lc $dt_zone
	    and plan skip_all =>
	    "Date::Manip zone is '$dm_zone' but DateTime zone is '$dt_zone'";

    } else {

	require Astro::Coord::ECI::Utils;
	Astro::Coord::ECI::Utils->VERSION( '0.112' );
	Astro::Coord::ECI::Utils->import( qw{ greg_time_gm greg_time_local } );

    }

}

dump_date_manip_init();
my $path = $ENV{PATH};

require_ok 'Astro::App::Satpass2::ParseTime';

note <<'EOD';
The following test is to make sure we have worked around RT ticket
#80435: [patch] Date::Manip clobbers $ENV{PATH} on *nix
EOD

is $ENV{PATH}, $path, 'Ensure that the PATH is prorected at load';

klass( 'Astro::App::Satpass2::ParseTime' );

call_m( new => class => 'Astro::App::Satpass2::ParseTime::Date::Manip',
    INSTANTIATE, 'Instantiate' );

note <<'EOD';
The following test is to make sure we have worked around RT ticket
#80435: [patch] Date::Manip clobbers $ENV{PATH} on *nix
EOD

is $ENV{PATH}, $path, 'Ensure that the PATH is prorected at instantiation';

call_m( isa => 'Astro::App::Satpass2::ParseTime::Date::Manip::v6', TRUE,
    'Object is an Astro::App::Satpass2::ParseTime::Date::Manip::v6' );

call_m( isa => 'Astro::App::Satpass2::ParseTime', TRUE,
    'Object is an Astro::App::Satpass2::ParseTime' );

call_m( 'delegate',
    'Astro::App::Satpass2::ParseTime::Date::Manip::v6',
    'Delegate is Astro::App::Satpass2::ParseTime::Date::Manip::v6' );

call_m( 'use_perltime', FALSE, 'Does not use perltime' );

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

my $time_local = greg_time_local( 0, 0, 0, 1, 0, 2009 );
call_m( parse => '20090101T000000',
    $time_local,
    'Parse ISO-8601 20090101T000000' )
    or dump_date_manip( $time_local );

$time_local = greg_time_local( 0, 0, 0, 1, 6, 2009 );
call_m( parse => '20090701T000000',
    $time_local,
    'Parse ISO-8601 20090701T000000' )
    or dump_date_manip( $time_local );

call_m( perltime => 0, TRUE, 'Set perltime false' );

$time_local = greg_time_local( 0, 0, 0, 1, 0, 2009 );
call_m( parse => '20090101T000000',
    $time_local,
    'Parse ISO-8601 20090101T000000, no help from perltime' )
    or dump_date_manip( $time_local );

$time_local = greg_time_local( 0, 0, 0, 1, 6, 2009 );
call_m( parse => '20090701T000000',
    $time_local,
    'Parse ISO-8601 20090701T000000, no help from perltime' )
    or dump_date_manip( $time_local );

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
