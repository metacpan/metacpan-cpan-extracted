package main;

use 5.006002;

use strict;
use warnings;

use Test::More 0.88;

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
	use lib qw{ inc };
	require My::Module::Test;
	My::Module::Test->import( qw{ format_pass magnitude } );
	1;
    } or do {
	plan skip_all => 'Can not load My::Module::Test from inc';
	exit;
    };
}

use Astro::Coord::ECI;
use Astro::Coord::ECI::Moon;
use Astro::Coord::ECI::Star;
use Astro::Coord::ECI::Sun;
use Astro::Coord::ECI::TLE qw{ :constants };
use Astro::Coord::ECI::TLE::Set;
use Astro::Coord::ECI::Utils qw{ deg2rad PARSEC SECSPERDAY };

my $sta = Astro::Coord::ECI->new(
    name => 'Greenwich Observatory',
)->geodetic(
    deg2rad( 51.4772 ),
    0,
    2 / 1000,
);

use constant SPY2DPS => 3600 * 365.24219 * SECSPERDAY;

my $star = do {
    my $ra = deg2rad( 146.4625 );
    Astro::Coord::ECI::Star->new(
	name	=> 'Epsilon Leonis',
    )->position(
	$ra,
	deg2rad( 23.774 ),
	76.86 * PARSEC,
	deg2rad( -0.0461 * 24 / 360 / cos( $ra ) / SPY2DPS ),
	deg2rad( -0.00957 / SPY2DPS ),
	4.3,
    );
};

# The following TLE is from
#
# SPACETRACK REPORT NO. 3
#
# Models for Propagation of
# NORAD Element Sets
#
# Felix R. Hoots
# Ronald L. Roerich
#
# December 1980
#
# Package Compiled by
# TS Kelso
#
# 31 December 1988
#
# obtained from http://celestrak.org/

# There is no need to call Astro::Coord::ECI::TLE::Set->aggregate()
# because we know we have exactly one data set.

my ( $tle ) = Astro::Coord::ECI::TLE->parse( <<'EOD' );
1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
EOD
$tle->set(
    geometric	=> 1,
    intrinsic_magnitude	=> 3.0,
);

my @pass;

