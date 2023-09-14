package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;

use lib qw{ inc };
use My::Module::Test::App;	# For environment clean-up.
use My::Module::Test::Mock_App;

use Astro::App::Satpass2::Format::Template;

use Astro::Coord::ECI 0.077;
use Astro::Coord::ECI::Moon 0.077;
use Astro::Coord::ECI::Sun 0.077;
use Astro::Coord::ECI::TLE 0.077 qw{ :constants };
use Astro::Coord::ECI::Utils 0.112 qw{ deg2rad greg_time_gm };

{
    local $@ = undef;

    use constant HAVE_TLE_IRIDIUM	=> eval {
	require Astro::Coord::ECI::TLE::Iridium;
	Astro::Coord::ECI::TLE::Iridium->VERSION( 0.077 );
	1;
    } || 0;
}

use Cwd ();
use Time::Local;

use constant APRIL_FOOL_2023	=> greg_time_gm( 0, 0, 0, 1, 3, 2023 );
use constant FORMAT_VALUE	=> 'Astro::App::Satpass2::FormatValue';

my $app = My::Module::Test::Mock_App->new();

my $sta = Astro::Coord::ECI->new()->geodetic(
    deg2rad( 38.898748 ),
    deg2rad( -77.037684 ),
    16.68 / 1000,
)->set( name => '1600 Pennsylvania Ave NW Washington DC 20502' );
my $sun = Astro::Coord::ECI::Sun->new();
my $moon = Astro::Coord::ECI::Moon->new();
# The following TLE is from
# SPACETRACK REPORT NO. 3
# Models for Propagation of NORAD Element Sets
# Felix R. Hoots and Ronald L. Roehrich
# December 1980
# Compiled by TS Kelso
# 31 December 1988
# Obtained from celestrak.com
# NASA line added by T. R. Wyant
my ( $sat ) = Astro::Coord::ECI::TLE->parse( <<'EOD' );
None
1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
EOD

HAVE_TLE_IRIDIUM and $sat->rebless( 'iridium' );

my $ft = Astro::App::Satpass2::Format::Template->new(
    parent	=> $app,
)->gmt( 1 );

# Encapsulation violation. The _uniq() subroutine may be moved or
# retracted without notice of any kind.

is_deeply
    [ Astro::App::Satpass2::Format::Template::_uniq(
	    qw{ Able was I ere I saw Elba } ) ],
    [ qw{ Able was I ere saw Elba } ],
    'Check our implementation of uniq()';

ok $ft, 'Instantiate Astro::App::Satpass2::Format::Template';

sub april_fool {
    my ( undef, $hash ) = @_;
    $hash ||= {};
    $hash->{time} = APRIL_FOOL_2023;
    return $hash;
}

ok $ft->template( fubar => <<'EOD' ), 'Can set custom template';
Able was [% arg.0 %] ere [% arg.0 %] saw Elba
EOD

is $ft->template( 'fubar' ), <<'EOD', 'Can get same template back';
Able was [% arg.0 %] ere [% arg.0 %] saw Elba
EOD

is $ft->format(
    template	=> 'fubar',
    arg		=> [ 'I' ],
), <<'EOD', 'Can use custom template';
Able was I ere I saw Elba
EOD

is $ft->format(
    template	=> 'almanac',
    data	=> [ {
		almanac	=> {
		    description	=> 'Moon rise',
		    detail		=> 1,
		    event		=> 'horizon',
		},
		body	=> $moon,
		station	=> $sta,
		time	=> greg_time_gm( 8, 38, 9, 1, 3, 2011 ),
	    },
	    {
		almanac	=> {
		    description	=> 'Moon transits meridian',
		    detail		=> 1,
		    event		=> 'transit',
		},
		body	=> $moon,
		station	=> $sta,
		time	=> greg_time_gm( 20, 46, 15, 1, 3, 2011 ),
	    },
	    {
		almanac	=> {
		    description	=> 'Moon set',
		    detail		=> 0,
		    event		=> 'horizon',
		},
		body	=> $moon,
		station	=> $sta,
		time	=> greg_time_gm( 40, 2, 22, 1, 3, 2011 ),
	    },
	] ), <<'EOD', 'Almanac';
2011-04-01 09:38:08 Moon rise
2011-04-01 15:46:20 Moon transits meridian
2011-04-01 22:02:40 Moon set
EOD

