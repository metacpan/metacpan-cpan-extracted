use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Carpet;
use Chart::Plotly::Trace::Contourcarpet;
# Example data from: https://plot.ly/javascript/carpet-contour/#add-contours
my $contourcarpet = Chart::Plotly::Trace::Contourcarpet->new(
    a           => [ 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3 ],
    b           => [ 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6 ],
    z           => [ 1, 1.96, 2.56, 3.0625, 4, 5.0625, 1, 7.5625, 9, 12.25, 15.21, 14.0625 ],
    autocontour => 0,
    contours    => {
        start => 1,
        end   => 14,
        size  => 1
    },
    line        => {
        width     => 2,
        smoothing => 0
    },
    colorbar    => {
        len => 0.4,
        y   => 0.25
    }
);

my $carpet = Chart::Plotly::Trace::Carpet->new(
    a     => [ 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3 ],
    b     => [ 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6 ],
    x     => [ 2, 3, 4, 5, 2.2, 3.1, 4.1, 5.1, 1.5, 2.5, 3.5, 4.5 ],
    y     => [ 1, 1.4, 1.6, 1.75, 2, 2.5, 2.7, 2.75, 3, 3.5, 3.7, 3.75 ],
    aaxis => {
        tickprefix     => "a = ",
        smoothing      => 0,
        minorgridcount => 9,
        type           => 'linear'
    },
    baxis => {
        tickprefix     => "b = ",
        smoothing      => 0,
        minorgridcount => 9,
        type           => 'linear'
    }
);

show_plot([ $contourcarpet, $carpet ]);

