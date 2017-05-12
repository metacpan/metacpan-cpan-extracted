#!/usr/bin/perl

use strict;
use warnings;

my $limit;
BEGIN { $limit =  @ARGV ? shift : 100 }

use Algorithm::BreakOverlappingRectangles;

use Algorithm::RectanglesContainingDot;

#eval {

    while (1) {

        my $bor = Algorithm::BreakOverlappingRectangles->new;

        my $rcd1 = Algorithm::RectanglesContainingDot->new;
        my $rcd2 = Algorithm::RectanglesContainingDot->new;
        
        open my $data, ">", "rect.dat"
            or die "unable to dump test data\n";
        
        for (1..$limit) {
            my ($x0, $y0) = map { 2 * int(400 * rand) } 0..1;
            my ($dx, $dy) = map { 2 * int(100 * rand) } 0..1;
            my ($x1, $y1) = ($x0 + $dx, $y0 + $dy);
            print $data "$x0 $y0 $x1 $y1 $_\n";
            $bor->add_rectangle($x0, $y0, $x1, $y1, $_);
            $rcd1->add_rectangle($_, $x0, $y0, $x1, $y1);
        }

        close $data;


        my $rects = $bor->get_rectangles_as_array_ref;
        for (my $i = 0; $i < @$rects; $i++) {
            $rcd2->add_rectangle($i, @{$rects->[$i]}[0..3]);
        }

        for (0..1000) {
            my ($x, $y) = map { 1 + 2 * int(1000 * rand) } 0..1;
            my @test = sort $rcd1->rectangles_containing_dot($x, $y);
            my @this = $rcd2->rectangles_containing_dot($x, $y);
            if (scalar(@this) > 1) { die "only one rectangle in any point" };
            @this = sort map { my @names = @{$rects->[$_]}; @names[4..$#names] } @this;
            if ("@this" ne "@test") {die "bad" }
        }


        print "ok\n";
        last;
    }
#}
