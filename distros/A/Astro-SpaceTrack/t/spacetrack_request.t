package main;

use strict;
use warnings;

use Test::More 0.96;

use Astro::SpaceTrack qw{ :ref };
use HTTP::Status qw{ HTTP_I_AM_A_TEAPOT };

use lib 'inc';

use Mock::LWP::UserAgent;

use constant DUMP_REQUEST => Astro::SpaceTrack->DUMP_REQUEST |
    Astro::SpaceTrack->DUMP_DRY_RUN;
use constant DUMP_NONE => Astro::SpaceTrack->DUMP_NONE;

my $loader = Astro::SpaceTrack->__get_loader() or do {
    plan skip_all => 'JSON required to check Space Track requests.';
    exit;
};

note 'Space Track v2 interface';

my $st = Astro::SpaceTrack->new(
    space_track_version	=> 2,
    dump_headers => DUMP_REQUEST,
    username	=> 'Yehudi',
    password	=> 'Menuhin',
);

my $base_url = $st->_make_space_track_base_url();

is_resp( qw{retrieve 25544}, [ {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'tle_latest',
	    format	=> 'tle',
	    orderby	=> 'OBJECT_NUMBER asc',
	    OBJECT_NUMBER => 25544,
	    ORDINAL	=> 1,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/OBJECT_NUMBER%20asc/OBJECT_NUMBER/25544/ORDINAL/1",
	version => 2,
    } ],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{retrieve 25544}, <<'EOD' );
1 25544U First line of data
2 25544 Second line of data
EOD

$st->set( dump_headers => DUMP_REQUEST );

is_resp( qw{retrieve -sort catnum 25544}, [ {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'tle_latest',
	    format	=> 'tle',
	    orderby	=> 'OBJECT_NUMBER asc',
	    OBJECT_NUMBER => 25544,
	    ORDINAL	=> 1,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/OBJECT_NUMBER%20asc/OBJECT_NUMBER/25544/ORDINAL/1",
	version => 2,
    } ],
 );

is_resp( qw{retrieve -sort epoch 25544}, [ {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'tle_latest',
	    format	=> 'tle',
	    orderby	=> 'EPOCH asc',
	    OBJECT_NUMBER => 25544,
	    ORDINAL	=> 1,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/EPOCH%20asc/OBJECT_NUMBER/25544/ORDINAL/1",
	version => 2,
    } ],
 );

is_resp( qw{retrieve -descending 25544}, [ {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'tle_latest',
	    format	=> 'tle',
	    orderby	=> 'OBJECT_NUMBER desc',
	    OBJECT_NUMBER => 25544,
	    ORDINAL	=> 1,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/OBJECT_NUMBER%20desc/OBJECT_NUMBER/25544/ORDINAL/1",
	version => 2,
    } ],
 );

is_resp( qw{retrieve -last5 25544}, [ {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'tle_latest',
	    format	=> 'tle',
	    orderby	=> 'OBJECT_NUMBER asc',
	    OBJECT_NUMBER => 25544,
	    ORDINAL	=> '1--5',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/OBJECT_NUMBER%20asc/OBJECT_NUMBER/25544/ORDINAL/1--5",
	version => 2,
    } ],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{retrieve -last5 25544}, <<'EOD' );
1 25544U First line of data
2 25544 Second line of data
1 25544U First line of data
2 25544 Second line of data
1 25544U First line of data
2 25544 Second line of data
1 25544U First line of data
2 25544 Second line of data
1 25544U First line of data
2 25544 Second line of data
EOD

$st->set( dump_headers => DUMP_REQUEST );

