use Chart::Plotly;
use Chart::Plotly::Plot;
use JSON;
use Chart::Plotly::Trace::Funnel;

# Example from https://github.com/plotly/plotly.js/blob/b93e3a5a83b6561ac6258a59f274b5fc87630c3e/test/image/mocks/funnel_11.json
my $trace1 = Chart::Plotly::Trace::Funnel->new({'orientation' => 'v', 'marker' => {'color' => 'rgb(255, 102, 97)', }, 'y' => [13.23, 22.7, 26.06, ], 'x' => ['Half Dose', 'Full Dose', 'Double Dose', ], 'name' => 'Orange Juice', });

my $trace2 = Chart::Plotly::Trace::Funnel->new({'name' => 'Vitamin C', 'marker' => {'color' => 'rgb(0, 196, 200)', }, 'y' => [7.98, 16.77, 26.14, ], 'x' => ['Half Dose', 'Full Dose', 'Double Dose', ], 'orientation' => 'v', });

my $trace3 = Chart::Plotly::Trace::Funnel->new({'name' => 'Std Dev - OJ', 'x' => ['Half Dose', 'Full Dose', 'Double Dose', ], 'y' => [1.4102837, 1.236752, 0.8396031, ], 'visible' => JSON::false, 'orientation' => 'v', });

my $trace4 = Chart::Plotly::Trace::Funnel->new({'y' => [0.868562, 0.7954104, 1.5171757, ], 'x' => ['Half Dose', 'Full Dose', 'Double Dose', ], 'name' => 'Std Dev - VC', 'orientation' => 'v', 'visible' => JSON::false, });


my $plot = Chart::Plotly::Plot->new(
    traces => [$trace1, $trace2, $trace3, $trace4, ],
    layout => 
        {'autosize' => JSON::false, 'hidesources' => JSON::false, 'plot_bgcolor' => 'rgb(217, 217, 217)', 'font' => {'color' => '#000', 'size' => 12, 'family' => 'Arial, sans-serif', }, 'width' => 600, 'separators' => '.,', 'legend' => {'xanchor' => 'left', 'font' => {'size' => 16, 'family' => '', 'color' => 'rgb(0, 0, 0)', }, 'bgcolor' => 'rgba(255, 255, 255, 0)', 'bordercolor' => 'rgba(0, 0, 0, 0)', 'yanchor' => 'auto', 'x' => 1.02, 'y' => 0.931907250442406, 'borderwidth' => 1, 'traceorder' => 'normal', }, 'funnelgroupgap' => 0, 'funnelgap' => 0.2, 'annotations' => [{'tag' => '', 'yatype' => 'linear', 'showarrow' => JSON::false, 'xanchor' => 'auto', 'bgcolor' => 'rgba(0,0,0,0)', 'arrowhead' => 1, 'yref' => 'paper', 'ax' => -10, 'align' => 'center', 'yanchor' => 'auto', 'xatype' => 'category', 'bordercolor' => '', 'ref' => 'paper', 'text' => '<b>Supplement</b>', 'x' => 1.3479735318445, 'y' => 0.998214285714286, 'opacity' => 1, 'arrowwidth' => 0, 'font' => {'size' => 18, 'family' => '', 'color' => '', }, 'ay' => -26.7109375, 'arrowcolor' => '', 'borderpad' => 1, 'borderwidth' => 1, 'xref' => 'paper', 'arrowsize' => 1, }, ], 'height' => 440, 'dragmode' => 'zoom', 'hovermode' => 'x', 'paper_bgcolor' => '#fff', 'boxmode' => 'overlay', 'showlegend' => JSON::true, 'titlefont' => {'family' => '', 'size' => 16, 'color' => '', }, 'title' => 'Grouped Funnel Chart', 'margin' => {'r' => 0, 't' => 80, 'b' => 80, 'l' => 80, 'autoexpand' => JSON::true, 'pad' => 2, }, 'yaxis' => {'gridcolor' => 'rgb(255, 255, 255)', 'autotick' => JSON::true, 'ticks' => '', 'tickfont' => {'color' => '', 'size' => 16, 'family' => '', }, 'mirror' => JSON::true, 'tickangle' => 0, 'domain' => [0, 1, ], 'anchor' => 'x', 'showgrid' => JSON::true, 'exponentformat' => 'e', 'tick0' => 0, 'showticklabels' => JSON::true, 'nticks' => 0, 'zerolinewidth' => 1, 'zeroline' => JSON::false, 'position' => 0, 'range' => [0, 29.1128165263158, ], 'dtick' => 5, 'showexponent' => 'all', 'showline' => JSON::false, 'linecolor' => '#000', 'type' => 'linear', 'linewidth' => 0.1, 'overlaying' => JSON::false, 'ticklen' => 5, 'rangemode' => 'normal', 'tickwidth' => 1, 'tickcolor' => '#000', 'title' => 'Length', 'autorange' => JSON::true, 'titlefont' => {'size' => 16, 'family' => '', 'color' => '', }, 'zerolinecolor' => '#000', 'gridwidth' => 1.9, }, 'funnelmode' => 'group', 'xaxis' => {'ticks' => '', 'autotick' => JSON::true, 'gridcolor' => 'rgb(255, 255, 255)', 'tickfont' => {'color' => '', 'family' => '', 'size' => 16, }, 'mirror' => JSON::true, 'anchor' => 'y', 'tickangle' => 0, 'domain' => [0, 1, ], 'showgrid' => JSON::true, 'exponentformat' => 'e', 'tick0' => 0, 'showticklabels' => JSON::true, 'range' => [-0.5, 2.5, ], 'nticks' => 0, 'zerolinewidth' => 1, 'zeroline' => JSON::false, 'position' => 0, 'showexponent' => 'all', 'dtick' => 1, 'showline' => JSON::false, 'type' => 'category', 'linecolor' => '#000', 'overlaying' => JSON::false, 'linewidth' => 0.1, 'ticklen' => 5, 'rangemode' => 'normal', 'titlefont' => {'size' => 16, 'family' => '', 'color' => '', }, 'autorange' => JSON::true, 'title' => 'Dose (mg)', 'tickwidth' => 1, 'tickcolor' => '#000', 'gridwidth' => 1.9, 'zerolinecolor' => '#000', }, }
); 

Chart::Plotly::show_plot($plot);
    
