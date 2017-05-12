use HTML::Show;
use Chart::Plotly;
use Chart::Plotly::Trace::Pie;
my @labels = ( "ants", "bees", "crickets", "dragonflies", "earwigs" );
my $pie = Chart::Plotly::Trace::Pie->new( labels => \@labels, values => [ map { int( rand() * 10 ) } @labels ] );

HTML::Show::show( Chart::Plotly::render_full_html( data => [$pie] ) );