{
    no warnings qw{ uninitialized };
    local $ENV{SPACETRACK_REST_FRACTIONAL_DATE} = undef;

    is_resp( qw{retrieve -start_epoch 2009-04-01 25544}, [ {
	    args => [
		basicspacedata	=> 'query',
		class	=> 'tle',
		format	=> 'tle',
		orderby	=> 'OBJECT_NUMBER asc',
		EPOCH	=> '2009-04-01 00:00:00--2009-04-02 00:00:00',
		OBJECT_NUMBER => 25544,
	    ],
	    method => 'GET',
	    url => "$base_url/basicspacedata/query/class/tle/format/tle/orderby/OBJECT_NUMBER%20asc/EPOCH/2009-04-01%2000:00:00--2009-04-02%2000:00:00/OBJECT_NUMBER/25544",
	    version => 2,
	} ],
     );

    is_resp( qw{retrieve -last5 -start_epoch 2009-04-01 25544}, [ {
	    args => [
		basicspacedata	=> 'query',
		class	=> 'tle',
		format	=> 'tle',
		orderby	=> 'OBJECT_NUMBER asc',
		EPOCH	=> '2009-04-01 00:00:00--2009-04-02 00:00:00',
		OBJECT_NUMBER => 25544,
	    ],
	    method => 'GET',
	    url => "$base_url/basicspacedata/query/class/tle/format/tle/orderby/OBJECT_NUMBER%20asc/EPOCH/2009-04-01%2000:00:00--2009-04-02%2000:00:00/OBJECT_NUMBER/25544",
	    version => 2,
	} ],
     );

    is_resp( qw{retrieve -end_epoch 2009-04-01 25544}, [ {
	    args => [
		basicspacedata	=> 'query',
		class	=> 'tle',
		format	=> 'tle',
		orderby	=> 'OBJECT_NUMBER asc',
		EPOCH	=> '2009-03-31 00:00:00--2009-04-01 00:00:00',
		OBJECT_NUMBER => 25544,
	    ],
	    method => 'GET',
	    url => "$base_url/basicspacedata/query/class/tle/format/tle/orderby/OBJECT_NUMBER%20asc/EPOCH/2009-03-31%2000:00:00--2009-04-01%2000:00:00/OBJECT_NUMBER/25544",
	    version => 2,
	} ],
     );

    is_resp( qw{retrieve -start_epoch 2009-03-01 -end_epoch 2009-04-01 25544}, [ {
	    args => [
		basicspacedata	=> 'query',
		class	=> 'tle',
		format	=> 'tle',
		orderby	=> 'OBJECT_NUMBER asc',
		EPOCH	=> '2009-03-01 00:00:00--2009-04-01 00:00:00',
		OBJECT_NUMBER => 25544,
	    ],
	    method => 'GET',
	    url => "$base_url/basicspacedata/query/class/tle/format/tle/orderby/OBJECT_NUMBER%20asc/EPOCH/2009-03-01%2000:00:00--2009-04-01%2000:00:00/OBJECT_NUMBER/25544",
	    version => 2,
	} ],
     );

}

note <<'EOD';
The point of the following test is to ensure that the request is being
properly broken into two pieces, and that the joining of the JSON in the
responses is being handled properly.
EOD

