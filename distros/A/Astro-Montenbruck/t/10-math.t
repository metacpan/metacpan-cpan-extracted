#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.03;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More tests => 9;
use Test::Number::Delta within => 1e-6;

use Math::Trig qw/:pi deg2rad :radial/;

BEGIN {
	use_ok( 'Astro::Montenbruck::MathUtils', qw/:all/ );
}

subtest 'Sexadecimal conversions' => sub {
    plan tests => 3;
    my ( $d, $m, $s ) = ( 250, 46, 0.0 );
    my $ddd = 250.766666666667;

    my $got = ddd( $d, $m, $s );
    delta_ok($ddd, $got, "Sexadecimal --> decimal") or diag("Expected: $ddd, got: $got");

    subtest 'Decimal --> sexadecimal' => sub{
        plan tests => 3;
        my @got = dms( $ddd );
        cmp_ok($d, '==', $got[0], "Degrees") or diag("Expected: $d, got: $got[0]");
        cmp_ok($m, '==', $got[1], "Minutes") or diag("Expected: $m, got: $got[1]");
        cmp_ok($s, '==', int($got[2]), "Seconds") or diag("Expected: $s, got: $got[2]");
    };

    subtest 'Zodiac' => sub {
        plan tests => 12;
        for ( 0 .. 11 ) {
            my $x = 30 * $_ + 10;
            my ($z, $d) = zdms($x);
            cmp_ok( $z, '==', $_, sprintf( 'zdms(%d)', $x ) )
                or diag("Expected $z, got: $_");
        }
    };
};

subtest 'Frac' => sub {
    my @cases = (
        [ -23456789.9, -0.9 ],
        [ -10.7, -0.7 ],
        [ 0.0, 0.0 ],
        [ 10.7, 0.7 ],
        [ 23456789.9, 0.9 ]
    );
    plan tests => scalar @cases;

    for (@cases) {
        my ($arg, $exp) = @{$_};
        my $got = frac($arg);
        delta_ok($exp, $got, "frac($arg)") or diag("Expected: $exp, got: $got")
    }
};

subtest 'sine' => sub {
    plan tests => 1;
    my $arg = 0.226385;
    my $exp = 0.989012251401426;
    my $got = sine($arg);
    delta_ok($exp, $got, "sine($arg)") or diag("Expected: $exp, got: $got");
};

subtest 'Polynome' => sub {
    plan tests => 2;

    my $got = polynome( 10, 1, 2, 3 );
    cmp_ok(321, '==', $got, 'Simple polynome') or diag("Expected: 321, got: $got");

    subtest 'Long' => sub {
        my @a = map { deg2rad( ddd(@$_) ) } (
            [ 23, 26, 21.448 ],
            [ 0,  0,  -4680.93 ],
            [ 0,  0,  -1.55 ],
            [ 0,  0,  1999.25 ],
            [ 0,  0,  -51.38 ],
            [ 0,  0,  -249.67 ],
            [ 0,  0,  -39.05 ],
            [ 0,  0,  7.12 ],
            [ 0,  0,  27.87 ],
            [ 0,  0,  5.79 ],
            [ 0,  0,  2.45 ]
        );
        my $t  = -0.127296372347707;
        my $x0 = polynome( $t, @a );
        my $x1 = (
            (
                (
                    (
                        (
                            (
                                (
                                    ( ( $a[10] * $t + $a[9] ) * $t + $a[8] ) * $t + $a[7]
                                ) * $t + $a[6]
                            ) * $t + $a[5]
                        ) * $t + $a[4]
                    ) * $t + $a[3]
                ) * $t + $a[2]
            ) * $t + $a[1]
          ) * $t + $a[0];
        delta_ok( $x1, $x0, 'Polynome algorithm' ) or diag("Expected: $x0, got: $x1");
    }
};

subtest 'Normalization' => sub {
    plan tests => 3;

    my $got = to_range( 410.5, 360 );
    my $exp = 50.5;
    delta_ok($got, $exp, "to_range" ) or diag("Expected: $exp, got: $got");

    $got = reduce_deg(410.5);
    delta_ok($got, $exp, "reduce_deg" ) or diag("Expected: $exp, got: $got");

    $got = reduce_rad( pi2 + pi );
    delta_ok($got, pi, "reduce_rad" ) or diag("Expected: PI, got: $got");
};


subtest 'Opposite' => sub {
    my @cases = ( [180, 0], [270, 90], [0, 180], [90, 270] );
    plan tests => scalar @cases * 2;

    for ( @cases ) {
        my ($arg, $exp) = @{$_};
        my $got = opposite_deg($arg);
        cmp_ok( $exp, '==', $got, "opposite_deg($arg)" ) or diag("Expected: $exp, got: $got");
    }

    for ( @cases ) {
        my ($arg, $exp) = map { deg2rad($_) } @{$_};
        my $got = opposite_rad($arg);
        delta_ok( $exp, $got, "opposite_rad($arg)" ) or diag("Expected: $exp, got: $got");
    }

};

subtest 'Angles' => sub {
    plan tests => 3;

    subtest 'angle_c' => sub {
        my $y = 180;
        my @cases = ( [180, 0], [270, 90], [0, 180], [90, 90] );
        plan tests => scalar @cases * 2;
        for ( @cases ) {
            my ($arg, $exp) = @{$_};
            my $got = angle_c( $y, $arg );
            cmp_ok( $exp, '==', $got, "angle_c($y, $arg)" )
                or diag("Expected: $exp, got: $got");
        }
        for ( @cases ) {
            my ($arg, $exp) = map { deg2rad($_) } @{$_};
            my $got = angle_c_rad( pi, $arg );
            delta_ok( $exp, $got, "angle_c_rad(pi, $arg)" )
                or diag("Expected: $exp, got: $got");
        }
    };

    my $got = angle_s( 177.5, 4.3, 10, -15 );
    my $exp = 163.695031046655;
    delta_ok($exp, $got, 'angle_s') or diag("Expected: $exp, got: $got");

    subtest 'diff_angle' => sub {
        my @cases = (
            [10, 40, 30],
            [350, 5, 15],
            [5, 350, -15],
        );
        plan tests => scalar @cases;
        for (@cases) {
            my ($a, $b, $exp) = @{$_};
            my $got = diff_angle($a, $b);
            delta_ok( $exp, $got, "diff_angle($a, $b)") or diag("Expected: $exp, got: $got");
        }
    };
};

subtest 'Coordinates conversions' => sub {
    my $x0     = -.0328084439326622;
    my $y0     = -.461338601422229;
    my $z0     = -.0567790199103871;
    my $r0     = 0.465975918108957;
    my $theta0 = -.122153243943489;
    my $phi0   = 4.64139274891861;

    plan tests => 2;

    subtest 'Rectangular --> Spherical' => sub {
        plan tests => 3;
        my ( $r, $theta, $phi ) = polar( $x0, $y0, $z0 );
        delta_ok($r0, $r,  'r' );
        delta_ok($theta0, $theta, 'theta' );
        delta_ok($phi0, $phi,  'phi' );
    };

    subtest 'Spherical --> Rectangular' => sub {
        plan tests => 3;
        my ( $x, $y, $z ) = cart( $r0, $theta0, $phi0 );
        delta_ok($x0, $x, 'x' );
        delta_ok($y0, $y, 'y' );
        delta_ok($z0, $z, 'z' );
    };
}
