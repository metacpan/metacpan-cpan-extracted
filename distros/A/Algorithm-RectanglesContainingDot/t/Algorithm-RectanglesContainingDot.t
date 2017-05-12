#!/usr/bin/perl

use Test::More tests => 4002;

BEGIN { use_ok('Algorithm::RectanglesContainingDot') };

my $a = Algorithm::RectanglesContainingDot->new;
my $ref = Algorithm::RectanglesContainingDot::Perl->new;

my $nr = 10000;

my $d = 100;
my $dd = 20;

for (0..($nr-1)) {
    my $x0 = int(rand $d);
    my $y0 = int(rand $d);
    my $x1 = int($x0 + rand $dd);
    my $y1 = int($y0 + rand $dd);
    $a->add_rectangle($_, $x0, $y0, $x1, $y1);
    $ref->add_rectangle($_, $x0, $y0, $x1, $y1);
}

ok(1, "data inserted");

for (1..2000) {
    my $x = int(rand($d + 4 * $dd) - $d);
    my $y = int(rand($d + 4 * $dd) - $d);
    my @rect = sort $ref->rectangles_containing_dot($x,$y);
    my @rectref = sort $ref->_rectangles_containing_dot_ref($x,$y);

    is("@rect", "@rectref");
}


SKIP: {
    # these test will use the XS version when available:
    eval "require Algorithm::RectanglesContainingDot_XS"
        or skip "Algorithm::RectanglesContainingDot_XS not installed", 2000;

    for (1..2000) {
        my $x = int(rand($d + 4 * $dd) - $d);
        my $y = int(rand($d + 4 * $dd) - $d);
        my @rect = sort $a->rectangles_containing_dot($x,$y);
        my @rectref = sort $ref->_rectangles_containing_dot_ref($x,$y);

        is("@rect", "@rectref");
    }
}
