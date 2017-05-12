use strict;
use warnings;
use ANSI::Heatmap;

binmode STDOUT, ':utf8';

my $map = ANSI::Heatmap->new(
    half => 1,
    swatch => 'grayscale',
);
for my $x (0..19) {
    for my $y (0..19) {
        my $sc = 1 + ($x >= 10) + ($y >= 10) * 2;
        my $z = (($x/$sc) % 2 == ($y/$sc) % 2);
        $map->set($x, $y, $z);
    }
}
print "$map\n";
$map->width(15);
$map->height(15);
print "$map\n";
$map->interpolate(1);
print "$map\n";
