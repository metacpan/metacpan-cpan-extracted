use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Scattergl;
use English qw(-no_match_vars);

my $scattergl = Chart::Plotly::Trace::Scattergl->new(
    x => [
        map {
            2 * cos( $ARG * 2 * 3.14 / 100 ) +
              cos( 2 * $ARG * 2 * 3.14 / 100 )
        } ( 1 .. 101 )
    ],
    y => [
        map {
            2 * sin( $ARG * 2 * 3.14 / 100 ) + sin( 2 * $ARG * 2 * 3.14 / 100 )
        } ( 1 .. 101 )
    ]
);

show_plot( [$scattergl] );

