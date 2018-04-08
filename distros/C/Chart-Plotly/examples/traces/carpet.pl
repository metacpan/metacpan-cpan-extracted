use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Carpet;
# Example data from: https://plot.ly/javascript/carpet-plot/#add-parameter-values
my $carpet = Chart::Plotly::Trace::Carpet->new(
    a => [ 4, 4, 4, 4.5, 4.5, 4.5, 5, 5, 5, 6, 6, 6 ],
    b => [ 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3 ],
    y => [ 2, 3.5, 4, 3, 4.5, 5, 5.5, 6.5, 7.5, 8, 8.5, 10 ]);

show_plot([ $carpet ]);

