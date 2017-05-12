use HTML::Show;
use Chart::Plotly;
use Chart::Plotly::Trace::Scatterternary;
my $scatterternary = Chart::Plotly::Trace::Scatterternary->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] );

HTML::Show::show( Chart::Plotly::render_full_html( data => [$scatterternary] ) );

