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
}

use Astro::Coord::ECI;
use Astro::Coord::ECI::TLE qw{ :constants };
use Astro::Coord::ECI::TLE::Iridium;
use Astro::Coord::ECI::Utils qw{ deg2rad PARSEC rad2deg SECSPERDAY };

use lib qw{ inc };

use My::Module::Test qw{ magnitude };

my $sta = Astro::Coord::ECI->new(
    name => 'Greenwich Observatory',
)->geodetic(
    deg2rad( 51.4772 ),
    0,
    2 / 1000,
);

Astro::Coord::ECI::TLE->status( add => 88888, iridium => '+',
    'Fake Iridium' );

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
# obtained from http://celestrak.com/

# There is no need to call Astro::Coord::ECI::TLE::Set->aggregate()
# because we know we have exactly one data set.

my ( $tle ) = Astro::Coord::ECI::TLE->parse( <<'EOD' );
1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
EOD

$tle->set( zone => 0 );

ok $tle->can_flare(), 'Body 88888 can flare (not really, but ...)';

my @flare;

note 'Flares over explicit location';

if (
    eval {
	@flare = $tle->flare(
	    $sta,
	    timegm( 0, 0, 0, 13, 9, 80 ),
	    timegm( 0, 0, 0, 14, 9, 80 ),
	);
	1;
    }
) {
    ok @flare == 2, 'Found 2 flares as seen from Greenwich'
	or diag "Found @{[ scalar @flare ]} flares from Greenwich";
} else {
    fail "Error in flare() method: $@";
}

is format_flare( $flare[0] ), <<'EOD', 'Flare 1';
1980/10/13 05:43:26  29.9  48.1   412.9 -0.4 1 am
EOD

magnitude $tle, $sta, $flare[0]{time},
    -0.4, 'Compute magnitude at time of flare 1';

is format_flare( $flare[1] ), <<'EOD', 'Flare 2';
1980/10/13 14:58:33  42.8 204.9   393.0 -3.0 1 day
EOD

magnitude $tle, $sta, $flare[1]{time},
    -3.0, 'Compute magnitude at time of flare 2';

note 'Flares over location specified by station attribute';

if (
    eval {
	$tle->set( station => $sta );
	@flare = $tle->flare(
	    timegm( 0, 0, 0, 13, 9, 80 ),
	    timegm( 0, 0, 0, 14, 9, 80 ),
	);
	1;
    }
) {
    ok @flare == 2, 'Found 2 flares as seen from Greenwich'
	or diag "Found @{[ scalar @flare ]} flares from Greenwich";
} else {
    fail "Error in flare() method: $@";
}

is format_flare( $flare[0] ), <<'EOD', 'Flare 1';
1980/10/13 05:43:26  29.9  48.1   412.9 -0.4 1 am
EOD

magnitude $tle, $flare[0]{time},
    -0.4, 'Compute magnitude at time of flare 1';

is format_flare( $flare[1] ), <<'EOD', 'Flare 2';
1980/10/13 14:58:33  42.8 204.9   393.0 -3.0 1 day
EOD

magnitude $tle, $flare[1]{time},
    -3.0, 'Compute magnitude at time of flare 2';

done_testing;

########################################################################

sub format_flare {
    my ( $flare ) = @_;
    $flare or return '';
    my $rslt = sprintf '%19s %5.1f %5.1f %7.1f %4.1f %1d %-3s',
	format_time( $flare->{time} ),
	rad2deg( $flare->{elevation} ),
	rad2deg( $flare->{azimuth} ),
	$flare->{range},
	$flare->{magnitude},
	$flare->{mma},
	$flare->{type},
	;
    $rslt =~ s/ \s+ \z //smx;
    $rslt .= "\n";
    return $rslt;
}

sub format_time {
    my ( $time ) = @_;
    my @parts = gmtime int( $time + 0.5 );
    return sprintf '%04d/%02d/%02d %02d:%02d:%02d', $parts[5] + 1900,
	$parts[4] + 1, @parts[ 3, 2, 1, 0 ];
}

1;

# ex: set textwidth=72 :
