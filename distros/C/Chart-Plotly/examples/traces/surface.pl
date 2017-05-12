use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Surface;
use English qw(-no_match_vars);

my $surface = Chart::Plotly::Trace::Surface->new(
    x => [ 0 .. 10 ],
    y => [ 0 .. 10 ],
    z => [
        map {
            my $y = $ARG;
            [ map { $ARG - $y * $y } ( 0 .. 10 ) ]
        } ( 0 .. 10 )
    ]
);

show_plot( [$surface] );

