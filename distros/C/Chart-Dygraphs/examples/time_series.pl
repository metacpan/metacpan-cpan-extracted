use Chart::Dygraphs qw(show_plot);
use DateTime;

my $start_date = DateTime->now(time_zone => 'UTC')->truncate(to => 'hour');
my $time_series_data = [map {[$start_date->add(hours => 1)->clone(), rand($_)]} 1..1000];

show_plot($time_series_data);