SKIP: {
    HAVE_TLE_IRIDIUM
	or skip 'Astro::Coord::ECI::TLE::Iridium not installed', 1;

    is $ft->format(
	template	=> 'flare',
	data	=> [
		{
		    angle => 0.262059013150469,
		    appulse => {
			angle => 1.02611236331053,
			body => $sun,
		    },
		    area => 5.01492326975883e-12,
		    azimuth => 2.2879991425019,
		    body => $sat,
		    center => {
			body => Astro::Coord::ECI->new()->eci(
			    -239.816850881829,
			    4844.88846601786,
			    4147.86073518313,
			),
			magnitude => -9.19948076848716,
		    },
		    elevation => 0.494460647040746,
		    magnitude => 3.92771062285379,
		    mma => 0,
		    range => 410.943432358706,
		    specular => 0,
		    station => $sta,
		    status => '',
		    time => greg_time_gm( 44, 7, 10, 13, 9, 1980 ) + .606786,
		    type => 'am',
		    virtual_image => Astro::Coord::ECI->new()->eci(
			-126704974.030369,
			66341250.3306362,
			-42588590.3666171,
		    ),
		},
	    ] ), <<'EOD', 'Flare';
                                                     Degre
                                                      From   Center Center
Time     Name         Eleva  Azimuth      Range Magn   Sun  Azimuth  Range
1980-10-13
10:07:45 None          28.3 131.1 SE      410.9  3.9 night 300.8 NW  412.5
EOD
}

is $ft->format(
    template	=> 'list',
    data	=> [ $sat ]
), <<'EOD', 'List';
   OID Name                     Epoch               Period
 88888 None                     1980-10-01 23:41:24 01:29:37
EOD

{
    $ft->template( list => <<'EOD' );
[%- title.oid( align_left = 0 ) %] [% title.name %]
[% FOR item IN data %]
    [%- item.oid %] [% item.name %]
[% END -%]
EOD

    is $ft->format(
	template	=> 'list',
	data		=> [ $sat ],
    ), <<'EOD', 'List (custom format)';
   OID Name
 88888 None
EOD

    is $ft->format(
	template	=> 't/list.tt',
	data		=> [ $sat ],
    ), <<'EOD', 'List (format from relative path)';
                    Name OID
                    None  88888
EOD

    my $abs = Cwd::abs_path( 't/list.tt' );

    my $rslt;
    eval {
	$ft->format(
	    template	=> $abs,
	    data	=> [ $sat ],
	);
	1;
    } or do {
	$rslt = $@;
    };
    like $rslt, qr{absolute paths are not allowed}sm,
	    'List (format from absolute path) should fail by default'
	or diag defined $rslt ? "Failed but with error $rslt" :
    'Succeeded';

    $ft->permissive( 1 );

    is $ft->format(
	template	=> $abs,
	data		=> [ $sat ],
    ), <<'EOD', 'List (format from absolute path, permissive)';
                    Name OID
                    None  88888
EOD

}

is $ft->format(
    template	=> 'location',
    data	=> $sta
), <<'EOD', 'Location';
Location: 1600 Pennsylvania Ave NW Washington DC 20502
          Latitude 38.8987, longitude -77.0377, height 17 m
EOD

is $ft->format(
    template	=> 'pass',
    data	=> [
	    {
		body	=> $sat,
		events	=> [
		    {
			azimuth => 2.72679983099103,
			body => $sat,
			elevation => 0.350867451859261,
			event => PASS_EVENT_RISE,
			illumination => PASS_EVENT_LIT,
			range => 537.930341183133,
			station => $sta,
			time	=> greg_time_gm( 14, 7, 10, 13, 9, 1980 ),
		    },
		    {
			azimuth		=> 2.22028221624351,
			body		=> $sat,
			elevation	=> 0.507347011634507,
			event		=> PASS_EVENT_BRIGHTEST,
			illumination	=> PASS_EVENT_LIT,
			range		=> 402.657696214206,
			station		=> $sta,
			time		=> greg_time_gm( 48, 7, 10, 13, 9, 1980 ),
		    },
		    {
			azimuth => 1.95627424522813,
			body => $sat,
			elevation => 0.535869703007124,
			event => PASS_EVENT_MAX,
			illumination => PASS_EVENT_LIT,
			range => 385.864099675914,
			station => $sta,
			time => greg_time_gm( 0, 8, 10, 13, 9, 1980 ),
		    },
		    {
			azimuth => 0.988652345285029,
			body => $sat,
			elevation => 0.344817448574959,
			event => PASS_EVENT_SET,
			illumination => PASS_EVENT_LIT,
			range => 552.731309464471,
			station => $sta,
			time => greg_time_gm( 56, 8, 10, 13, 9, 1980 ),
		    },
		],
		time => greg_time_gm( 0, 8, 10, 13, 9, 1980 ),
	    },
	] ), <<'EOD', 'Pass';
