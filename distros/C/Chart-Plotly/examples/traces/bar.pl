use Chart::Plotly;
use Chart::Plotly::Trace::Bar;
use Chart::Plotly::Plot;
my $x = [ "apples", "bananas", "cherries" ];
my $sample1 = Chart::Plotly::Trace::Bar->new( x    => $x,
                                              y    => [ map { int( rand() * 10 ) } ( 1 .. ( scalar(@$x) ) ) ],
                                              name => "sample1"
);
my $sample2 = Chart::Plotly::Trace::Bar->new( x    => $x,
                                              y    => [ map { int( rand() * 10 ) } ( 1 .. ( scalar(@$x) ) ) ],
                                              name => "sample2"
);
my $sample3 = Chart::Plotly::Trace::Bar->new( x    => $x,
                                              y    => [ map { int( rand() * 10 ) } ( 1 .. ( scalar(@$x) ) ) ],
                                              name => "sample3"
);
my $plot = Chart::Plotly::Plot->new( traces => [ $sample1, $sample2, $sample3 ], layout => { barmode => 'group' } );
Chart::Plotly::show_plot($plot);

