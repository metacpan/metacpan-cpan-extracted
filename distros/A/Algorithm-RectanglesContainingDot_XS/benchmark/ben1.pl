#!/usr/bin/perl

use Benchmark 'cmpthese';

use Algorithm::RectanglesContainingDot;
use Algorithm::RectanglesContainingDot_XS;

$|=1;

my $a = Algorithm::RectanglesContainingDot->new;
my $axs = Algorithm::RectanglesContainingDot_XS->new;

my $nr = 100000;
my $np = 5000;

my $d = 100000;
my $dd = 20;

for (0..($nr-1)) {
    my $x0 = int(rand $d);
    my $y0 = int(rand $d);
    my $x1 = int($x0 + rand $dd);
    my $y1 = int($y0 + rand $dd);
    $a->add_rectangle($_, $x0, $y0, $x1, $y1);
    $axs->add_rectangle($_, $x0, $y0, $x1, $y1);

}

my @x = map { rand($d + 4 * $dd) - $d } 0..$np;
my @y = map { rand($d + 4 * $dd) - $d } 0..$np;

cmpthese(-1,
         {
          pp => sub {
              # warn "pp";
              for (0..$np) {
                  @r = $a->rectangles_containing_dot($x[$_], $y[$_])
              }
          },
          ref => sub {
              # warn "ref";
              for (0..$np) {
                  @r = $a->_rectangles_containing_dot_ref($x[$_], $y[$_])
              }
          },
          xs => sub {
              # warn "xs";
              for (0..$np) {
                  # print ".";
                  # print "index: $_, x: $x[$_], y: $y[$_]\n";
                  @r = $axs->rectangles_containing_dot($x[$_], $y[$_])
              }
          }
         } );