Time     Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980-10-13     88888 - None
10:07:14  20.1 156.2 SE      537.9  34.8367  -74.8798   204.0 lit   rise
10:07:48  29.1 127.2 SE      402.7  36.9992  -73.9844   204.9 lit   brgt
10:08:00  30.7 112.1 E       385.9  37.7599  -73.6545   205.2 lit   max
10:08:56  19.8  56.6 NE      552.7  41.2902  -72.0053   207.0 lit   set
EOD

is $ft->format(
    template	=> 'pass_events',
    data	=> [
	    {
		body	=> $sat,
		events	=> [
		    {
			azimuth => 2.72679983099103,
			body => $sat,
			elevation => 0.350867451859261,
			event => PASS_EVENT_RISE,
			illumination => PASS_EVENT_LIT,
			range => 537.930341183133,
			station => $sta,
			time	=> greg_time_gm( 14, 7, 10, 13, 9, 1980 ),
		    },
		    {
			azimuth => 1.95627424522813,
			body => $sat,
			elevation => 0.535869703007124,
			event => PASS_EVENT_MAX,
			illumination => PASS_EVENT_LIT,
			range => 385.864099675914,
			station => $sta,
			time => greg_time_gm( 0, 8, 10, 13, 9, 1980 ),
		    },
		    {
			azimuth => 0.988652345285029,
			body => $sat,
			elevation => 0.344817448574959,
			event => PASS_EVENT_SET,
			illumination => PASS_EVENT_LIT,
			range => 552.731309464471,
			station => $sta,
			time => greg_time_gm( 56, 8, 10, 13, 9, 1980 ),
		    },
		],
		time => greg_time_gm( 0, 8, 10, 13, 9, 1980 ),
	    },
	] ), <<'EOD', 'Pass';
Date       Time     OID    Event Illum Eleva  Azimuth      Range
1980-10-13 10:07:14  88888 rise  lit    20.1 156.2 SE      537.9
1980-10-13 10:08:00  88888 max   lit    30.7 112.1 E       385.9
1980-10-13 10:08:56  88888 set   lit    19.8  56.6 NE      552.7
EOD

$moon->universal( greg_time_gm( 0, 0, 4, 1, 3, 2011 ) );
is $ft->format(
    template	=> 'phase',
    data	=> [ { body => $moon, time => $moon->universal() } ]
), <<'EOD', 'Phase';
      Date     Time     Name Phas Phase             Lit
2011-04-01 04:00:00     Moon  333 waning crescent     5%
EOD

my $iridium_stuff = HAVE_TLE_IRIDIUM ? <<'EOD' : '';

                                           MMA 0 mirror angle 15.0 magnitude 3.9
                                           MMA 1 Geometry does not allow reflection
                                           MMA 2 Geometry does not allow reflection
EOD
chomp $iridium_stuff;

is $ft->format(
    template	=> 'position',
    data	=> {
	    bodies	=> [ $sat, $moon ],
	    station	=> $sta,
	    time	=> greg_time_gm( 45, 7, 10, 13, 9, 1980 ),
	} ), <<"EOD", 'Position';
1980-10-13 10:07:45
            Name Eleva  Azimuth      Range               Epoch Illum
            None  28.4 130.7 SE      409.9 1980-10-01 23:41:24 lit$iridium_stuff
            Moon -55.8  59.2 NE   406685.1
EOD

$sat->rebless( 'tle' );	# No more Iridium stuff, since we know we can do it.

$ft->local_coord( 'azel' );
is $ft->format(
    template	=> 'position',
    data	=> {
	    bodies	=> [ $sat, $moon ],
	    station	=> $sta,
	    time	=> greg_time_gm( 45, 7, 10, 13, 9, 1980 ),
	} ), <<'EOD', 'Position, local_coord = azel';
1980-10-13 10:07:45
            Name Eleva  Azimuth               Epoch Illum
            None  28.4 130.7 SE 1980-10-01 23:41:24 lit
            Moon -55.8  59.2 NE
EOD

$ft->local_coord( 'az_rng' );
is $ft->format(
    template	=> 'position',
    data	=> {
	    bodies	=> [ $sat, $moon ],
	    station	=> $sta,
	    time	=> greg_time_gm( 45, 7, 10, 13, 9, 1980 ),
	} ), <<'EOD', 'Position, local_coord = az_rng';
1980-10-13 10:07:45
            Name  Azimuth      Range               Epoch Illum
            None 130.7 SE      409.9 1980-10-01 23:41:24 lit
            Moon  59.2 NE   406685.1
EOD

