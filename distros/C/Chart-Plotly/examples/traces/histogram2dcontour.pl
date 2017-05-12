use HTML::Show;
use Chart::Plotly;
use Chart::Plotly::Trace::Histogram2dcontour;
my $histogram2dcontour =
  Chart::Plotly::Trace::Histogram2dcontour->new( x => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ],
                                                 y => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ] );

HTML::Show::show( Chart::Plotly::render_full_html( data => [$histogram2dcontour] ) );