if (
    eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( 0, 0, 0, 12, 9, 80 ),
	    timegm( 0, 0, 0, 19, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 6, 'Found 6 passes over Greenwich'
	or diag "Found @{[ scalar @pass ]} passes over Greenwich";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   rise
1980/10/13 05:42:42  55.8 119.1   255.7 lit   apls
                     49.6 118.3     6.2 Epsilon Leonis
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   set
EOD

note <<'EOD';
The following magnitude test is really only a regression test, since I
have no idea what the correct magnitude is.
EOD

magnitude( $tle, $sta, $pass[0]{events}[2]{time},
    0.6, 'Magnitude at max of pass 1' );

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
1980/10/14 05:32:49   0.0 204.8  1691.2 lit   rise
1980/10/14 05:36:32  85.6 111.4   215.0 lit   max
1980/10/14 05:40:27   0.0  27.3  1782.5 lit   set
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
1980/10/15 05:26:29   0.0 210.3  1693.5 shdw  rise
1980/10/15 05:27:33   4.7 212.0  1220.0 lit   lit
1980/10/15 05:30:12  63.7 297.6   239.9 lit   max
1980/10/15 05:34:08   0.0  25.1  1789.5 lit   set
EOD

is format_pass( $pass[3] ), <<'EOD', 'Pass 4';
1980/10/16 05:20:01   0.0 215.7  1701.3 shdw  rise
1980/10/16 05:22:20  14.8 228.1   701.8 lit   lit
1980/10/16 05:23:44  43.5 299.4   310.4 lit   max
1980/10/16 05:27:40   0.0  23.0  1798.7 lit   set
EOD

is format_pass( $pass[4] ), <<'EOD', 'Pass 5';
1980/10/17 05:13:26   0.0 221.0  1706.4 shdw  rise
1980/10/17 05:16:45  28.6 273.8   433.1 lit   lit
1980/10/17 05:17:08  31.7 301.4   400.0 lit   max
1980/10/17 05:21:03   0.0  21.0  1809.7 lit   set
EOD

is format_pass( $pass[5] ), <<'EOD', 'Pass 6';
1980/10/18 05:06:44   0.0 226.2  1708.2 shdw  rise
1980/10/18 05:10:23  24.5 302.6   495.7 shdw  max
1980/10/18 05:10:50  22.3 327.2   537.6 lit   lit
1980/10/18 05:14:16   0.0  19.0  1814.7 lit   set
EOD

@pass = ();
$tle->set( pass_threshold => deg2rad( 45 ) );

if (
    eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( 0, 0, 0, 12, 9, 80 ),
	    timegm( 0, 0, 0, 19, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 3, 'Found 3 passes over Greenwich over 45 degrees elevation'
	or diag "Found @{[ scalar @pass
	    ]} passes over Greenwich over 45 degrees elevation";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   rise
1980/10/13 05:42:42  55.8 119.1   255.7 lit   apls
                     49.6 118.3     6.2 Epsilon Leonis
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   set
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
1980/10/14 05:32:49   0.0 204.8  1691.2 lit   rise
1980/10/14 05:36:32  85.6 111.4   215.0 lit   max
1980/10/14 05:40:27   0.0  27.3  1782.5 lit   set
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
1980/10/15 05:26:29   0.0 210.3  1693.5 shdw  rise
1980/10/15 05:27:33   4.7 212.0  1220.0 lit   lit
1980/10/15 05:30:12  63.7 297.6   239.9 lit   max
1980/10/15 05:34:08   0.0  25.1  1789.5 lit   set
EOD

$tle->set( pass_threshold => undef );

@pass = ();
$tle->set( pass_variant => PASS_VARIANT_VISIBLE_EVENTS );

if (
    eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( 0, 0, 0, 12, 9, 80 ),
	    timegm( 0, 0, 0, 19, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 6, 'Found 6 passes over Greenwich'
	or diag "Found @{[ scalar @pass ]} passes over Greenwich";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   rise
1980/10/13 05:42:42  55.8 119.1   255.7 lit   apls
                     49.6 118.3     6.2 Epsilon Leonis
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   set
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
1980/10/14 05:32:49   0.0 204.8  1691.2 lit   rise
1980/10/14 05:36:32  85.6 111.4   215.0 lit   max
1980/10/14 05:40:27   0.0  27.3  1782.5 lit   set
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
1980/10/15 05:27:33   4.7 212.0  1220.0 lit   lit
1980/10/15 05:30:12  63.7 297.6   239.9 lit   max
1980/10/15 05:34:08   0.0  25.1  1789.5 lit   set
EOD

is format_pass( $pass[3] ), <<'EOD', 'Pass 4';
1980/10/16 05:22:20  14.8 228.1   701.8 lit   lit
1980/10/16 05:23:44  43.5 299.4   310.4 lit   max
1980/10/16 05:27:40   0.0  23.0  1798.7 lit   set
EOD

is format_pass( $pass[4] ), <<'EOD', 'Pass 5';
1980/10/17 05:16:45  28.6 273.8   433.1 lit   lit
1980/10/17 05:17:08  31.7 301.4   400.0 lit   max
1980/10/17 05:21:03   0.0  21.0  1809.7 lit   set
EOD

is format_pass( $pass[5] ), <<'EOD', 'Pass 6';
1980/10/18 05:10:50  22.3 327.2   537.6 lit   lit
1980/10/18 05:14:16   0.0  19.0  1814.7 lit   set
EOD

@pass = ();
$tle->set( pass_variant => PASS_VARIANT_VISIBLE_EVENTS |
    PASS_VARIANT_FAKE_MAX );
if (
    eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( 0, 0, 0, 12, 9, 80 ),
	    timegm( 0, 0, 0, 19, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 6, 'Found 6 passes over Greenwich'
	or diag "Found @{[ scalar @pass ]} passes over Greenwich";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   rise
1980/10/13 05:42:42  55.8 119.1   255.7 lit   apls
                     49.6 118.3     6.2 Epsilon Leonis
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   set
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
1980/10/14 05:32:49   0.0 204.8  1691.2 lit   rise
1980/10/14 05:36:32  85.6 111.4   215.0 lit   max
1980/10/14 05:40:27   0.0  27.3  1782.5 lit   set
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
1980/10/15 05:27:33   4.7 212.0  1220.0 lit   lit
1980/10/15 05:30:12  63.7 297.6   239.9 lit   max
1980/10/15 05:34:08   0.0  25.1  1789.5 lit   set
EOD

is format_pass( $pass[3] ), <<'EOD', 'Pass 4';
1980/10/16 05:22:20  14.8 228.1   701.8 lit   lit
1980/10/16 05:23:44  43.5 299.4   310.4 lit   max
1980/10/16 05:27:40   0.0  23.0  1798.7 lit   set
EOD

is format_pass( $pass[4] ), <<'EOD', 'Pass 5';
1980/10/17 05:16:45  28.6 273.8   433.1 lit   lit
1980/10/17 05:17:08  31.7 301.4   400.0 lit   max
1980/10/17 05:21:03   0.0  21.0  1809.7 lit   set
EOD

is format_pass( $pass[5] ), <<'EOD', 'Pass 6';
1980/10/18 05:10:50  22.3 327.2   537.6 lit   lit
1980/10/18 05:10:50  22.3 327.2   537.6 lit   max
1980/10/18 05:14:16   0.0  19.0  1814.7 lit   set
EOD

note 'Passes over location in station attribute';

@pass = ();
$tle->set( pass_variant => PASS_VARIANT_VISIBLE_EVENTS |
    PASS_VARIANT_FAKE_MAX | PASS_VARIANT_START_END,
    station => $sta,
);
$star->set( station => $sta );
if (
    eval {
	@pass = $tle->pass(
	    timegm( 0, 0, 0, 12, 9, 80 ),
	    timegm( 0, 0, 0, 16, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 3, 'Found 3 passes over Greenwich'
	or diag "Found @{[ scalar @pass ]} passes over Greenwich";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   start
1980/10/13 05:42:42  55.8 119.1   255.7 lit   apls
                     49.6 118.3     6.2 Epsilon Leonis
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   end
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
1980/10/14 05:32:49   0.0 204.8  1691.2 lit   start
1980/10/14 05:36:32  85.6 111.4   215.0 lit   max
1980/10/14 05:40:27   0.0  27.3  1782.5 lit   end
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
1980/10/15 05:27:33   4.7 212.0  1220.0 lit   start
1980/10/15 05:30:12  63.7 297.6   239.9 lit   max
1980/10/15 05:34:08   0.0  25.1  1789.5 lit   end
EOD

{
    my $sun = Astro::Coord::ECI::Sun->new( station => $sta );
    $tle->set( appulse => deg2rad( 90 ) );
    if (
	eval {
	    @pass = $tle->pass(
		timegm( 0, 0, 0, 13, 9, 80 ),
		timegm( 0, 0, 0, 14, 9, 80 ),
		[ $sun ],
	    );
	    1;
	}
    ) {
	ok @pass == 1, 'Found 1 passes over Greenwich'
	    or diag "Found @{[ scalar @pass ]} passes over Greenwich";
    } else {
	fail "Error in pass() method: $@";
    }

    is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   start
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:43:11  39.1  58.2   332.3 lit   apls
                     -6.6  94.3    56.6 Sun
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   end
EOD

    my $moon = Astro::Coord::ECI::Moon->new( station => $sta );
    if (
	eval {
	    @pass = $tle->pass(
		timegm( 0, 0, 0, 13, 9, 80 ),
		timegm( 0, 0, 0, 14, 9, 80 ),
		[ $moon ],
	    );
	    1;
	}
    ) {
	ok @pass == 1, 'Found 1 passes over Greenwich'
	    or diag "Found @{[ scalar @pass ]} passes over Greenwich";
    } else {
	fail "Error in pass() method: $@";
    }

    is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   start
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   end
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   apls
                    -41.0  61.9    49.8 Moon
EOD

    $tle->set( pass_variant => PASS_VARIANT_TRUNCATE );
    @pass = ();
    if (
	eval {
	    @pass = $tle->pass(
		timegm( 0, 0, 0, 13, 9, 80 ),
		timegm( 0, 0, 0, 14, 9, 80 ),
	    );
	    1;
	}
    ) {
	ok @pass == 1, 'Found 1 passes over Greenwich'
	    or diag "Found @{[ scalar @pass ]} passes over Greenwich";
    } else {
	fail "Error in pass() method: $@";
    }

    is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   rise
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   set
EOD

    @pass = ();
    if (
	eval {
	    @pass = $tle->pass(
		timegm( 0, 40, 5, 13, 9, 80 ),
		timegm( 0, 45, 5, 13, 9, 80 ),
	    );
	    1;
	}
    ) {
	ok @pass == 1, 'Found 1 passes over Greenwich'
	    or diag "Found @{[ scalar @pass ]} passes over Greenwich";
    } else {
	fail "Error in pass() method: $@";
    }

    is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:40:01   4.2 197.4  1251.1 lit   start
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:45:00   7.4  32.6  1063.4 lit   end
EOD

    $tle->set( pass_variant => PASS_VARIANT_NONE );

    my ( $tle2 ) = Astro::Coord::ECI::TLE->parse(
	{ station => $sta },  <<'EOD' );
11801
1 11801U          80230.29629788  .01431103  00000-0  14311-1
2 11801  46.7916 230.4354 7318036  47.4722  10.4117  2.28537848
EOD

    if (
	eval {
	    @pass = $tle->pass(
		timegm( 0, 0, 0, 13, 9, 80 ),
		timegm( 0, 0, 0, 14, 9, 80 ),
		[ $tle2 ],
	    );
	    1;
	}
    ) {
	ok @pass == 1, 'Found 1 passes over Greenwich'
	    or diag "Found @{[ scalar @pass ]} passes over Greenwich";
    } else {
	fail "Error in pass() method: $@";
    }

    is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   rise
1980/10/13 05:39:02   0.0 199.0  1687.4 lit   apls
                    -17.8 203.7    17.8 11801
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   set
EOD

}

note 'Passes over explicit location';

@pass = ();
$tle->set( pass_variant => PASS_VARIANT_VISIBLE_EVENTS |
	PASS_VARIANT_FAKE_MAX | PASS_VARIANT_START_END,
    appulse	=> deg2rad( 10 ),
);
if (
    eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( 0, 0, 0, 12, 9, 80 ),
	    timegm( 0, 0, 0, 16, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 3, 'Found 6 passes over Greenwich'
	or diag "Found @{[ scalar @pass ]} passes over Greenwich";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1';
1980/10/13 05:39:02   0.0 199.0  1687.8 lit   start
1980/10/13 05:42:42  55.8 119.1   255.7 lit   apls
                     49.6 118.3     6.2 Epsilon Leonis
1980/10/13 05:42:43  55.9 115.6   255.5 lit   max
1980/10/13 05:46:37   0.0  29.7  1778.5 lit   end
EOD

is format_pass( $pass[1] ), <<'EOD', 'Pass 2';
1980/10/14 05:32:49   0.0 204.8  1691.2 lit   start
1980/10/14 05:36:32  85.6 111.4   215.0 lit   max
1980/10/14 05:40:27   0.0  27.3  1782.5 lit   end
EOD

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
1980/10/15 05:27:33   4.7 212.0  1220.0 lit   start
1980/10/15 05:30:12  63.7 297.6   239.9 lit   max
1980/10/15 05:34:08   0.0  25.1  1789.5 lit   end
EOD

@pass = ();
$tle->set(
    interval => 30,
    pass_variant => PASS_VARIANT_NONE,
);

if (
    eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( 0, 0, 3, 14, 9, 80 ),
	    timegm( 0, 0, 9, 14, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 1, 'Found 1 pass over Greenwich, with interval'
	or diag "Found @{[ scalar @pass ]} passes over Greenwich";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1, with interval';
1980/10/14 05:32:49   0.0 204.8  1691.2 lit   rise
1980/10/14 05:33:19   1.9 204.8  1468.1 lit
1980/10/14 05:33:49   4.3 204.7  1245.5 lit
1980/10/14 05:34:19   7.4 204.6  1023.7 lit
1980/10/14 05:34:49  11.7 204.5   804.1 lit
1980/10/14 05:35:19  18.6 204.1   589.1 lit
1980/10/14 05:35:49  31.9 203.0   387.2 lit
1980/10/14 05:36:19  64.9 196.4   235.3 lit
1980/10/14 05:36:32  85.6 111.4   215.0 lit   max
1980/10/14 05:36:49  58.2  33.2   251.8 lit
1980/10/14 05:37:19  29.8  28.7   417.1 lit
1980/10/14 05:37:49  18.0  27.8   621.9 lit
1980/10/14 05:38:19  11.7  27.5   837.6 lit
1980/10/14 05:38:49   7.6  27.3  1057.3 lit
1980/10/14 05:39:19   4.6  27.3  1278.8 lit
1980/10/14 05:39:49   2.3  27.3  1500.9 lit
1980/10/14 05:40:19   0.4  27.3  1723.2 lit
1980/10/14 05:40:27   0.0  27.3  1782.5 lit   set
EOD

@pass = ();
$tle->set( lazy_pass_position => 1 );

if (
    eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( 0, 0, 3, 14, 9, 80 ),
	    timegm( 0, 0, 9, 14, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 1, 'Found 1 pass over Greenwich, with interval'
	or diag "Found @{[ scalar @pass ]} passes over Greenwich";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[0] ), <<'EOD', 'Pass 1, with interval';
1980/10/14 05:32:49   0.0 204.8  1691.2 lit   rise
1980/10/14 05:33:19                     lit
1980/10/14 05:33:49                     lit
1980/10/14 05:34:19                     lit
1980/10/14 05:34:49                     lit
1980/10/14 05:35:19                     lit
1980/10/14 05:35:49                     lit
1980/10/14 05:36:19                     lit
1980/10/14 05:36:32  85.6 111.4   215.0 lit   max
1980/10/14 05:36:49                     lit
1980/10/14 05:37:19                     lit
1980/10/14 05:37:49                     lit
1980/10/14 05:38:19                     lit
1980/10/14 05:38:49                     lit
1980/10/14 05:39:19                     lit
1980/10/14 05:39:49                     lit
1980/10/14 05:40:19                     lit
1980/10/14 05:40:27   0.0  27.3  1782.5 lit   set
EOD

@pass = ();
$tle->set(
    interval		=> 0,
    lazy_pass_position	=> 0,
    pass_variant	=> PASS_VARIANT_NO_ILLUMINATION,
    visible		=> 0,
);
if (
    eval {
	@pass = $tle->pass(
	    $sta,
	    timegm( 0, 0, 0, 12, 9, 80 ),
	    timegm( 0, 0, 0, 19, 9, 80 ),
	    [ $star ],
	);
	1;
    }
) {
    ok @pass == 13, 'Found 13 passes over Greenwich'
	or diag "Found @{[ scalar @pass ]} passes over Greenwich";
} else {
    fail "Error in pass() method: $@";
}

is format_pass( $pass[2] ), <<'EOD', 'Pass 3';
1980/10/13 05:39:02   0.0 199.0  1687.8       rise
1980/10/13 05:42:42  55.8 119.1   255.7       apls
                     49.6 118.3     6.2 Epsilon Leonis
1980/10/13 05:42:43  55.9 115.6   255.5       max
1980/10/13 05:46:37   0.0  29.7  1778.5       set
EOD

is format_pass( $pass[6] ), <<'EOD', 'Pass 7';
1980/10/15 05:26:29   0.0 210.3  1693.5       rise
1980/10/15 05:30:12  63.7 297.6   239.9       max
1980/10/15 05:34:08   0.0  25.1  1789.5       set
EOD

done_testing;

1;

# ex: set filetype=perl textwidth=72 :
