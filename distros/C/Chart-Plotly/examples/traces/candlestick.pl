use Chart::Plotly;
use Chart::Plotly::Trace::Candlestick;
my $candlestick = Chart::Plotly::Trace::Candlestick->new(
    x     => [ 1 .. 5 ],
    open  => [ 1, 6, 7 ],
    close => [ 7, 12, 5 ],
    high  => [ 8, 15, 10 ],
    low   => [ 0.5, 5, 4 ]
);

Chart::Plotly::show_plot([$candlestick]);

