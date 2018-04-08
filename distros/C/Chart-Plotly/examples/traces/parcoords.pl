use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Parcoords;
# Example data from: https://plot.ly/javascript/parallel-coordinates-plot/#adding-dimensions
my $parcoords = Chart::Plotly::Trace::Parcoords->new(
 line=> {
    color=> 'blue'
  },
  
  dimensions=> [{
    range=> [1, 5],
    constraintrange=> [1, 2],
    label=> 'A',
    values=> [1,4]
  }, {    
    range=> [1,5],
    label=> 'B',
    values=> [3,1.5],
    tickvals=> [1.5,3,4.5]
  }, {
    range=> [1, 5],
    label=> 'C',
    values=> [2,4],
    tickvals=> [1,2,4,5],
    ticktext=> ['text 1','text 2','text 4','text 5']
  }, {
    range=> [1, 5],
    label=> 'D',
    values=> [4,2]
  }]
);

show_plot([ $parcoords ]);

