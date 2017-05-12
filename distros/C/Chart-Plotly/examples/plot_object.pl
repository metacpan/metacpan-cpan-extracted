use Chart::Plotly::Trace::Scatter;
use Chart::Plotly::Plot;
use HTML::Show;

my $x = [1 .. 15];
my $y = [map {rand 10 } @$x];
my $scatter = Chart::Plotly::Trace::Scatter->new(x => $x, y => $y);
my $plot = Chart::Plotly::Plot->new();
$plot->add_trace($scatter);

HTML::Show::show($plot->html);

# This also works
# HTML::Show::show(Chart::Plotly::render_full_html(data => $plot));
