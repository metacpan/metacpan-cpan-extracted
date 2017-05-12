#!/usr/bin/perl

# use lib '../Algorithm-RectanglesContainingDot/lib';

use Test::More tests => 20003;

BEGIN { use_ok('Algorithm::RectanglesContainingDot_XS') };
BEGIN { use_ok('Algorithm::RectanglesContainingDot') };

my $a = Algorithm::RectanglesContainingDot_XS->new;
my $r = Algorithm::RectanglesContainingDot::Perl->new;

my $nr = 100000;
my $np = 20000;

my $d = 10000;
my $dd = 200;

# use Devel::Peek;
# Dump($a);

for (0..($nr-1)) {
    my $x0 = int(rand $d);
    my $y0 = int(rand $d);
    my $x1 = int($x0 + rand $dd);
    my $y1 = int($y0 + rand $dd);
    $a->add_rectangle($_, $x0, $y0, $x1, $y1);
    $r->add_rectangle($_, $x0, $y0, $x1, $y1);
}

ok(1, "data inserted");

for (1..$np) {
    my $x = int(rand($d + 4 * $dd) - $d);
    my $y = int(rand($d + 4 * $dd) - $d);
    my @rect = sort $a->rectangles_containing_dot($x,$y);
    my @rectref = sort $r->rectangles_containing_dot($x,$y);

    is("@rect", "@rectref");
}
