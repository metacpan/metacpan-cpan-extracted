use HTML::Show;
use Chart::Plotly;
use Chart::Plotly::Trace::Histogram;
my $histogram = Chart::Plotly::Trace::Histogram->new( x => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ] );

HTML::Show::show( Chart::Plotly::render_full_html( data => [$histogram] ) );

