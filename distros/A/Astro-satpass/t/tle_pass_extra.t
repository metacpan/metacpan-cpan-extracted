package main;

use 5.006002;

use strict;
use warnings;

# This test makes use of satellite orbital elements which I have access
# to, but which I do not have permission to distribute. The needed data
# are in variable $expect below, which contains one line per TLE element
# set, with each line specifying a required OID and epoch (in both
# ISO-8601-ish and TLE format). Order is unimportant.
#
# These data can be downloaded from the Space Track web site
# (http://www.space-track.org/), provided you have an account.
#
# Once you have the TLE data, you need a place to put it. There are two
# places to put it; the first place found will be used:
#
# 1) You can designate the directory of your choice for the data by
#    putting its name in environment variable ASTRO_COORD_ECI_TLE_DIR.
#    This environment variable must be defined when the tests are
#    actually run.
#
# 2) If you have File::HomeDir installed, you can put it in the
#    dist_config directory for Astro-Coord-ECI-TLE-Dir. You will need to
#    consult the File::HomeDir documentation (or even, unfortunately,
#    the source for the plug-in for your operating system) to figure out
#    where this is.
#
# No matter where the file goes, its name must be 'pass_extra.tle'.
#
# The order of the data in the file is unimportant. Blank lines are
# ignored, as are lines whose first non-blank character is '#'. You can
# use either NORAD-format TLE (i.e. two lines of data per data set), or
# NASA-format TLE (with the common name of the object on a line before
# the two lines of data)

use Test::More 0.88;	# Because of done_testing()

BEGIN {

    eval {
	require Time::Local;
	Time::Local->import();
	1;
    } or do {
	plan skip_all => 'Can not load Time::Local';
	exit;
    };

    eval {
	require File::Spec;
	1;
    } or do {
	plan skip_all => 'Can not load File::Spec';
	exit;
    };

    eval {
	use lib qw{ inc };
	require My::Module::Test;
	My::Module::Test->import( ':all' );
	1;
    } or do {
	plan skip_all => 'Can not load My::Module::Test from inc';
	exit;
    };

}

use Astro::Coord::ECI;
use Astro::Coord::ECI::Moon;
use Astro::Coord::ECI::Star;
use Astro::Coord::ECI::TLE qw{ :constants };
use Astro::Coord::ECI::TLE::Set;
use Astro::Coord::ECI::Utils qw{ deg2rad PARSEC rad2deg SECSPERDAY };

my @all_tle;

{
    my $dir = $ENV{ASTRO_COORD_ECI_TLE_DIR};
    $dir
	and -d $dir
	or eval {
	require File::HomeDir;
	$dir = File::HomeDir->my_dist_config(
	    'Astro-Coord-ECI-TLE-Dir' );
    } or do {
	plan skip_all => 'TLE directory not found';
	exit;
    };

    my $file = File::Spec->catfile( $dir, 'pass_extra.tle' );
    -f $file or do {
	plan skip_all => "TLE file $file not found";
	exit;
    };

    my $fh;
    open $fh, '<', $file or do {
	plan skip_all => "Unable to open $file: $!";
	exit;
    };

    @all_tle = sort {
	$a->get( 'id' ) <=> $b->get( 'id' ) ||
	$a->get( 'epoch' ) <=> $b->get( 'epoch' )
    } Astro::Coord::ECI::TLE->parse( <$fh> );

    my $descr = join '', map {
	sprintf "%5s %s %14.8f\n", $_->get( 'id'),
	    format_time( $_->get( 'epoch' ) ),
	    $_->__make_tle_epoch()
    } @all_tle;

    # List of OIDs and epochs expected in pass_extra.tle
    my $expect = <<'EOD';
00733 2011/05/27 18:59:26 11147.79127244
03597 2011/05/27 22:21:07 11147.93133392
21938 2011/05/27 22:36:19 11147.94188938
25544 2011/04/25 08:32:05 11115.35561462
25544 2011/05/13 11:58:29 11133.49894455
EOD

    $descr eq $expect
	or do {
	diag "The TLE data for the test are:\n";
	diag <<'EOD';
OID   Epoch (GMT)          Epoch (in TLE)
----- -------------------- --------------
EOD
	diag "Expected:\n";
	diag $expect;
	diag "Found in $file:\n";
	diag $descr;
	plan skip_all => "$file does not contain the expected data";
	exit;
    };

}

plan tests => 47;

my $sta = Astro::Coord::ECI->new(
    name	=> 'Twisst',
)->geodetic(
    deg2rad( 51.8 ),
    deg2rad( 5.3 ),
    0,
);

my $moon = Astro::Coord::ECI::Moon->new();

my ( $tle ) = get_oid( '25544', @all_tle );
$tle->set( horizon => deg2rad( 10 ) );