{

    local $Astro::SpaceTrack::RETRIEVAL_SIZE = 50;
    # Force undocumented hack to be turned off.
    no warnings qw{ uninitialized };
    local $ENV{SPACETRACK_REST_RANGE_OPERATOR} = undef;

    is_resp( retrieve => 1 .. 66, [
	{
	    args => [
		basicspacedata	=> 'query',
		class		=> 'tle_latest',
		format		=> 'tle',
		orderby		=> 'OBJECT_NUMBER asc',
		OBJECT_NUMBER	=> '1--50',
		ORDINAL		=> 1,
	    ],
	    method	=> 'GET',
	    url => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/OBJECT_NUMBER%20asc/OBJECT_NUMBER/1--50/ORDINAL/1",
	    version	=> 2
	},
	{
	    args => [
		basicspacedata	=> 'query',
		class		=> 'tle_latest',
		format		=> 'tle',
		orderby		=> 'OBJECT_NUMBER asc',
		OBJECT_NUMBER	=> '51--66',
		ORDINAL		=> 1,
	    ],
	    method	=> 'GET',
	    url => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/OBJECT_NUMBER%20asc/OBJECT_NUMBER/51--66/ORDINAL/1",
	    version	=> 2
	},
    ],
     );

    $st->set( dump_headers => DUMP_NONE );

    is_resp( retrieve => 1 .. 66, <<'EOD' );
1 00004U First line of data
2 00004 Second line of data
1 00005U First line of data
2 00005 Second line of data
1 00008U First line of data
2 00008 Second line of data
1 00009U First line of data
2 00009 Second line of data
1 00011U First line of data
2 00011 Second line of data
1 00012U First line of data
2 00012 Second line of data
1 00015U First line of data
2 00015 Second line of data
1 00016U First line of data
2 00016 Second line of data
1 00017U First line of data
2 00017 Second line of data
1 00018U First line of data
2 00018 Second line of data
1 00019U First line of data
2 00019 Second line of data
1 00020U First line of data
2 00020 Second line of data
1 00022U First line of data
2 00022 Second line of data
1 00023U First line of data
2 00023 Second line of data
1 00024U First line of data
2 00024 Second line of data
1 00025U First line of data
2 00025 Second line of data
1 00026U First line of data
2 00026 Second line of data
1 00028U First line of data
2 00028 Second line of data
1 00029U First line of data
2 00029 Second line of data
1 00030U First line of data
2 00030 Second line of data
1 00031U First line of data
2 00031 Second line of data
1 00032U First line of data
2 00032 Second line of data
1 00033U First line of data
2 00033 Second line of data
1 00034U First line of data
2 00034 Second line of data
1 00035U First line of data
2 00035 Second line of data
1 00036U First line of data
2 00036 Second line of data
1 00037U First line of data
2 00037 Second line of data
1 00038U First line of data
2 00038 Second line of data
1 00039U First line of data
2 00039 Second line of data
1 00040U First line of data
2 00040 Second line of data
1 00041U First line of data
2 00041 Second line of data
1 00042U First line of data
2 00042 Second line of data
1 00043U First line of data
2 00043 Second line of data
1 00044U First line of data
2 00044 Second line of data
1 00045U First line of data
2 00045 Second line of data
1 00046U First line of data
2 00046 Second line of data
1 00047U First line of data
2 00047 Second line of data
1 00048U First line of data
2 00048 Second line of data
1 00049U First line of data
2 00049 Second line of data
1 00050U First line of data
2 00050 Second line of data
1 00051U First line of data
2 00051 Second line of data
1    52U First line of data
2    52 Second line of data
1 00053U First line of data
2 00053 Second line of data
1 00054U First line of data
2 00054 Second line of data
1 00055U First line of data
2 00055 Second line of data
1 00056U First line of data
2 00056 Second line of data
1 00057U First line of data
2 00057 Second line of data
1 00058U First line of data
2 00058 Second line of data
1 00059U First line of data
2 00059 Second line of data
1 00060U First line of data
2 00060 Second line of data
1 00061U First line of data
2 00061 Second line of data
1 00062U First line of data
2 00062 Second line of data
1 00063U First line of data
2 00063 Second line of data
1 00064U First line of data
2 00064 Second line of data
1 00065U First line of data
2 00065 Second line of data
1 00066U First line of data
2 00066 Second line of data
EOD

    $st->set( dump_headers => DUMP_REQUEST );
}

is_resp( qw{set with_name 1}, 'OK' );

# NOTE That the following request is forced to JSON format so that we
# can build a NASA-format TLE from the result.
is_resp( qw{retrieve 25544}, [ {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'tle_latest',
	    format	=> '3le',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'OBJECT_NAME,TLE_LINE1,TLE_LINE2',
	    OBJECT_NUMBER => 25544,
	    ORDINAL	=> 1,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/tle_latest/format/3le/orderby/OBJECT_NUMBER%20asc/predicates/OBJECT_NAME,TLE_LINE1,TLE_LINE2/OBJECT_NUMBER/25544/ORDINAL/1",
	version => 2,
    } ],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{retrieve 25544}, <<'EOD' );
ISS (ZARYA)
1 25544U First line of data
2 25544 Second line of data
EOD

$st->set( dump_headers => DUMP_REQUEST );

is_resp( qw{search_date 2009-04-01}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    LAUNCH	=> '2009-04-01',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/LAUNCH/2009-04-01",
	version => 2,
    },
],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{search_date 2009-04-01}, '412 No catalog IDs specified.' );

$st->set( dump_headers => DUMP_REQUEST );

is_resp( qw{search_date -status all 2009-04-01}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    LAUNCH	=> '2009-04-01',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/LAUNCH/2009-04-01",
	version => 2,
    },
],
 );

is_resp( qw{search_date -status onorbit 2009-04-01}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    LAUNCH	=> '2009-04-01',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/LAUNCH/2009-04-01",
	version => 2,
    },
],
 );

is_resp( qw{search_date -status decayed 2009-04-01}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> '<>null-val',
	    LAUNCH	=> '2009-04-01',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/%3C%3Enull-val/LAUNCH/2009-04-01",
	version => 2,
    },
],
 );

is_resp( qw{search_date -exclude debris 2009-04-01}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    LAUNCH	=> '2009-04-01',
	    OBJECT_TYPE	=> 'OTHER,PAYLOAD,ROCKET BODY,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/LAUNCH/2009-04-01/OBJECT_TYPE/OTHER,PAYLOAD,ROCKET%20BODY,TBA,UNKNOWN",
	version => 2,
    },
],
 );

