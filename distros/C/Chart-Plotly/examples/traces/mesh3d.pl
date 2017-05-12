use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Mesh3d;
use List::Flatten;
use List::MoreUtils qw/pairwise/;
use English qw(-no_match_vars);

my @x = flat map { [ 0 .. 10 ] } ( 0 .. 10 );
my @y = flat map {
    my $y = $ARG;
    map { $y } ( 0 .. 10 )
} ( 0 .. 10 );
my @z = pairwise { $a * $a + $b * $b } @x, @y;
my $mesh3d = Chart::Plotly::Trace::Mesh3d->new( x => \@x, y => \@y, z => \@z );

show_plot( [$mesh3d] );

