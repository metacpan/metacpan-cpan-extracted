use Chart::Plotly;
use Chart::Plotly::Plot;
use JSON;
use Chart::Plotly::Trace::Treemap;

# Example from https://github.com/plotly/plotly.js/blob/3004a9ac8300f8d8681ba2cdfb9833856a6f37fa/test/image/mocks/treemap_with-without_values.json
my $trace1 = Chart::Plotly::Trace::Treemap->new({'name' => 'without values', 'domain' => {'x' => [0.01, 0.33, ], }, 'labels' => ['Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot', 'Golf', 'Hotel', 'India', 'Juliet', 'Kilo', 'Lima', 'Mike', 'November', 'Oscar', 'Papa', 'Quebec', 'Romeo', 'Sierra', 'Tango', 'Uniform', 'Victor', 'Whiskey', 'X ray', 'Yankee', 'Zulu', ], 'parents' => ['', 'Alpha', 'Alpha', 'Charlie', 'Charlie', 'Charlie', 'Foxtrot', 'Foxtrot', 'Foxtrot', 'Foxtrot', 'Juliet', 'Juliet', 'Juliet', 'Juliet', 'Juliet', 'Oscar', 'Oscar', 'Oscar', 'Oscar', 'Oscar', 'Oscar', 'Uniform', 'Uniform', 'Uniform', 'Uniform', 'Uniform', 'Uniform', ], 'hoverinfo' => 'all', 'level' => 'Oscar', 'textinfo' => 'label+value+percent parent+percent entry+percent root+text+current path', });

my $plot = Chart::Plotly::Plot->new(
    traces => [$trace1, ],
    layout => 
        {'width' => 1500, 'height' => 600, 'annotations' => [{'xanchor' => 'center', 'y' => 0, 'x' => 0.17, 'showarrow' => JSON::false, 'text' => '<b>with counted leaves<br>', 'yanchor' => 'top', }, {'showarrow' => JSON::false, 'x' => 0.5, 'yanchor' => 'top', 'text' => '<b>with values and branchvalues: total<br>', 'xanchor' => 'center', 'y' => 0, }, {'y' => 0, 'xanchor' => 'center', 'yanchor' => 'top', 'text' => '<b>with values and branchvalues: remainder<br>', 'showarrow' => JSON::false, 'x' => 0.83, }, ], 'margin' => {'r' => 0, 't' => 50, 'b' => 25, 'l' => 0, }, 'shapes' => [{'x1' => 0.33, 'type' => 'rect', 'x0' => 0.01, 'y0' => 0, 'layer' => 'above', 'y1' => 1, }, {'y0' => 0, 'x0' => 0.34, 'x1' => 0.66, 'type' => 'rect', 'y1' => 1, 'layer' => 'above', }, {'y0' => 0, 'x0' => 0.67, 'x1' => 0.99, 'type' => 'rect', 'y1' => 1, 'layer' => 'above', }, ], }
); 

Chart::Plotly::show_plot($plot);
    
