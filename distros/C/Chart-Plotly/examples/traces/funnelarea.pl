use Chart::Plotly;
use Chart::Plotly::Plot;
use JSON;
use Chart::Plotly::Trace::Funnelarea;

# Example from https://github.com/plotly/plotly.js/blob/a9625b6466cdd41c7c686e7dc516171c6eae52ac/test/image/mocks/funnelarea_simple.json
my $trace1 = Chart::Plotly::Trace::Funnelarea->new({'values' => [5, 4, 3, 2, 1, ], });


my $plot = Chart::Plotly::Plot->new(
    traces => [$trace1, ],
    layout => 
        {'height' => 300, 'width' => 400, }
); 

Chart::Plotly::show_plot($plot);
    
