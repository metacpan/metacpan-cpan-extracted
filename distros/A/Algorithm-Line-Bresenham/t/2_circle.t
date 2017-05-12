#!/usr/bin/perl
use Test::More tests => 2;

BEGIN { use_ok( 'Algorithm::Line::Bresenham', qw(circle) ); }

use Data::Dumper;

my $r = 10;
my @circle = circle( ($r) x 3 );

my @points;
for (@circle) {
    $points[$_->[0]][$_->[1]] = '#';
}
my $circle = join "\n", map {
    join '', map { $_ || ' ' } @$_;
} @points;


chomp (my $exp_circle = <<EOCIRCLE);
       #######
     ##       ##
    #           #
   #             #
  #               #
 #                 #
 #                 #
#                   #
#                   #
#                   #
#                   #
#                   #
#                   #
#                   #
 #                 #
 #                 #
  #               #
   #             #
    #           #
     ##       ##
       #######
EOCIRCLE

is ( 
    $circle, $exp_circle, 'circle' ) or diag $circle;
