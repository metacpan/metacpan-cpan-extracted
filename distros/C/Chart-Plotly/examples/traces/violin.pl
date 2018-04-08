use Chart::Plotly qw(show_plot);
use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Violin;
my $x = [ 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3 ];
my $violin1 = Chart::Plotly::Trace::Violin->new(
    x    => $x,
    y    => [ map {rand()} (1 .. (scalar(@$x))) ],
    name => "Violin1",
    box  => { visible => JSON::true }
);
my $violin2 = Chart::Plotly::Trace::Violin->new(
    x    => $x,
    y    => [ map {rand()} (1 .. (scalar(@$x))) ],
    name => "Violin2",
    box  => { visible => JSON::true }
);
my $violin_plot = Chart::Plotly::Plot->new(traces => [ $violin1, $violin2 ], layout => { violinmode => 'group' });

show_plot($violin_plot);

