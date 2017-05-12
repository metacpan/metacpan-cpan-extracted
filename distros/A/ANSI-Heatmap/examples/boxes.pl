use strict;
use warnings;
use ANSI::Heatmap;

binmode STDOUT, ':utf8';

for my $half (0,1) {
    for my $box ([2,2], [3, 5], [9,9], [10,10], [11,11], [21,19]) {
        my ($x, $y) = @$box;
        my $map = ANSI::Heatmap->new(
            half => $half,
            min_x => 1,
            min_y => 1,
            max_x => $x,
            max_y => $y,
            swatch => 'grayscale',
        );

        my @white = (
            (map { [1,$_], [$x,$_] } (1..$y)),
            (map { [$_, 1], [$_, $y] } (1..$x)),
        );
        for my $c (@white) {
            $map->set(@$c, 100);
        }
        print "$x x $y\n";
        print $map, "\n";
    }
}
