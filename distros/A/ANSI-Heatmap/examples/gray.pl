use strict;
use warnings;
use ANSI::Heatmap;

binmode STDOUT, ':utf8';

# Advanced usage
my $map = ANSI::Heatmap->new(
    half => 1,
    min_x => 1,
    min_y => 1,
    max_x => 10,
    max_y => 10,
    swatch => 'grayscale',
 );
 for my $x (1..10) {
    for my $y (1..10) {
        $map->set($x, $y, $x * $y);
    }
 }
 print $map->to_string;  # explicit

