use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Carpet;
use Chart::Plotly::Trace::Scattercarpet;
# Example data from: https://plot.ly/javascript/carpet-scatter/#add-carpet-scatter-trace
my $scattercarpet = Chart::Plotly::Trace::Scattercarpet->new(
    a    => [ map {$_ * 1e-6} 4, 4.5, 5, 6 ],
    b    => [ map {$_ * 1e-6} 1.5, 2.5, 1.5, 2.5 ],
    line => { shape => 'spline', smoothing => 1 }
);

my $carpet = Chart::Plotly::Trace::Carpet->new(
    a     => [ map {$_ * 1e-6} 4, 4, 4, 4.5, 4.5, 4.5, 5, 5, 5, 6, 6, 6 ],
    b     => [ map {$_ * 1e-6} 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3 ],
    y     => [ 2, 3.5, 4, 3, 4.5, 5, 5.5, 6.5, 7.5, 8, 8.5, 10 ],
    aaxis => {
        tickprefix     => 'a = ',
        ticksuffix     => 'm',
        smoothing      => 1,
        minorgridcount => 9,
    },
    baxis => {
        tickprefix     => 'b = ',
        ticksuffix     => 'Pa',
        smoothing      => 1,
        minorgridcount => 9,
    }
);

show_plot([ $carpet, $scattercarpet ]);