is_resp( qw{search_date -include payload 2009-04-01}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    LAUNCH	=> '2009-04-01',
	    OBJECT_TYPE	=> 'PAYLOAD',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/LAUNCH/2009-04-01/OBJECT_TYPE/PAYLOAD",
	version => 2,
    },
],
 );

is_resp( qw{search_date -exclude rocket 2009-04-01}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    LAUNCH	=> '2009-04-01',
	    OBJECT_TYPE	=> 'DEBRIS,OTHER,PAYLOAD,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/LAUNCH/2009-04-01/OBJECT_TYPE/DEBRIS,OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
    },
],
 );

{
    no warnings qw{qw};	## no critic (ProhibitNoWarnings)
    is_resp( qw{search_date -exclude debris,rocket 2009-04-01}, [
	{
	    args => [
		basicspacedata	=> 'query',
		class	=> 'satcat',
		format	=> 'json',
		orderby	=> 'OBJECT_NUMBER asc',
		predicates	=> 'all',
		CURRENT	=> 'Y',
		DECAY	=> 'null-val',
		LAUNCH	=> '2009-04-01',
		OBJECT_TYPE	=> 'OTHER,PAYLOAD,TBA,UNKNOWN',
	    ],
	    method => 'GET',
	    url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/LAUNCH/2009-04-01/OBJECT_TYPE/OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
	},
    ],
     );
}

is_resp( qw{search_date -exclude debris -exclude rocket 2009-04-01}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    LAUNCH	=> '2009-04-01',
	    OBJECT_TYPE	=> 'OTHER,PAYLOAD,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/LAUNCH/2009-04-01/OBJECT_TYPE/OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
    },
],
 );

is_resp( qw{search_id 98067}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_ID	=> '~~1998-067',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_ID/~~1998-067",
	version => 2,
    },
],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{search_id 98067}, <<'EOD' );
ISS (ZARYA)
1 25544U First line of data
2 25544 Second line of data
ISS DEB (VSPLESK PLTFRM)
1 39496U First line of data
2 39496 Second line of data
FLOCK 1-3
1 39512U First line of data
2 39512 Second line of data
FLOCK 1-1
1 39513U First line of data
2 39513 Second line of data
FLOCK 1-2
1 39514U First line of data
2 39514 Second line of data
FLOCK 1-4
1 39515U First line of data
2 39515 Second line of data
FLOCK 1-5
1 39518U First line of data
2 39518 Second line of data
FLOCK 1-6
1 39519U First line of data
2 39519 Second line of data
FLOCK 1-7
1 39520U First line of data
2 39520 Second line of data
FLOCK 1-8
1 39521U First line of data
2 39521 Second line of data
FLOCK 1-9
1 39525U First line of data
2 39525 Second line of data
FLOCK 1-10
1 39526U First line of data
2 39526 Second line of data
FLOCK 1-11
1 39527U First line of data
2 39527 Second line of data
FLOCK 1-12
1 39528U First line of data
2 39528 Second line of data
FLOCK 1-13
1 39529U First line of data
2 39529 Second line of data
FLOCK 1-14
1 39530U First line of data
2 39530 Second line of data
FLOCK 1-15
1 39531U First line of data
2 39531 Second line of data
FLOCK 1-16
1 39532U First line of data
2 39532 Second line of data
FLOCK 1-17
1 39555U First line of data
2 39555 Second line of data
FLOCK 1-18
1 39556U First line of data
2 39556 Second line of data
FLOCK 1-21
1 39557U First line of data
2 39557 Second line of data
FLOCK 1-22
1 39558U First line of data
2 39558 Second line of data
FLOCK 1-19
1 39559U First line of data
2 39559 Second line of data
FLOCK 1-20
1 39560U First line of data
2 39560 Second line of data
FLOCK 1-23
1 39561U First line of data
2 39561 Second line of data
FLOCK 1-24
1 39562U First line of data
2 39562 Second line of data
FLOCK 1-25
1 39563U First line of data
2 39563 Second line of data
FLOCK 1-26
1 39564U First line of data
2 39564 Second line of data
FLOCK 1-28
1 39566U First line of data
2 39566 Second line of data
ARDUSAT 2
1 39567U First line of data
2 39567 Second line of data
UAPSAT 1
1 39568U First line of data
2 39568 Second line of data
SKYCUBE
1 39569U First line of data
2 39569 Second line of data
LITSAT 1
1 39570U First line of data
2 39570 Second line of data
LITUANICASAT 1
1 39571U First line of data
2 39571 Second line of data
EOD

