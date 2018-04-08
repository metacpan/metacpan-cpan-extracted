use Chart::Plotly::Trace::Scatter;
use Chart::Plotly::Plot;
use Chart::Plotly qw(show_plot);
use HTML::Show;

my $x = [1 .. 15];
my $y = [map {rand 10 } @$x];
my $scatter = Chart::Plotly::Trace::Scatter->new(x => $x, y => $y);
my $plot = Chart::Plotly::Plot->new();
$plot->add_trace($scatter);

show_plot($plot);

# This also works
# HTML::Show::show(Chart::Plotly::render_full_html(data => $plot));
# HTML::Show::show($plot->html);
