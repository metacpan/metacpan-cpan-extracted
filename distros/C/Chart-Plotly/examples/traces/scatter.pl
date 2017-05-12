use HTML::Show;
use Chart::Plotly;
use Chart::Plotly::Trace::Scatter;
my $scatter = Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] );

HTML::Show::show( Chart::Plotly::render_full_html( data => [$scatter] ) );

