use Chart::Plotly;
use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Scattergeo;
use Chart::Plotly::Trace::Attribute::Marker;
my $scattergeo = Chart::Plotly::Trace::Scattergeo->new(
    mode => 'markers+text',
    text => [ 'Mount Everest', 'K2',      'Kangchenjunga', 'Lhotse', 'Makalu', 'Cho Oyu',
              'Dhaulagiri I',  'Manaslu', 'Nanga Parbat',  'Annapurna I'
    ],
    lon => [ 86.9252777778, 76.5133333333, 88.1475,       86.9330555556, 87.0888888889, 86.6608333333,
             83.4930555556, 84.5597222222, 74.5891666667, 83.8202777778
    ],
    lat => [ 27.9880555556, 35.8813888889, 27.7033333333, 27.9616666667, 27.8897222222, 28.0941666667,
             28.6966666667, 28.55,         35.2372222222, 28.5955555556
    ],
    name => "Highest mountains
        https://en.wikipedia.org/wiki/List_of_highest_mountains_on_Earth",
    textposition => [ 'top right',
                      'top center',
                      'bottom center',
                      'bottom left',
                      'right',
                      'left',
                      'left',
                      'right',
                      'bottom center',
                      'top center'
    ],
    marker => Chart::Plotly::Trace::Attribute::Marker->new(
                                                   size  => 7,
                                                   color => [
                                                       '#bebada', '#fdb462', '#fb8072', '#d9d9d9', '#bc80bd', '#b3de69',
                                                       '#8dd3c7', '#80b1d3', '#fccde5', '#ffffb3'
                                                   ]
    )
);

my $plot = Chart::Plotly::Plot->new( traces => [$scattergeo],
                                     layout => { title => 'Mountains',
                                                 geo   => { scope => 'asia', }
                                     }
);
Chart::Plotly::show_plot($plot);

