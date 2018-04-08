use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Area;
# Example data from: https://plot.ly/javascript/wind-rose-charts/#wind-rose-chart
my $area = Chart::Plotly::Trace::Area->new(
    r      => [ 77.5, 72.5, 70.0, 45.0, 22.5, 42.5, 40.0, 62.5 ],
    t      => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
    name   => '11-14 m/s',
    marker => { color => 'rgb(106,81,163)' },
);

show_plot([ $area ]);

