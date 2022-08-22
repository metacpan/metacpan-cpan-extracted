use Chart::Plotly;
use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Scattersmith;

my $smith = Chart::Plotly::Trace::Scattersmith->new(imag=>[0.5, 1, 2, 3], real=>[0.5, 1, 2, 3]);
my $plot = Chart::Plotly::Plot->new(traces => [$smith]);

Chart::Plotly::show_plot($plot);

