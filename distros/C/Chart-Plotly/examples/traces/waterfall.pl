use Chart::Plotly;
use Chart::Plotly::Trace::Waterfall;
use Chart::Plotly::Trace::Scatter;
use Chart::Plotly::Plot;

# Example from  https://github.com/plotly/plotly.js/blob/8f8956432ed18368fb6d3f70107b94bbfb39a528/test/image/mocks/waterfall_line.json

my $trace1 = Chart::Plotly::Trace::Scatter->new(
      "x"=>[
        0,
        1,
        2,
        3,
        4,
        5
      ],
      "y"=>[
        1.5,
        1,
        1.3,
        0.7,
        0.8,
        0.9
      ],
    );


my $trace2 = Chart::Plotly::Trace::Waterfall->new(
      "x"=>[
        0,
        1,
        2,
        3,
        4,
        5
      ],
      "y"=>[
        1,
        0.5,
        0.7,
        -1.2,
        0.3,
        0.4
      ],
  );

my $plot = Chart::Plotly::Plot->new(
    traces => [ $trace1, $trace2 ]
);

Chart::Plotly::show_plot($plot);
