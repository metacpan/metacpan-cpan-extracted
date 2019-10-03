use Chart::Plotly;
use Chart::Plotly::Plot;
use JSON;
use Chart::Plotly::Trace::Choroplethmapbox;

# Example from https://github.com/plotly/plotly.js/blob/cb202a8e47631e20555de382d2bbc7393625519b/test/image/mocks/mapbox_choropleth0.json
my $trace1 = Chart::Plotly::Trace::Choroplethmapbox->new({'locations' => ['NY', 'MA', 'VT', ], 'geojson' => 'https://raw.githubusercontent.com/python-visualization/folium/master/examples/data/us-states.json', 'z' => [10, 20, 30, ], });


my $plot = Chart::Plotly::Plot->new(
    traces => [$trace1, ],
    layout => 
        {'width' => 600, 'mapbox' => {'style' => 'open-street-map', 'center' => {'lon' => -74.22, 'lat' => 42.35, }, 'zoom' => 3.5, }, }
); 

Chart::Plotly::show_plot($plot);
    
