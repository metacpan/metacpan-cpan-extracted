#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2000;

use Algorithm::BreakOverlappingRectangles;

use Algorithm::RectanglesContainingDot;

for (0..4) {


    my $bor = Algorithm::BreakOverlappingRectangles->new;

    my $rcd1 = Algorithm::RectanglesContainingDot->new;
    my $rcd2 = Algorithm::RectanglesContainingDot->new;

    for (0..200) {
        my ($x0, $y0, $x1, $y1) = map { 2 * int(1000 * rand) } 0..3;
        $bor->add_rectangle($x0, $y0, $x1, $y1, $_);
        $rcd1->add_rectangle($_, $x0, $y0, $x1, $y1);
    }

    my $rects = $bor->get_rectangles_as_array_ref;
    for (my $i = 0; $i < @$rects; $i++) {
        $rcd2->add_rectangle($i, @{$rects->[$i]}[0..3]);
    }

    for (0..199) {
        my ($x, $y) = map { 1 + 2 * int(2000 * rand) } 0..1;
        my @test = sort $rcd1->rectangles_containing_dot($x, $y);
        my @this = $rcd2->rectangles_containing_dot($x, $y);
        ok (scalar(@this) <= 1, "only one rectangle in any point");
        if (scalar(@this) > 1) {
            diag("($x,$y) => ". join(" ", map("[@{$rects->[$_]}]", @this)));
        }

        @this = sort map { my @names = @{$rects->[$_]}; @names[4..$#names] } @this;

        is("@this", "@test");
    }
}
