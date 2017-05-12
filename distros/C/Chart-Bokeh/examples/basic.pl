use Chart::Bokeh qw(show_plot);

my $plot_data = {x => [0..10], y => [map {rand 10} 0..10]};

show_plot($plot_data);