my @pass;
my $offset = 10;
if ( eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( $offset, 0, 10, 25, 3, 111 ),
	    timegm( $offset, 0, 10,  2, 4, 111 ),
	    [ $moon ],
	);
	1;
    } ) {
    ok @pass == 10,
	"Found 10 passes over Twisst at $offset sec after minute"
	or diag "Found @{[ scalar @pass ]} passes over Twisst";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
2011/04/25 20:29:44  10.1 274.3  1311.4 lit   rise
2011/04/25 20:32:40  85.5 178.7   352.9 lit   max
2011/04/25 20:34:18  23.2  98.6   792.2 shdw  shdw
2011/04/25 20:35:36   9.9  97.9  1317.9 shdw  set
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
2011/04/25 22:05:01  10.1 273.1  1309.8 lit   rise
2011/04/25 22:05:46  15.7 265.9  1030.7 shdw  shdw
2011/04/25 22:07:43  34.5 205.5   589.1 shdw  max
2011/04/25 22:10:26   9.9 137.5  1314.0 shdw  set
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
2011/04/26 20:54:23  10.0 277.1  1313.9 lit   rise
2011/04/26 20:57:17  60.9 195.5   398.9 lit   max
2011/04/26 20:57:52  46.5 142.8   472.9 shdw  shdw
2011/04/26 21:00:10  10.0 115.1  1310.1 shdw  set
EOD

is format_pass( $pass[3] ), <<'EOD', 'Pass 4';
2011/04/27 19:43:46  10.0 274.6  1312.4 lit   rise
2011/04/27 19:46:42  84.8 182.0   353.1 lit   max
2011/04/27 19:49:38   9.9  98.5  1317.0 lit   set
EOD

is format_pass( $pass[4] ), <<'EOD', 'Pass 5';
2011/04/27 21:19:03  10.1 272.7  1310.4 lit   rise
2011/04/27 21:21:22  32.0 223.9   623.4 shdw  shdw
2011/04/27 21:21:44  33.5 206.0   602.1 shdw  max
2011/04/27 21:24:26   9.9 138.7  1312.5 shdw  set
EOD

is format_pass( $pass[5] ), <<'EOD', 'Pass 6';
2011/04/28 20:08:18  10.1 277.0  1311.1 lit   rise
2011/04/28 20:11:11  59.6 196.7   403.6 lit   max
2011/04/28 20:13:20  16.1 118.9  1012.8 shdw  shdw
2011/04/28 20:14:05   9.9 116.0  1316.0 shdw  set
EOD

is format_pass( $pass[6] ), <<'EOD', 'Pass 7';
2011/04/28 21:43:59  10.0 258.6  1309.6 lit   rise
2011/04/28 21:44:48  13.9 244.5  1106.9 shdw  shdw
2011/04/28 21:45:59  16.9 215.3   978.9 shdw  max
2011/04/28 21:48:00   9.9 171.4  1309.0 shdw  set
EOD

is format_pass( $pass[7] ), <<'EOD', 'Pass 8';
2011/04/29 20:32:50  10.0 272.4  1312.6 lit   rise
2011/04/29 20:35:31  32.6 205.9   614.1 lit   max
2011/04/29 20:36:43  22.6 160.3   805.6 shdw  shdw
2011/04/29 20:38:11  10.0 139.9  1308.8 shdw  set
EOD

is format_pass( $pass[8] ), <<'EOD', 'Pass 9';
2011/04/30 20:57:40  10.0 257.8  1310.6 lit   rise
2011/04/30 20:59:38  16.5 215.4   995.9 lit   max
2011/04/30 21:00:03  16.0 204.4  1012.0 shdw  shdw
2011/04/30 21:01:35  10.0 173.2  1305.2 shdw  set
EOD

is format_pass( $pass[9] ), <<'EOD', 'Pass 10';
2011/05/01 19:46:23  10.1 272.1  1309.5 lit   rise
2011/05/01 19:49:02  31.8 206.8   624.9 lit   max
2011/05/01 19:51:42   9.9 140.9  1309.4 lit   set
EOD

@pass = ();
$offset = 54;
if ( eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( $offset, 0, 10, 25, 3, 111 ),
	    timegm( $offset, 0, 10,  2, 4, 111 ),
	    [ $moon ],
	);
	1;
    } ) {
    ok @pass == 10,
	"Found 10 passes over Twisst at $offset sec after minute"
	or diag "Found @{[ scalar @pass ]} passes over Twisst";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
2011/04/25 20:29:44  10.1 274.3  1311.4 lit   rise
2011/04/25 20:32:40  85.5 178.7   352.9 lit   max
2011/04/25 20:34:18  23.2  98.6   792.2 shdw  shdw
2011/04/25 20:35:36   9.9  97.9  1317.9 shdw  set
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
2011/04/25 22:05:01  10.1 273.1  1309.8 lit   rise
2011/04/25 22:05:46  15.7 265.9  1030.7 shdw  shdw
2011/04/25 22:07:43  34.5 205.5   589.1 shdw  max
2011/04/25 22:10:26   9.9 137.5  1314.0 shdw  set
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
2011/04/26 20:54:23  10.0 277.1  1313.9 lit   rise
2011/04/26 20:57:17  60.9 195.5   398.9 lit   max
2011/04/26 20:57:52  46.5 142.8   472.9 shdw  shdw
2011/04/26 21:00:10  10.0 115.1  1310.1 shdw  set
EOD

is format_pass( $pass[3] ), <<'EOD', 'Pass 4';
2011/04/27 19:43:46  10.0 274.6  1312.4 lit   rise
2011/04/27 19:46:42  84.8 182.0   353.1 lit   max
2011/04/27 19:49:38   9.9  98.5  1317.0 lit   set
EOD

is format_pass( $pass[4] ), <<'EOD', 'Pass 5';
2011/04/27 21:19:03  10.1 272.7  1310.4 lit   rise
2011/04/27 21:21:22  32.0 223.9   623.4 shdw  shdw
2011/04/27 21:21:44  33.5 206.0   602.1 shdw  max
2011/04/27 21:24:26   9.9 138.7  1312.5 shdw  set
EOD

is format_pass( $pass[5] ), <<'EOD', 'Pass 6';
2011/04/28 20:08:18  10.1 277.0  1311.1 lit   rise
2011/04/28 20:11:11  59.6 196.7   403.6 lit   max
2011/04/28 20:13:20  16.1 118.9  1012.8 shdw  shdw
2011/04/28 20:14:05   9.9 116.0  1316.0 shdw  set
EOD

is format_pass( $pass[6] ), <<'EOD', 'Pass 7';
2011/04/28 21:43:59  10.0 258.6  1309.6 lit   rise
2011/04/28 21:44:48  13.9 244.5  1106.9 shdw  shdw
2011/04/28 21:45:59  16.9 215.3   978.9 shdw  max
2011/04/28 21:48:00   9.9 171.4  1309.0 shdw  set
EOD

is format_pass( $pass[7] ), <<'EOD', 'Pass 8';
2011/04/29 20:32:50  10.0 272.4  1312.6 lit   rise
2011/04/29 20:35:31  32.6 205.9   614.1 lit   max
2011/04/29 20:36:43  22.6 160.3   805.6 shdw  shdw
2011/04/29 20:38:11  10.0 139.9  1308.8 shdw  set
EOD

is format_pass( $pass[8] ), <<'EOD', 'Pass 9';
2011/04/30 20:57:40  10.0 257.8  1310.6 lit   rise
2011/04/30 20:59:38  16.5 215.4   995.9 lit   max
2011/04/30 21:00:03  16.0 204.4  1012.0 shdw  shdw
2011/04/30 21:01:35  10.0 173.2  1305.2 shdw  set
EOD

is format_pass( $pass[9] ), <<'EOD', 'Pass 10';
2011/05/01 19:46:23  10.1 272.1  1309.5 lit   rise
2011/05/01 19:49:02  31.8 206.8   624.9 lit   max
2011/05/01 19:51:42   9.9 140.9  1309.4 lit   set
EOD


# Purpose of test: Confirm that extremely short passes are reported
# reliably, and have their maximum elevations correctly calculated.

$sta = Astro::Coord::ECI->new(
    name	=> 'Bogota',
)->geodetic(
    deg2rad( 4.656370 ),
    deg2rad( -74.117790 ),
    46 / 1000,
);
$tle->set( horizon => deg2rad( 11 ), twilight => deg2rad( -3 ) );

@pass = ();
$offset = 34;
if ( eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( $offset, 0, 17, 13, 4, 111 ),
	    timegm( $offset, 0, 17, 20, 4, 111 ),
	    [ $moon ],
	);
	1;
    } ) {
    ok @pass == 7,
	"Found 7 passes over Bogota at $offset sec after minute"
	or diag "Found @{[ scalar @pass ]} passes over Bogota";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
2011/05/14 00:32:45  11.0 244.1  1237.5 lit   rise
2011/05/14 00:33:11  11.3 234.9  1223.3 lit   max
2011/05/14 00:33:39  11.0 225.1  1239.4 lit   set
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
2011/05/14 23:19:14  11.1 319.6  1232.4 lit   rise
2011/05/14 23:21:58  73.2 232.8   359.7 lit   max
2011/05/14 23:24:43  10.9 149.4  1245.3 lit   set
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
2011/05/15 23:45:28  11.0 237.6  1238.1 lit   rise
2011/05/15 23:45:36  11.0 234.8  1236.9 lit   max
2011/05/15 23:45:44  11.0 232.0  1238.3 lit   set
EOD

is format_pass( $pass[3] ), <<'EOD', 'Pass 4';
2011/05/17 09:59:17  11.0 154.7  1236.0 lit   rise
2011/05/17 10:00:38  13.9 125.1  1091.2 lit   max
2011/05/17 10:01:59  11.0  95.5  1236.0 lit   set
EOD

is format_pass( $pass[4] ), <<'EOD', 'Pass 5';
2011/05/18 10:21:25  11.1 217.9  1230.4 lit   rise
2011/05/18 10:24:09  81.8 307.8   347.4 lit   max
2011/05/18 10:26:53  11.0  33.4  1233.7 lit   set
EOD

is format_pass( $pass[5] ), <<'EOD', 'Pass 6';
2011/05/19 09:11:21  11.0 155.1  1233.2 shdw  rise
2011/05/19 09:12:10  13.4 138.2  1109.8 lit   lit
2011/05/19 09:12:43  14.0 125.1  1084.3 lit   max
2011/05/19 09:14:06  10.9  94.7  1237.1 lit   set
EOD

is format_pass( $pass[6] ), <<'EOD', 'Pass 7';
2011/05/20 09:33:24  11.1 218.1  1230.7 shdw  rise
2011/05/20 09:35:30  50.2 226.7   439.8 shdw  apls
                     50.3 226.0     0.5 Moon
2011/05/20 09:35:31  50.6 226.9   437.4 lit   lit
2011/05/20 09:36:08  81.0 307.4   347.6 lit   max
2011/05/20 09:38:52  11.0  33.1  1233.7 lit   set
EOD


# Purpose of test: Confirm that extremely short passes are reported
# reliably, and have their maximum elevations correctly calculated.

@pass = ();
$offset = 44;
if ( eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( $offset, 0, 17, 13, 4, 111 ),
	    timegm( $offset, 0, 17, 20, 4, 111 ),
	    [ $moon ],
	);
	1;
    } ) {
    ok @pass == 7,
	"Found 7 passes over Bogota at $offset sec after minute"
	or diag "Found @{[ scalar @pass ]} passes over Bogota";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
2011/05/14 00:32:45  11.0 244.1  1237.5 lit   rise
2011/05/14 00:33:11  11.3 234.9  1223.3 lit   max
2011/05/14 00:33:39  11.0 225.1  1239.4 lit   set
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
2011/05/14 23:19:14  11.1 319.6  1232.4 lit   rise
2011/05/14 23:21:58  73.2 232.8   359.7 lit   max
2011/05/14 23:24:43  10.9 149.4  1245.3 lit   set
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
2011/05/15 23:45:28  11.0 237.6  1238.1 lit   rise
2011/05/15 23:45:36  11.0 234.8  1236.9 lit   max
2011/05/15 23:45:44  11.0 232.0  1238.3 lit   set
EOD

is format_pass( $pass[3] ), <<'EOD', 'Pass 4';
2011/05/17 09:59:17  11.0 154.7  1236.0 lit   rise
2011/05/17 10:00:38  13.9 125.1  1091.2 lit   max
2011/05/17 10:01:59  11.0  95.5  1236.0 lit   set
EOD

is format_pass( $pass[4] ), <<'EOD', 'Pass 5';
2011/05/18 10:21:25  11.1 217.9  1230.4 lit   rise
2011/05/18 10:24:09  81.8 307.8   347.4 lit   max
2011/05/18 10:26:53  11.0  33.4  1233.7 lit   set
EOD

is format_pass( $pass[5] ), <<'EOD', 'Pass 6';
2011/05/19 09:11:21  11.0 155.1  1233.2 shdw  rise
2011/05/19 09:12:10  13.4 138.2  1109.8 lit   lit
2011/05/19 09:12:43  14.0 125.1  1084.3 lit   max
2011/05/19 09:14:06  10.9  94.7  1237.1 lit   set
EOD

# Purpose of test: Confirm that appulses are correctly reported.

is format_pass( $pass[6] ), <<'EOD', 'Pass 7';
2011/05/20 09:33:24  11.1 218.1  1230.7 shdw  rise
2011/05/20 09:35:30  50.2 226.7   439.8 shdw  apls
                     50.3 226.0     0.5 Moon
2011/05/20 09:35:31  50.6 226.9   437.4 lit   lit
2011/05/20 09:36:08  81.0 307.4   347.6 lit   max
2011/05/20 09:38:52  11.0  33.1  1233.7 lit   set
EOD


# Purpose of test: confirm that passes in progress at the beginning of
# the prediciton interval are correctly reported.

$sta = Astro::Coord::ECI->new(
    name	=> 'Sao Paulo',
)->geodetic(
    deg2rad( -23.55 ),
    deg2rad( -46.6333333333333 ),
    0,
);


( $tle ) = get_oid( '03597', @all_tle );
$tle->set( visible => 0 );

@pass = ();
$offset = 0;

if ( eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( $offset, 0, 12, 27, 4, 111 ),
	    timegm( $offset, 0, 13, 27, 4, 111 ),
	    [ $moon ],
	);
	1;
    } ) {
    ok @pass == 1,
	"Found 1 pass of OAO 2 over Sao Paulo at $offset sec after minute"
	or diag "Found @{[ scalar @pass ]} passes over Sao Paulo";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1 of OAO 2 over Sao Paulo';
2011/05/27 11:58:17  20.0 204.7  1678.3 day   rise
2011/05/27 11:59:57  23.2 178.2  1545.7 day   max
2011/05/27 12:01:38  20.0 151.4  1681.3 day   set
EOD

$sta = Astro::Coord::ECI->new(
    name	=> 'Shanghai',
)->geodetic(
    deg2rad( 31.2 ),
    deg2rad( 121.5 ),
    0,
);


# Purpose of test: Confirm that visible passes which begin during the
# day are correctly reported.

$tle->set( visible => 1 );

@pass = ();
$offset = 0;
if ( eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( $offset, 0,  6, 31, 4, 111 ),
	    timegm( $offset, 0, 18, 31, 4, 111 ),
	    [ $moon ],
	);
	1;
    } ) {
    ok @pass == 2,
	"Found 2 passes of OAO 2 over Shanghai at $offset sec after minute"
	or diag "Found @{[ scalar @pass ]} passes over Shanghai";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1 of OAO 2 over Shanghai';
2011/05/31 11:18:59  20.0 290.7  1670.5 day   rise
2011/05/31 11:19:47  26.8 295.3  1407.6 lit   lit
2011/05/31 11:22:34  58.1   4.3   861.2 lit   max
2011/05/31 11:26:10  20.0  78.8  1671.0 lit   set
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2 of OAO 2 over Shanghai';
2011/05/31 13:04:35  20.1 285.0  1664.5 lit   rise
2011/05/31 13:08:17  79.9 200.9   753.7 lit   max
2011/05/31 13:08:59  66.3 134.4   803.5 shdw  shdw
2011/05/31 13:12:00  19.9 115.4  1666.5 shdw  set
EOD


# Purpose of test: Confirm that passes which occur extremely close to
# the end of the prediction interval are reported.

( $tle ) = get_oid( '21938', @all_tle );

@pass = ();
$offset = 0;
if ( eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( $offset, 0,  6, 3, 5, 111 ),
	    timegm( $offset, 0, 12, 3, 5, 111 ),
	    [ $moon ],
	);
	1;
    } ) {
    ok @pass == 1,
	"Found 1 pass of OID 21938 over Shanghai at $offset sec after minute"
	or diag "Found @{[ scalar @pass ]} passes over Shanghai";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1 of OID 21938 over Shanghai';
2011/06/03 11:51:51  20.0 146.8  2124.6 lit   rise
2011/06/03 11:55:44  40.1  89.3  1432.8 lit   max
2011/06/03 11:59:38  20.0  32.1  2138.7 lit   set
EOD


# Purpose of test: Confirm that the interval attribute correctly infers
# the illumination.

( $tle ) = get_oid( '00733', @all_tle );

@pass = ();
$offset = 0;
if ( eval {
	$tle->set( interval => 1 );
	@pass = $tle->pass(
	    $sta,
	    timegm( $offset, 0, 14, 30, 4, 111 ),
	    timegm( $offset, 0, 16, 30, 4, 111 ),
	    [ $moon ],
	);
	1;
    } ) {
    ok @pass == 1,
	"Found 1 pass of OID 00733 over Shanghai at $offset sec after minute"
	or diag "Found @{[ scalar @pass ]} passes over Shanghai";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1 of OID 00733 over Shanghai';
2011/05/30 14:12:20  20.0 234.7  1759.9 shdw  rise
2011/05/30 14:12:21  20.1 234.9  1757.1 shdw
2011/05/30 14:12:22  20.2 235.2  1754.2 shdw
2011/05/30 14:12:23  20.2 235.4  1751.3 shdw
2011/05/30 14:12:24  20.3 235.6  1748.5 shdw
2011/05/30 14:12:25  20.3 235.9  1745.7 shdw
2011/05/30 14:12:26  20.4 236.1  1743.0 shdw
2011/05/30 14:12:27  20.5 236.3  1740.2 shdw
2011/05/30 14:12:28  20.5 236.6  1737.5 shdw
2011/05/30 14:12:29  20.6 236.8  1734.8 shdw
2011/05/30 14:12:30  20.6 237.1  1732.1 shdw
2011/05/30 14:12:31  20.7 237.3  1729.4 shdw
2011/05/30 14:12:32  20.7 237.6  1726.8 shdw
2011/05/30 14:12:33  20.8 237.8  1724.2 shdw
2011/05/30 14:12:34  20.9 238.0  1721.6 shdw
2011/05/30 14:12:35  20.9 238.3  1719.1 shdw
2011/05/30 14:12:36  21.0 238.5  1716.5 shdw
2011/05/30 14:12:37  21.0 238.8  1714.0 shdw
2011/05/30 14:12:38  21.1 239.0  1711.5 shdw
2011/05/30 14:12:39  21.1 239.3  1709.1 shdw
2011/05/30 14:12:40  21.2 239.5  1706.7 shdw
2011/05/30 14:12:41  21.2 239.8  1704.2 shdw
2011/05/30 14:12:42  21.3 240.0  1701.9 shdw
2011/05/30 14:12:43  21.3 240.3  1699.5 shdw
2011/05/30 14:12:44  21.4 240.5  1697.2 shdw
2011/05/30 14:12:45  21.5 240.8  1694.9 shdw
2011/05/30 14:12:46  21.5 241.1  1692.6 shdw
2011/05/30 14:12:47  21.6 241.3  1690.3 shdw
2011/05/30 14:12:48  21.6 241.6  1688.1 shdw
2011/05/30 14:12:49  21.7 241.8  1685.9 shdw
2011/05/30 14:12:50  21.7 242.1  1683.7 shdw
2011/05/30 14:12:51  21.8 242.3  1681.6 shdw
2011/05/30 14:12:52  21.8 242.6  1679.5 shdw
2011/05/30 14:12:53  21.9 242.9  1677.4 shdw
2011/05/30 14:12:54  21.9 243.1  1675.3 shdw
2011/05/30 14:12:55  21.9 243.4  1673.2 shdw
2011/05/30 14:12:56  22.0 243.7  1671.2 shdw
2011/05/30 14:12:57  22.0 243.9  1669.2 shdw
2011/05/30 14:12:58  22.1 244.2  1667.3 shdw
2011/05/30 14:12:59  22.1 244.5  1665.3 shdw
2011/05/30 14:13:00  22.2 244.7  1663.4 shdw
2011/05/30 14:13:01  22.2 245.0  1661.6 shdw
2011/05/30 14:13:02  22.3 245.3  1659.7 shdw
2011/05/30 14:13:03  22.3 245.5  1657.9 shdw
2011/05/30 14:13:04  22.3 245.8  1656.1 shdw
2011/05/30 14:13:05  22.4 246.1  1654.3 shdw
2011/05/30 14:13:06  22.4 246.3  1652.6 shdw
2011/05/30 14:13:07  22.5 246.6  1650.8 shdw
2011/05/30 14:13:08  22.5 246.9  1649.2 shdw
2011/05/30 14:13:09  22.5 247.2  1647.5 shdw
2011/05/30 14:13:10  22.6 247.4  1645.9 shdw
2011/05/30 14:13:11  22.6 247.7  1644.3 shdw
2011/05/30 14:13:12  22.7 248.0  1642.7 shdw
2011/05/30 14:13:13  22.7 248.3  1641.1 shdw
2011/05/30 14:13:14  22.7 248.5  1639.6 shdw
2011/05/30 14:13:15  22.8 248.8  1638.1 shdw
2011/05/30 14:13:16  22.8 249.1  1636.7 shdw
2011/05/30 14:13:17  22.8 249.4  1635.2 shdw
2011/05/30 14:13:18  22.9 249.7  1633.8 shdw
2011/05/30 14:13:19  22.9 249.9  1632.5 shdw
2011/05/30 14:13:20  22.9 250.2  1631.1 shdw
2011/05/30 14:13:21  23.0 250.5  1629.8 shdw
2011/05/30 14:13:22  23.0 250.8  1628.5 shdw
2011/05/30 14:13:23  23.0 251.1  1627.2 shdw
2011/05/30 14:13:24  23.1 251.3  1626.0 shdw
2011/05/30 14:13:25  23.1 251.6  1624.8 shdw
2011/05/30 14:13:26  23.1 251.9  1623.6 shdw
2011/05/30 14:13:27  23.1 252.2  1622.5 shdw
2011/05/30 14:13:28  23.2 252.5  1621.4 shdw
2011/05/30 14:13:29  23.2 252.8  1620.3 shdw
2011/05/30 14:13:30  23.2 253.1  1619.2 shdw
2011/05/30 14:13:31  23.3 253.3  1618.2 shdw
2011/05/30 14:13:32  23.3 253.6  1617.2 shdw
2011/05/30 14:13:33  23.3 253.9  1616.3 shdw
2011/05/30 14:13:34  23.3 254.2  1615.3 shdw
2011/05/30 14:13:35  23.3 254.5  1614.4 shdw
2011/05/30 14:13:36  23.4 254.8  1613.5 shdw
2011/05/30 14:13:37  23.4 255.1  1612.7 shdw
2011/05/30 14:13:38  23.4 255.4  1611.9 shdw
2011/05/30 14:13:39  23.4 255.7  1611.1 shdw
2011/05/30 14:13:40  23.4 255.9  1610.3 shdw
2011/05/30 14:13:41  23.5 256.2  1609.6 shdw
2011/05/30 14:13:42  23.5 256.5  1608.9 shdw
2011/05/30 14:13:43  23.5 256.8  1608.2 shdw
2011/05/30 14:13:44  23.5 257.1  1607.6 shdw
2011/05/30 14:13:45  23.5 257.4  1607.0 shdw
2011/05/30 14:13:46  23.5 257.7  1606.4 shdw
2011/05/30 14:13:47  23.6 258.0  1605.9 shdw
2011/05/30 14:13:48  23.6 258.3  1605.4 shdw
2011/05/30 14:13:49  23.6 258.6  1604.9 shdw
2011/05/30 14:13:50  23.6 258.9  1604.4 shdw
2011/05/30 14:13:51  23.6 259.2  1604.0 shdw
2011/05/30 14:13:52  23.6 259.5  1603.6 shdw
2011/05/30 14:13:53  23.6 259.8  1603.2 shdw
2011/05/30 14:13:54  23.6 260.0  1602.9 shdw
2011/05/30 14:13:55  23.6 260.3  1602.6 shdw
2011/05/30 14:13:56  23.6 260.6  1602.3 shdw
2011/05/30 14:13:57  23.6 260.9  1602.1 shdw
2011/05/30 14:13:58  23.6 261.2  1601.9 shdw
2011/05/30 14:13:59  23.6 261.5  1601.7 shdw
2011/05/30 14:14:00  23.7 261.8  1601.6 shdw
2011/05/30 14:14:01  23.7 262.1  1601.4 shdw
2011/05/30 14:14:02  23.7 262.4  1601.4 shdw
2011/05/30 14:14:03  23.7 262.7  1601.3 shdw
2011/05/30 14:14:04  23.7 263.0  1601.3 shdw  max
2011/05/30 14:14:05  23.7 263.3  1601.3 lit   lit
2011/05/30 14:14:06  23.7 263.6  1601.3 lit
2011/05/30 14:14:07  23.7 263.9  1601.4 lit
2011/05/30 14:14:08  23.6 264.2  1601.5 lit
2011/05/30 14:14:09  23.6 264.5  1601.6 lit
2011/05/30 14:14:10  23.6 264.8  1601.8 lit
2011/05/30 14:14:11  23.6 265.1  1601.9 lit
2011/05/30 14:14:12  23.6 265.4  1602.2 lit
2011/05/30 14:14:13  23.6 265.6  1602.4 lit
2011/05/30 14:14:14  23.6 265.9  1602.7 lit
2011/05/30 14:14:15  23.6 266.2  1603.0 lit
2011/05/30 14:14:16  23.6 266.5  1603.3 lit
2011/05/30 14:14:17  23.6 266.8  1603.7 lit
2011/05/30 14:14:18  23.6 267.1  1604.1 lit
2011/05/30 14:14:19  23.6 267.4  1604.5 lit
2011/05/30 14:14:20  23.6 267.7  1605.0 lit
2011/05/30 14:14:21  23.5 268.0  1605.5 lit
2011/05/30 14:14:22  23.5 268.3  1606.0 lit
2011/05/30 14:14:23  23.5 268.6  1606.6 lit
2011/05/30 14:14:24  23.5 268.9  1607.1 lit
2011/05/30 14:14:25  23.5 269.2  1607.8 lit
2011/05/30 14:14:26  23.5 269.5  1608.4 lit
2011/05/30 14:14:27  23.4 269.7  1609.1 lit
2011/05/30 14:14:28  23.4 270.0  1609.8 lit
2011/05/30 14:14:29  23.4 270.3  1610.5 lit
2011/05/30 14:14:30  23.4 270.6  1611.3 lit
2011/05/30 14:14:31  23.4 270.9  1612.1 lit
2011/05/30 14:14:32  23.3 271.2  1612.9 lit
2011/05/30 14:14:33  23.3 271.5  1613.7 lit
2011/05/30 14:14:34  23.3 271.8  1614.6 lit
2011/05/30 14:14:35  23.3 272.1  1615.5 lit
2011/05/30 14:14:36  23.3 272.4  1616.5 lit
2011/05/30 14:14:37  23.2 272.6  1617.5 lit
2011/05/30 14:14:38  23.2 272.9  1618.5 lit
2011/05/30 14:14:39  23.2 273.2  1619.5 lit
2011/05/30 14:14:40  23.1 273.5  1620.6 lit
2011/05/30 14:14:41  23.1 273.8  1621.6 lit
2011/05/30 14:14:42  23.1 274.1  1622.8 lit
2011/05/30 14:14:43  23.1 274.4  1623.9 lit
2011/05/30 14:14:44  23.0 274.6  1625.1 lit
2011/05/30 14:14:45  23.0 274.9  1626.3 lit
2011/05/30 14:14:46  23.0 275.2  1627.5 lit
2011/05/30 14:14:47  22.9 275.5  1628.8 lit
2011/05/30 14:14:48  22.9 275.8  1630.1 lit
2011/05/30 14:14:49  22.9 276.1  1631.4 lit
2011/05/30 14:14:50  22.8 276.3  1632.8 lit
2011/05/30 14:14:51  22.8 276.6  1634.2 lit
2011/05/30 14:14:52  22.8 276.9  1635.6 lit
2011/05/30 14:14:53  22.7 277.2  1637.0 lit
2011/05/30 14:14:54  22.7 277.5  1638.5 lit
2011/05/30 14:14:55  22.7 277.7  1640.0 lit
2011/05/30 14:14:56  22.6 278.0  1641.5 lit
2011/05/30 14:14:57  22.6 278.3  1643.0 lit
2011/05/30 14:14:58  22.5 278.6  1644.6 lit
2011/05/30 14:14:59  22.5 278.8  1646.2 lit
2011/05/30 14:15:00  22.5 279.1  1647.9 lit
2011/05/30 14:15:01  22.4 279.4  1649.5 lit
2011/05/30 14:15:02  22.4 279.7  1651.2 lit
2011/05/30 14:15:03  22.3 279.9  1653.0 lit
2011/05/30 14:15:04  22.3 280.2  1654.7 lit
2011/05/30 14:15:05  22.3 280.5  1656.5 lit
2011/05/30 14:15:06  22.2 280.7  1658.3 lit
2011/05/30 14:15:07  22.2 281.0  1660.1 lit
2011/05/30 14:15:08  22.1 281.3  1662.0 lit
2011/05/30 14:15:09  22.1 281.5  1663.9 lit
2011/05/30 14:15:10  22.0 281.8  1665.8 lit
2011/05/30 14:15:11  22.0 282.1  1667.7 lit
2011/05/30 14:15:12  21.9 282.3  1669.7 lit
2011/05/30 14:15:13  21.9 282.6  1671.7 lit
2011/05/30 14:15:14  21.8 282.9  1673.7 lit
2011/05/30 14:15:15  21.8 283.1  1675.7 lit
2011/05/30 14:15:16  21.8 283.4  1677.8 lit
2011/05/30 14:15:17  21.7 283.7  1679.9 lit
2011/05/30 14:15:18  21.7 283.9  1682.0 lit
2011/05/30 14:15:19  21.6 284.2  1684.2 lit
2011/05/30 14:15:20  21.5 284.4  1686.4 lit
2011/05/30 14:15:21  21.5 284.7  1688.6 lit
2011/05/30 14:15:22  21.4 284.9  1690.8 lit
2011/05/30 14:15:23  21.4 285.2  1693.1 lit
2011/05/30 14:15:24  21.3 285.5  1695.3 lit
2011/05/30 14:15:25  21.3 285.7  1697.7 lit
2011/05/30 14:15:26  21.2 286.0  1700.0 lit
2011/05/30 14:15:27  21.2 286.2  1702.3 lit
2011/05/30 14:15:28  21.1 286.5  1704.7 lit
2011/05/30 14:15:29  21.1 286.7  1707.1 lit
2011/05/30 14:15:30  21.0 287.0  1709.6 lit
2011/05/30 14:15:31  21.0 287.2  1712.0 lit
2011/05/30 14:15:32  20.9 287.5  1714.5 lit
2011/05/30 14:15:33  20.8 287.7  1717.0 lit
2011/05/30 14:15:34  20.8 288.0  1719.6 lit
2011/05/30 14:15:35  20.7 288.2  1722.1 lit
2011/05/30 14:15:36  20.7 288.5  1724.7 lit
2011/05/30 14:15:37  20.6 288.7  1727.3 lit
2011/05/30 14:15:38  20.6 288.9  1729.9 lit
2011/05/30 14:15:39  20.5 289.2  1732.6 lit
2011/05/30 14:15:40  20.4 289.4  1735.3 lit
2011/05/30 14:15:41  20.4 289.7  1738.0 lit
2011/05/30 14:15:42  20.3 289.9  1740.7 lit
2011/05/30 14:15:43  20.3 290.1  1743.5 lit
2011/05/30 14:15:44  20.2 290.4  1746.2 lit
2011/05/30 14:15:45  20.1 290.6  1749.0 lit
2011/05/30 14:15:46  20.1 290.8  1751.9 lit
2011/05/30 14:15:47  20.0 291.1  1754.7 lit
2011/05/30 14:15:48  20.0 291.3  1757.6 lit   set
EOD


########################################################################

sub get_oid {
    my ( $oid, @all_tle ) = @_;
    return Astro::Coord::ECI::TLE::Set->aggregate(
	grep { $_->get( 'id' ) == $oid } @all_tle );
}

1;

# ex: set filetype=perl textwidth=72 :
