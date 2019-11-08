use Chart::Plotly;
use Chart::Plotly::Plot;
use JSON;
use Chart::Plotly::Trace::Image;

# Example from https://github.com/plotly/plotly.js/blob/e86c95b4b2abe646d7ab4e311fcd40cc61f1eaea/test/image/mocks/image_opacity.json
my $trace1 = Chart::Plotly::Trace::Image->new({'z' => [[[255, 0, 0, ], [0, 255, 0, ], [0, 0, 255, ], ], ], 'opacity' => 0.1, });


my $plot = Chart::Plotly::Plot->new(
    traces => [$trace1, ],
    layout => 
        {'width' => 400, 'title' => {'text' => 'image with opacity 0.1', }, 'height' => 400, }
); 

Chart::Plotly::show_plot($plot);
    
