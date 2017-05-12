use Chart::Plotly;
use Chart::Plotly::Trace::Box;
use Chart::Plotly::Plot;

my $x = [ 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3 ];
my $box1 = Chart::Plotly::Trace::Box->new( x => $x, y => [ map { rand() } ( 1 .. ( scalar(@$x) ) ) ], name => "box1" );
my $box2 = Chart::Plotly::Trace::Box->new( x => $x, y => [ map { rand() } ( 1 .. ( scalar(@$x) ) ) ], name => "box2" );
my $plot = Chart::Plotly::Plot->new( traces => [ $box1, $box2 ], layout => { boxmode => 'group' } );

Chart::Plotly::show_plot($plot);

