#!/usr/bin/perl
use warnings;
use strict;

# I used this to create the faded image content/style/block-fade.png
# It outputs plain text description of the image to stdout, which you
# then need to process with the 'sng' utility to create a PNG image.

use Math::Round qw( round );
use Carp::Assert qw( assert );

die "Usage: $0 width start-colour end-colour >foo.sng\n"
    unless @ARGV == 3;

my ($width, $start_col, $end_col) = @ARGV;
my ($start_r, $start_g, $start_b) = parse_colour($start_col);
my ($end_r, $end_g, $end_b) = parse_colour($end_col);

print "#SNG:\n\n",
      "# Fade from $start_col ($start_r, $start_g, $start_b) to",
      " $end_col ($end_r, $end_g, $end_b).\n\n",
      "IHDR {\n",
      "    width: $width;\n",
      "    height: 1;\n",
      "    bitdepth: 8;\n",
      "    using color;\n",
      "}\n\n",
      "IMAGE {\n",
      "    pixels hex\n";

my $done_pixels = 0;
for (my $x = 0.0; $x < 1.00001; $x += (1.0 / ($width - 1))) {
    my $y = $x * $x;
    my $r = calc_colour($start_r, $end_r, $y);
    my $g = calc_colour($start_g, $end_g, $y);
    my $b = calc_colour($start_b, $end_b, $y);
    printf "    %06X\n", ($r * 0x10000 + $g * 0x100 + $b);
    ++$done_pixels;
}

assert($done_pixels == $width);
print "}\n";


sub parse_colour
{
    my ($colour) = @_;
    die "Bad colour '$colour'\n"
        unless $colour =~ /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i;
    return map { hex } ($1, $2, $3);
}

sub calc_colour
{
    my ($start, $end, $x) = @_;
    return round(($end / 255.0 * $x + $start / 255.0 * (1.0 - $x)) * 255.0);
}

# vi:ts=4 sw=4 expandtab
