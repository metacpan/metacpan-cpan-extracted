use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# The sizing / padding / border / corner-radius helper subs.
# These are the Perl analogues of the CLAY_SIZING_* / CLAY_PADDING_ALL /
# CLAY_BORDER_* / CLAY_CORNER_RADIUS macros from clay.h.
# -----------------------------------------------------------------------------

subtest 'sizing helpers' => sub {
    my $fit = sizing_fit(10, 100);
    is( $fit->{type}, CLAY__SIZING_TYPE_FIT, 'sizing_fit type' );
    is( $fit->{min}, 10, 'sizing_fit min' );
    is( $fit->{max}, 100, 'sizing_fit max' );

    my $grow = sizing_grow();
    is( $grow->{type}, CLAY__SIZING_TYPE_GROW, 'sizing_grow defaults to no bounds' );
    is( $grow->{min}, 0, 'sizing_grow min defaults to 0' );

    my $fixed = sizing_fixed(50);
    is( $fixed->{type}, CLAY__SIZING_TYPE_FIXED, 'sizing_fixed type' );
    is( $fixed->{min}, 50, 'sizing_fixed encodes size as min' );
    is( $fixed->{max}, 50, 'sizing_fixed encodes size as max' );

    my $pct = sizing_percent(0.5);
    is( $pct->{type}, CLAY__SIZING_TYPE_PERCENT, 'sizing_percent type' );
    is( $pct->{percent}, 0.5, 'sizing_percent value' );
};

subtest 'padding/border/corner helpers' => sub {
    my $pad = padding_all(8);
    is( $pad->{left},   8, 'padding_all left' );
    is( $pad->{right},  8, 'padding_all right' );
    is( $pad->{top},    8, 'padding_all top' );
    is( $pad->{bottom}, 8, 'padding_all bottom' );

    my $bw = border_all(2);
    is( $bw->{left},            2, 'border_all left' );
    is( $bw->{betweenChildren}, 2, 'border_all betweenChildren' );

    my $bo = border_outside(3);
    is( $bo->{left},            3, 'border_outside left' );
    is( $bo->{betweenChildren}, 0, 'border_outside betweenChildren is 0' );

    my $cr = corner_radius_all(12);
    is( $cr->{topLeft},     12, 'corner_radius_all topLeft' );
    is( $cr->{bottomRight}, 12, 'corner_radius_all bottomRight' );
};

subtest 'helpers validate their arguments' => sub {
    like( dies { padding_all(-1) },    qr/padding_all: value: expected an integer in 0\.\.65535, got '-1'/,
        'negative padding' );
    like( dies { padding_all(70000) }, qr/padding_all: value: expected an integer in 0\.\.65535/,
        'padding above uint16' );
    like( dies { border_all(1.5) },    qr/border_all: width: expected an integer/, 'fractional border' );
    like( dies { border_outside('x') }, qr/border_outside: width: expected an integer/, 'non-numeric border' );
    like( dies { sizing_fixed('abc') }, qr/sizing_fixed: size: expected a finite number/, 'non-numeric size' );
    like( dies { corner_radius_all(9**9**9) }, qr/corner_radius_all: radius: expected a number >= 0/,
        'infinite radius' );
    like( dies { corner_radius_all(-1) }, qr/corner_radius_all: radius: expected a number >= 0, got '-1'/,
        'negative radius' );
    like( dies { sizing_percent(1.5) }, qr/sizing_percent: percent: expected a number in 0\.\.1, got '1.5'/,
        'percent above 1' );
    like( dies { sizing_percent(-0.5) }, qr/sizing_percent: percent: expected a number in 0\.\.1/, 'negative percent' );
    like( dies { sizing_fit(0, -9**9**9) }, qr/sizing_fit: max: expected a finite number or \+Inf/,
        '-Inf max' );

    is( sizing_grow(0, 0)->{max}, 0, 'sizing_grow(0, 0) keeps Clay\'s "no max" zero' );
    is( sizing_fit(10, 9**9**9)->{max}, 9**9**9, '+Inf is accepted as an unbounded max' );
    like( dies { sizing_fixed(1e39) }, qr/sizing_fixed: size: expected a finite number/,
        'a size beyond the range of a C float' );
    is( sizing_fit(0, 1e39)->{max}, 9**9**9, 'a max beyond it is unbounded' );
};

subtest 'optional arguments see magical values' => sub {
    # $1 caches its flags from the last read: read it while undef first, so
    # only get-magic can tell that it now holds a number.
    my $stale;
    "u" =~ /(x)?u/; $stale = $1; "x25" =~ /(\d+)/;
    is( sizing_fit($1)->{min}, 25, 'a capture variable as sizing_fit min' );
    "u" =~ /(x)?u/; $stale = $1; "x7" =~ /(\d+)/;
    is( Clay__HashString('a', $1)->{id}, Clay__HashString('a', 7)->{id}, 'a capture variable as a hash seed' );
};

done_testing;
