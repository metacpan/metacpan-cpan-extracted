use Data::Table;
use Chart::Plotly qw(show_plot);

my $table = Data::Table::fromFile('morley.csv');

show_plot($table);
