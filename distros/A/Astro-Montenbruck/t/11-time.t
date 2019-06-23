#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More tests => 9;
use Test::Number::Delta within => 1e-6;

BEGIN {
	use_ok( 'Astro::Montenbruck::Time', qw/:all/ );
}

our @MONTH_NAMES = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

sub format_date {
	sprintf('%04d-%02d-%05.2f', @_)
}

subtest "Start of Gregorian calendar" => sub {
    plan tests => 3;
    ok(
        after_gregorian(1965, 2, 1),
        'Afret Gregorian reform'
    ) or diag('1965-02-01 should be after Gregorian calendar reform');
    ok(
        !after_gregorian(1582, 10, 3),
        'Before Gregorian reform'
    ) or diag('1582-10-03 should be before Gregorian calendar reform');
    ok(
        # in Soviet Russia Gregorian calendar was accepted on Jan 26, 1918
        !after_gregorian(1917, 11, 7, gregorian_start => 19180126),
        'Custom Gregorian start'
    ) or diag('1917-11-07 should be before given Gregorian calendar reform');
};

subtest "Conversions" => sub {
	my @cases = (
        #{ date => [ 1900, 1, 0.5 ],   jd => 2415020 },
    	{ date => [ 1984, 8, 29 ],    jd => 2445941.5 },
    	{ date => [ 1899, 12, 31.5 ], jd => 2415020 },
    	{ date => [ 1938, 8, 17 ],    jd => 2429127.5 },
    	{ date => [ 1, 1, 1 ],        jd => 1721423.5 },
        { date => [-4712, 7, 12 ],    jd => 192.5 },
    	{ date => [-4712, 1,  1.5],   jd => 0 },
	);

	plan tests => 2;

	subtest "Calendar -> JD" => sub {
		plan tests => scalar @cases;
		for ( @cases ) {
			my $got = cal2jd( @{$_->{date}} );
            delta_ok($_->{jd}, $_->{jd}, format_date( @{$_->{date}} ))
                or diag("Expected: $_->{jd}, got: $got");
		}
	};

	subtest "JD -> calendar" => sub {
		plan tests => scalar @cases;
		for (@cases) {
            my @cal = jd2cal( $_->{jd} );
            my $got = format_date(@cal);
            my $exp = format_date( @{ $_->{date} } );
            cmp_ok($got, 'eq', $exp, "JD $_->{jd}")
                or diag("Expected: $exp, got: $got");
		}
	}
};

subtest "Old-style dates" => sub {
    plan tests => 3;
    my $jj = cal2jd(1870, 4, 10, gregorian_start => undef);
    my $jg = cal2jd(1870, 4, 22);
    cmp_ok($jj, '==', $jg, "Input old-style date")
        or diag("Results should be equal, got: $jj and $jg");

    {
        my ($y, $m, $d) = jd2cal($jj, gregorian => 1);
        cmp_ok($d, '==', 22, "Output new-style date")
            or diag("Old-style day should be 22, got $d instead");
    }
    {
        my ($y, $m, $d) = jd2cal($jj, gregorian => 0);
        cmp_ok($d, '==', 10, "Output old-style date")
            or diag("Old-style day should be 10, got $d instead");
    }
};

subtest "JD at midnight" => sub {
    plan tests => 4;
    cmp_ok( 2438791.5, '==', jd0(2438792.0), "At previous noon");
    cmp_ok( 2438792.5, '==', jd0(2438792.9), "Close to current noon");
    cmp_ok( 2438792.5, '==', jd0(2438793.0), "At noon");
    cmp_ok( 2438793.5, '==', jd0(2438793.5), "At midnight");
};

subtest "T" => sub {
	plan tests => 2;
    {
        my $exp = -0.070321697467488022970095;
        my $jd = 2448976.5;
        my $got = jd_cent($jd);
        delta_ok($exp, $got, "JD $jd -> T, epoch 2000")
            or diag("Expected: T $exp. got: $got");
    }
    {
        my $exp = 0.650869;
        my $jd = 2438792.99027778;
        my $got = t1900($jd);
        delta_ok($exp, $got, "JD $jd -> T, epoch 1900")
            or diag("Expected: T $exp. got: $got");
    }
};

subtest "JD <-> Unix time" => sub {
    plan tests => 2;
    my @cases = (
        [-155088000, 2438792.5],
        [0, $JD_UNIX_EPOCH],
        [1555821066, 2458594.68826389]
    );

    subtest "JD -> Unix time" => sub {
        plan tests => scalar @cases;
        for(@cases) {
            my $got = jd2unix($_->[1]);
            delta_ok($_->[0], $got, "JD $_->[1]")
                or diag("Expected: $_->[0], got: $got");
        }
    };
    subtest "Unix time -> JD" => sub {
        plan tests => scalar @cases;
        for(@cases) {
            my $got = unix2jd($_->[0]);
            delta_ok($_->[1], $got, "Unix $_->[0]")
                or diag("Expected: $_->[1], got: $got");
        }
    };
};

subtest "JD <-> MJD" => sub {
    plan tests => 2;
    my @cases = (
        [-12752.5, 2438792.5],
        [0, $J2000],
        [7049.68826388987, 2458594.68826389]
    );
    subtest "JD -> MJD" => sub {
        plan tests => scalar @cases;
        for(@cases) {
            my $got = jd2mjd($_->[1]);
            delta_ok($_->[0], $got, "JD $_->[1]")
                or diag("Expected: $_->[0], got: $got");
        }
    };
    subtest "MJD -> JD" => sub {
        plan tests => scalar @cases;
        for(@cases) {
            my $got = mjd2jd($_->[0]);
            delta_ok($_->[1], $got, "MJD $_->[0]")
                or diag("Expected: $_->[1], got: $got");
        }
    }
};

subtest 'Sidereal Time' => sub {
    my @cases = ({
        jd  => 2445943.851053,
        lst => 7.072111,
    }, # 1984-08-31.4
    {
        jd  => 2415703.498611,
        lst => 3.525306,
    }, # 1901-11-15.0
    {
        jd  => 2415702.501389,
        lst => 3.526444,
    }, # 1901-11-14.0
    {
        jd  => 2444352.108931,
        lst => 4.668119,
    }); # 1980-04-22.6
    plan tests => scalar @cases;
    for(@cases) {
        my $got = jd2lst( $_->{jd} );
        delta_within($_->{lst}, $got, 1e-4, "JD $_->{jd}")
            or diag("Expected: $_->{lst}, got: $got");
    }
};
