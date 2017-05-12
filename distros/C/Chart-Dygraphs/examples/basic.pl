use Chart::Dygraphs qw(show_plot);

my $data = [map {[$_, rand($_)]} 1..10 ];
show_plot($data);
