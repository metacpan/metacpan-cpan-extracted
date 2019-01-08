use Chart::Plotly::Trace::Scatter;
use Chart::Plotly::Plot;
use HTML::Show;

my $x = [1 .. 15];
my $y = [map {rand 10 } @$x];
my $scatter = Chart::Plotly::Trace::Scatter->new(x => $x, y => $y);
my $plot = Chart::Plotly::Plot->new();
$plot->add_trace($scatter);

HTML::Show::show($plot->html(load_plotly_using_script_tag => 'module_dist'));