$ft->local_coord( 'equatorial' );
is $ft->format(
    template	=> 'position',
    data	=> {
	    bodies	=> [ $sat, $moon ],
	    station	=> $sta,
	    time	=> greg_time_gm( 45, 7, 10, 13, 9, 1980 ),
	} ), <<'EOD', 'Position, local_coord = equatorial';
1980-10-13 10:07:45
                    Right
            Name Ascensio Decli               Epoch Illum
            None 09:17:51  -8.5 1980-10-01 23:41:24 lit
            Moon 16:26:42 -17.2
EOD

$ft->local_coord( 'equatorial_rng' );
is $ft->format(
    template	=> 'position',
    data	=> {
	    bodies	=> [ $sat, $moon ],
	    station	=> $sta,
	    time	=> greg_time_gm( 45, 7, 10, 13, 9, 1980 ),
	} ), <<'EOD', 'Position, local_coord = equatorial_rng';
1980-10-13 10:07:45
                    Right
            Name Ascensio Decli      Range               Epoch Illum
            None 09:17:51  -8.5      409.9 1980-10-01 23:41:24 lit
            Moon 16:26:42 -17.2   406685.1
EOD

is $ft->format(
	arg	=> [ qw{ sailor } ],
	template => \"Hello, [% arg.0 %]!\n",
    ), <<'EOD', 'Report';
Hello, sailor!
EOD

# NOTE: At this point, the local coordinates are equatorial_rng. We do
# not use them for subsequent tests, but if we do will probably need to
# reset them.

is $ft->format(
    template	=> 'tle',
    data	=> [ $sat ],
), <<'EOD', 'Tle';
None
1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
EOD

is $ft->format(
    template	=> 'tle_verbose',
    data	=> [ $sat ],
), <<'EOD', 'Tle verbose';
OID: 88888
    Name: None
    International Launch Designator:
    Epoch: 1980-10-01 23:41:24 GMT
    Effective Date: <none> GMT
    Classification: U
    Mean Motion: 4.01456130 degrees/minute
    First Derivative: 1.26899306e-07 degrees/minute squared
    Second Derivative: 1.66908e-11 degrees/minute cubed
    B Star Drag: 6.68160e-05
    Ephemeris Type: 0
    Inclination: 72.8435 degrees
    Ascending Node: 07:43:53 in right ascension
    Eccentricity: 0.0086731
    Argument Of Perigee: 52.6988 degrees from ascending node
    Mean Anomaly: 110.5714 degrees
    Element Number: 8
    Revolutions At Epoch: 105
    Period: 01:29:37
    Semimajor Axis: 6634.0 kilometers
    Perigee: 198.3 kilometers
    Apogee: 313.4 kilometers
EOD

eval {
    my $magic_word = 'Plugh';
    $ft->add_formatter_method( {
	    default	=> {
		width	=> 6,
	    },
	    dimension	=> {
		dimension	=> 'string_pseudo_units',
	    },
	    fetch	=> sub {
##		my ( $self, $name, $arg ) = @_;
		my ( $self ) = @_;	# Arguments unused
		return qq["$self->{data}{magic_word}"];
	    },
	    name	=> 'magic_word',
	} );
    $ft->template( advent => q<A hollow voice says [% data.magic_word( width = '' ) %]> );
    is $ft->format(
	template	=> 'advent',
	data		=> {
	    magic_word	=> $magic_word,
	}
    ), qq{A hollow voice says "$magic_word"}, 'Add a formatter';
    1;
} or fail "Added formatter failed: $@";

SKIP: {

    load_or_skip( 'DateTime::Calendar::Christian', 1 );

    eval {
	require DateTime::TimeZone;
	my $tz = DateTime::TimeZone->new( name => 'local' );
	1;
    } or do {
	my $err = $@;
	defined $err
		or $err = 'Cannot determine local time zone';
	chomp $err;
	skip "$err under $^O", 1;
    };


    $ft->template( fubar => q<[% data.date( width = '' ) %]> );
    $ft->time_formatter(
	q<DateTime::Strftime,back_end=DateTime::Calendar::Christian> );
    $ft->date_format( '%{year_with_christian_era}-%m-%d %{calendar_name}' );

    my $dt = DateTime::Calendar::Christian->new(
	year		=> -43,
	month		=> 3,
	day		=> 15,
	time_zone	=> 'UTC',
    );

    is $ft->format(
	template	=> 'fubar',
	data		=> {
	    time	=> $dt->epoch(),
	},
    ), q{44BC-03-15 Julian}, 'Julian dates';

}

done_testing;

1;

# ex: set textwidth=72 :