$st->set( dump_headers => DUMP_REQUEST );

is_resp( qw{search_id 98}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_ID	=> '~~1998-',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_ID/~~1998-",
	version => 2,
    },
],
 );

is_resp( qw{search_id 98067A}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_ID	=> '1998-067A',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_ID/1998-067A",
	version => 2,
    },
],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{search_id 98067A}, <<'EOD' );
ISS (ZARYA)
1 25544U First line of data
2 25544 Second line of data
EOD

$st->set( dump_headers => DUMP_REQUEST );

# TODO update below here

is_resp( qw{search_id -status all 98067}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    OBJECT_ID	=> '~~1998-067',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/OBJECT_ID/~~1998-067",
	version => 2,
    },
],
 );

is_resp( qw{search_id -status onorbit 98067}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_ID	=> '~~1998-067',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_ID/~~1998-067",
	version => 2,
    },
],
 );

is_resp( qw{search_id -status decayed 98067}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> '<>null-val',
	    OBJECT_ID	=> '~~1998-067',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/%3C%3Enull-val/OBJECT_ID/~~1998-067",
	version => 2,
    },
],
 );

is_resp( qw{search_id -exclude debris 98067}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_ID	=> '~~1998-067',
	    OBJECT_TYPE	=> 'OTHER,PAYLOAD,ROCKET BODY,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_ID/~~1998-067/OBJECT_TYPE/OTHER,PAYLOAD,ROCKET%20BODY,TBA,UNKNOWN",
	version => 2,
    },
],
 );

is_resp( qw{search_id -exclude rocket 98067}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_ID	=> '~~1998-067',
	    OBJECT_TYPE	=> 'DEBRIS,OTHER,PAYLOAD,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_ID/~~1998-067/OBJECT_TYPE/DEBRIS,OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
    },
],
 );

{
    no warnings qw{qw};	## no critic (ProhibitNoWarnings)
    is_resp( qw{search_id -exclude debris,rocket 98067}, [
	{
	    args => [
		basicspacedata	=> 'query',
		class	=> 'satcat',
		format	=> 'json',
		orderby	=> 'OBJECT_NUMBER asc',
		predicates	=> 'all',
		CURRENT	=> 'Y',
		DECAY	=> 'null-val',
		OBJECT_ID	=> '~~1998-067',
		OBJECT_TYPE	=> 'OTHER,PAYLOAD,TBA,UNKNOWN',
	    ],
	    method => 'GET',
	    url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_ID/~~1998-067/OBJECT_TYPE/OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
	}
    ],
     );
}

is_resp( qw{search_id -exclude debris -exclude rocket 98067}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_ID	=> '~~1998-067',
	    OBJECT_TYPE	=> 'OTHER,PAYLOAD,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_ID/~~1998-067/OBJECT_TYPE/OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
    },
],
 );

is_resp( qw{search_name ISS}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NAME	=> '~~ISS',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NAME/~~ISS",
	version => 2,
    },
],
 );

is_resp( qw{search_name -status all ISS}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    OBJECT_NAME	=> '~~ISS',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/OBJECT_NAME/~~ISS",
	version => 2,
    },
],
 );

is_resp( qw{search_name -status onorbit ISS}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NAME	=> '~~ISS',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NAME/~~ISS",
	version => 2,
    },
],
 );

is_resp( qw{search_name -status decayed ISS}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> '<>null-val',
	    OBJECT_NAME	=> '~~ISS',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/%3C%3Enull-val/OBJECT_NAME/~~ISS",
	version => 2,
    },
],
 );

is_resp( qw{search_name -exclude debris ISS}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NAME	=> '~~ISS',
	    OBJECT_TYPE	=> 'OTHER,PAYLOAD,ROCKET BODY,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NAME/~~ISS/OBJECT_TYPE/OTHER,PAYLOAD,ROCKET%20BODY,TBA,UNKNOWN",
	version => 2,
    },
],
 );

is_resp( qw{search_name -exclude rocket ISS}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NAME	=> '~~ISS',
	    OBJECT_TYPE	=> 'DEBRIS,OTHER,PAYLOAD,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NAME/~~ISS/OBJECT_TYPE/DEBRIS,OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
    },
],
 );

