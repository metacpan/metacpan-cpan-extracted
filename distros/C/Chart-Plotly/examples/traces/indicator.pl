use Chart::Plotly;
use Chart::Plotly::Plot;
use JSON;
use Chart::Plotly::Trace::Indicator;

# Example from https://github.com/plotly/plotly.js/blob/68c2aefa8ab6af09c598b3739149e2d5e89155d9/test/image/mocks/indicator_grid_template.json
my $trace1 = Chart::Plotly::Trace::Indicator->new({'domain' => {'column' => 0, 'row' => 0, }, 'gauge' => {'axis' => {'range' => [0, 200, ], 'visible' => JSON::false, }, }, 'delta' => {'reference' => 60, }, 'value' => 120, });

my $trace2 = Chart::Plotly::Trace::Indicator->new({'value' => 120, 'gauge' => {'axis' => {'visible' => JSON::false, 'range' => [-200, 200, ], }, 'shape' => 'bullet', }, 'domain' => {'y' => [0.15, 0.35, ], 'x' => [0.05, 0.5, ], }, });

my $trace3 = Chart::Plotly::Trace::Indicator->new({'domain' => {'column' => 1, 'row' => 0, }, 'value' => 120, 'mode' => 'number+delta', });

my $trace4 = Chart::Plotly::Trace::Indicator->new({'domain' => {'row' => 1, 'column' => 1, }, 'value' => 40, 'mode' => 'delta', });


my $plot = Chart::Plotly::Plot->new(
    traces => [$trace1, $trace2, $trace3, $trace4, ],
    layout => 
        {'margin' => {'b' => 25, 'l' => 25, 'r' => 25, 't' => 25, }, 'template' => {'data' => {'indicator' => [{'mode' => 'number+delta+gauge', 'title' => {'text' => 'Title', }, 'delta' => {'reference' => 60, }, }, ], }, }, 'height' => 400, 'grid' => {'columns' => 2, 'pattern' => 'independent', 'rows' => 2, }, 'width' => 700, }
); 

Chart::Plotly::show_plot($plot);
    
