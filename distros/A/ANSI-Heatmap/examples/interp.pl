use strict;
use warnings;
use ANSI::Heatmap;

binmode STDOUT, ':utf8';

my $map = ANSI::Heatmap->new(
    half => 1,
    swatch => 'grayscale',
);
for my $x (0..5) {
   for my $y (0..5) {
       $map->set($x, $y, ($x % 2 == $y % 2));
   }
}

for my $wh ([3,3], [3,5], [5,5], [6,6], [12,12], [15,16], [10,20]) {
    my ($w, $h) = @$wh;
    $map->width($w);
    $map->height($h);
    $map->interpolate(0);
    print "${w}x${h}\n";
    print $map;
    $map->interpolate(1);
    print "${w}x${h}, interpolated\n";
    print $map;
}
