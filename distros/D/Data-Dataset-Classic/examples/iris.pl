use Data::Dataset::Classic::Iris;
use Chart::Plotly qw(show_plot);

my $iris = Data::Dataset::Classic::Iris::get(as => 'Data::Table');

show_plot($iris);

