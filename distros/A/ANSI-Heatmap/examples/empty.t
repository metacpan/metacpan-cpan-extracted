use strict;
use warnings;
use ANSI::Heatmap;

my $map = ANSI::Heatmap->new( max_x => 10, max_y => 5 );
print $map;
