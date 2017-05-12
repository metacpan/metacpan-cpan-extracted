use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Heatmap;
use English qw(-no_match_vars);

my $heatmap = Chart::Plotly::Trace::Heatmap->new(
    x => [ 0 .. 10 ],
    y => [ 0 .. 10 ],
    z => [
        map {
            my $y = $ARG;
            [ map { $ARG * $ARG + $y * $y } ( 0 .. 10 ) ]
        } ( 0 .. 10 )
    ]
);

show_plot( [$heatmap] );