{
    no warnings qw{qw};	## no critic (ProhibitNoWarnings)
    is_resp( qw{search_name -exclude debris,rocket ISS}, [ {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NAME	=> '~~ISS',
	    OBJECT_TYPE	=> 'OTHER,PAYLOAD,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NAME/~~ISS/OBJECT_TYPE/OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
	} ],
     );
}

is_resp( qw{search_name -exclude debris -exclude rocket ISS}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NAME	=> '~~ISS',
	    OBJECT_TYPE	=> 'OTHER,PAYLOAD,TBA,UNKNOWN',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NAME/~~ISS/OBJECT_TYPE/OTHER,PAYLOAD,TBA,UNKNOWN",
	version => 2,
    },
],
 );

is_resp( qw{ search_oid 25544 }, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NUMBER	=> 25544,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NUMBER/25544",
	version => 2,
    },
],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{ search_oid 25544 }, <<'EOD' );
ISS (ZARYA)
1 25544U First line of data
2 25544 Second line of data
EOD

$st->set( dump_headers => DUMP_REQUEST );

is_resp( qw{ search_oid -format json 25544 }, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NUMBER	=> 25544,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NUMBER/25544",
	version => 2,
    },
],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{ search_oid -format json 25544 },
[
   {
      'COMMENT'	=> 'GENERATED VIA SPACETRACK.ORG API',
      'FILE'	=> '1681502',
      'INTLDES'	=> '98067A',
      'NORAD_CAT_ID'	=> '25544',
      'OBJECT_ID'	=> '1998-067A',
      'OBJECT_NAME'	=> 'ISS (ZARYA)',
      'OBJECT_NUMBER'	=> '25544',
      'OBJECT_TYPE'	=> 'PAYLOAD',
      'TLE_LINE0'	=> '0 ISS (ZARYA)',
      'TLE_LINE1'	=> '1 25544U First line of data',
      'TLE_LINE2'	=> '2 25544 Second line of data',
   }
]
 );

$st->set( dump_headers => DUMP_REQUEST );

is_resp( qw{ search_oid -format tle 25544 }, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NUMBER	=> 25544,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NUMBER/25544",
	version => 2,
    },
],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{ search_oid -format tle 25544 }, <<'EOD' );
1 25544U First line of data
2 25544 Second line of data
EOD

$st->set( dump_headers => DUMP_REQUEST );

is_resp( qw{ search_oid -format 3le 25544 }, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'satcat',
	    format	=> 'json',
	    orderby	=> 'OBJECT_NUMBER asc',
	    predicates	=> 'all',
	    CURRENT	=> 'Y',
	    DECAY	=> 'null-val',
	    OBJECT_NUMBER	=> 25544,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/satcat/format/json/orderby/OBJECT_NUMBER%20asc/predicates/all/CURRENT/Y/DECAY/null-val/OBJECT_NUMBER/25544",
	version => 2,
    },
],
 );

$st->set( dump_headers => DUMP_NONE );

is_resp( qw{ search_oid -format 3le 25544 }, <<'EOD' );
0 ISS (ZARYA)
1 25544U First line of data
2 25544 Second line of data
EOD

{
    my $with_name = $st->getv( 'with_name' );

    $st->set( with_name => 1 );

    is_resp( search_oid => {}, 25544, <<'EOD' );
ISS (ZARYA)
1 25544U First line of data
2 25544 Second line of data
EOD

    $st->set( with_name => 0 );

    is_resp( search_oid => {}, 25544, <<'EOD' );
1 25544U First line of data
2 25544 Second line of data
EOD

    $st->set( with_name => $with_name );
}

$st->set( dump_headers => DUMP_REQUEST );

is_resp( qw{spacetrack iridium}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class		=> 'tle_latest',
	    format		=> '3le',
	    orderby		=> 'OBJECT_NUMBER asc',
	    predicates		=> 'OBJECT_NAME,TLE_LINE1,TLE_LINE2',
	    EPOCH		=> '>now-30',
	    OBJECT_NAME		=> 'iridium~~',
	    OBJECT_TYPE		=> 'payload',
	    ORDINAL		=> 1,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/tle_latest/format/3le/orderby/OBJECT_NUMBER%20asc/predicates/OBJECT_NAME,TLE_LINE1,TLE_LINE2/EPOCH/%3Enow-30/OBJECT_NAME/iridium~~/OBJECT_TYPE/payload/ORDINAL/1",
	version => 2,
    },
],
 );

