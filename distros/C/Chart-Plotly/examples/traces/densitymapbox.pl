use Chart::Plotly;
use Chart::Plotly::Plot;
use JSON;
use Chart::Plotly::Trace::Densitymapbox;

# Example from https://github.com/plotly/plotly.js/blob/42998576f3ed1dd7f03bfcafd72627a0163bf605/test/image/mocks/mapbox_density0.json
my $trace1 = Chart::Plotly::Trace::Densitymapbox->new({'lon' => [10, 20, 30, ], 'z' => [1, 3, 2, ], 'lat' => [15, 25, 35, ], });


my $plot = Chart::Plotly::Plot->new(
    traces => [$trace1, ],
    layout => 
        {'height' => 400, 'width' => 600, 'mapbox' => { 'style' => 'open-street-map'}}
); 

Chart::Plotly::show_plot($plot);
    
