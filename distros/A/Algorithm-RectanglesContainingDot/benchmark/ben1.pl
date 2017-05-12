#!/usr/bin/perl

use Benchmark 'cmpthese';

use Algorithm::RectanglesContainingDot;

my $a = Algorithm::RectanglesContainingDot->new;

my $nr = 20000;
my $np = 50000;

my $d = 100000;
my $dd = 20;

for (0..($nr-1)) {
    my $x0 = int(rand $d);
    my $y0 = int(rand $d);
    my $x1 = int($x0 + rand $dd);
    my $y1 = int($y0 + rand $dd);
    $a->add_rectangle($_, $x0, $y0, $x1, $y1);
}

my @x = map { rand($d + 4 * $dd) - $d } 0..$np;
my @y = map { rand($d + 4 * $dd) - $d } 0..$np;

cmpthese(-1,
         {
          fast2 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 2;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          fast4 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 4;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          fast8 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 8;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          fast16 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 16;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          fast32 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 32;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          fast64 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 64;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          fast128 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 128;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          fast256 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 256;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          fast4096 => sub {
              $Algorithm::RectanglesContainingDot::MIN_DIV = 4096;
              $a->_reset;
              for (0..$np) {
                  @r= $a->rectangles_containing_dot($x[$_],$y[$_])
              }
          },
          #fast17000 => sub {
          #    $Algorithm::RectanglesContainingDot::MIN_DIV = 17000;
          #    for (0..$np) {
          #        @r= $a->rectangles_containing_dot($x[$_],$y[$_])
          #    }
          #},
          #ref =>  sub {
          #    for (0..$np) {
          #        @r= $a->_rectangles_containing_dot_ref($x[$_],$y[$_])
          #    }
          #}
         } );
