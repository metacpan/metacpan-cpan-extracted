use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Scatterpolar;
# Example data from: https://plot.ly/javascript/polar-chart/#area-polar-chart
my $scatterpolar1 = Chart::Plotly::Trace::Scatterpolar->new(
    mode      => "lines",
    r         => [ 0, 1.5, 1.5, 0, 2.5, 2.5, 0 ],
    theta     => [ 0, 10, 25, 0, 205, 215, 0 ],
    fill      => "toself",
    fillcolor => '#709BFF',
    line      => {
        color => 'black'
    }
);
my $scatterpolar2 = Chart::Plotly::Trace::Scatterpolar->new(
    mode      => "lines",
    r         => [ 0, 3.5, 3.5, 0 ],
    theta     => [ 0, 55, 75, 0 ],
    fill      => "toself",
    fillcolor => '#E4FF87',
    line      => {
        color => 'black'
    }
);

show_plot([ $scatterpolar1, $scatterpolar2 ]);

