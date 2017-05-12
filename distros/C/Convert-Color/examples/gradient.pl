#!/usr/bin/perl

use strict;
use warnings;

use Convert::Color;
use Getopt::Long;

my $steps = 10;
my $space = "hsv";
my $html;

GetOptions(
   'number|n=i' => \$steps,
   'space=s' => \$space,
   'html' => \$html,
) or exit 1;

my $as_space = "as_$space";

my @start = Convert::Color->new( shift @ARGV || die "No start colour\n" )->$as_space->$space;
my @end   = Convert::Color->new( shift @ARGV || die "No end colour\n" )->$as_space->$space;

print qq[<html><body><table>\n] if $html;

foreach ( 0 .. $steps ) {
   my $alpha = $_ / $steps;

   my $col = Convert::Color->new( "$space:" . join ",", map { (1-$alpha) * $start[$_] + $alpha * $end[$_] } 0 .. 2 );

   my $rgb = $col->as_rgb8;

   if( $html ) {
      my $hex = $rgb->hex;
      printf qq[<tr><td style="background-color: #%s">#%s</td></tr>\n], $hex, $hex;
   }
   else {
      printf "%s  h: %3s, s: %3s, v: %3s\n", $rgb->hex, $col->hue, $col->saturation, $col->value;
   }
}

print qq[</table></body></html>\n] if $html;