is_resp( qw{ spacetrack special }, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class		=> 'tle_latest',
	    favorites		=> 'Special_interest',
	    format		=> '3le',
	    predicates		=> 'OBJECT_NAME,TLE_LINE1,TLE_LINE2',
	    EPOCH		=> '>now-30',
	    ORDINAL		=> 1
	],
	method	=> 'GET',
	url	=> "$base_url/basicspacedata/query/class/tle_latest/favorites/Special_interest/format/3le/predicates/OBJECT_NAME,TLE_LINE1,TLE_LINE2/EPOCH/%3Enow-30/ORDINAL/1",
	version	=> 2
    },
],
 );

is_resp( qw{set with_name 0}, 'OK' );


is_resp( qw{spacetrack iridium}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class		=> 'tle_latest',
	    format		=> 'tle',
	    orderby		=> 'OBJECT_NUMBER asc',
	    EPOCH		=> '>now-30',
	    OBJECT_NAME		=> 'iridium~~',
	    OBJECT_TYPE		=> 'payload',
	    ORDINAL		=> 1,
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/OBJECT_NUMBER%20asc/EPOCH/%3Enow-30/OBJECT_NAME/iridium~~/OBJECT_TYPE/payload/ORDINAL/1",
	version => 2,
    },
],
 );

is_resp( qw{retrieve -json -since_file 1848000 25544 25546}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class		=> 'tle',
	    format		=> 'json',
	    orderby		=> 'OBJECT_NUMBER asc',
	    FILE		=> '>1848000',
	    OBJECT_NUMBER	=> '25544,25546',
	],
	method	=> "GET",
	url	=> "https://www.space-track.org/basicspacedata/query/class/tle/format/json/orderby/OBJECT_NUMBER%20asc/FILE/%3E1848000/OBJECT_NUMBER/25544,25546",
	version	=> 2,
    }
],
 );

=begin comment

# TODO Not supported by Space Track v2 interface
is_resp( qw{spacetrack 10}, {
	args => [
	    basicspacedata	=> 'query',
	],
	method => 'GET',
	url => $base_url,
	version => 2,
    },
 );

=end comment

=cut

is_resp( qw{box_score}, [
    {
	args => [
	    basicspacedata	=> 'query',
	    class	=> 'boxscore',
	    format	=> 'json',
	    predicates	=> 'all',
	],
	method => 'GET',
	url => "$base_url/basicspacedata/query/class/boxscore/format/json/predicates/all",
	version => 2,
    },
],
 );

done_testing;

my $warning;

sub warning_like {
    splice @_, 0, 0, $warning;
    goto &like;
}

sub is_resp {	## no critic (RequireArgUnpacking)
    my @args = @_;
    my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
    my $method = shift @args;
    my $query = pop @args;
    my $name = "\$st->$method(" . join( ', ', map {"'$_'"} @args ) . ')';
    my ( $resp, @extra );
    {
	$warning = undef;
	local $SIG{__WARN__} = sub { $warning = $_[0] };
	if ( $opt->{list_context} ) {
	    ( $resp, @extra ) = $st->$method( @args );
	} else {
	    $resp = $st->$method( @args );
	}
	not defined $warning
	    or $opt->{allow_warning}
	    or do {
	    $warning =~ s{\bat t/spacetrack_request.t\b.*}{}sm;
	    @_ = qq{$name. Unexpected warning "$warning"};
	    goto &fail;
	};
    }
    my ($got);

    if ( $resp && $resp->isa('HTTP::Response') ) {
	if ( $resp->code() == HTTP_I_AM_A_TEAPOT ) {
	    $got = $loader->( $resp->content() );
	} elsif ( $resp->is_success() ) {
	    $got = $resp->content();
	    $got =~ m/ \A \s* [[] \s* [{] .* [}] \s* []] \s* \z /smx
		and $got = $loader->( $got );
	} else {
	    $got = $resp->status_line();
	}
    } else {
	$got = $resp;
    }
    $opt->{list_context}
	and $got = [ $got, @extra ];

    @_ = ($got, $query, $name);
    ref $query
	and goto &is_deeply;
    goto &is;
}

sub year {
    return (localtime)[5] + 1900;
}

1;

__END__

# ex: set filetype=perl textwidth=72 :
