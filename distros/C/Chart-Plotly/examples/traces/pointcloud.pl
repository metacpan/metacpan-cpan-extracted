use HTML::Show;
use Chart::Plotly;
use Chart::Plotly::Trace::Pointcloud;
my $pointcloud = Chart::Plotly::Trace::Pointcloud->new( x => [ 1 .. 100000 ], y => [ map { rand() } ( 1 .. 100000 ) ] );

HTML::Show::show( Chart::Plotly::render_full_html( data => [$pointcloud] ) );

