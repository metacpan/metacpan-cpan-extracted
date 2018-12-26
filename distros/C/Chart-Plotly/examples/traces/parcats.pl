use Chart::Plotly;
use Chart::Plotly::Trace::Parcats;
use Chart::Plotly::Plot;

# Example from https://github.com/plotly/plotly.js/blob/7b751009fc9804272316f0bb539ed0386c0858bd/test/image/mocks/parcats_bundled.json

my $trace = Chart::Plotly::Trace::Parcats->new( bundlecolors => 1,
                                                dimensions   => [
                                                           { label  => 'One',
                                                             values => [ (1) x 2, 2, 1, 2, (1) x 2, 2, 1 ]
                                                           },
                                                           { label  => 'Two',
                                                             values => [ 'A', 'B', 'A', 'B', ('C') x 2, 'A', 'B', 'C' ]
                                                           },
                                                           { label  => 'Three',
                                                             values => [ (11) x 9 ]
                                                           }
                                                ],
                                                domain => { x => [ 0.125, 0.625 ],
                                                            y => [ 0.25,  0.75 ]
                                                },
                                                line => { color => [ (0) x 2, (1) x 2, 0, 1, (0) x 3 ] }
);

my $plot = Chart::Plotly::Plot->new( traces => [$trace],
                                     layout => { height => 602,
                                                 margin => { b => 40,
                                                             l => 40,
                                                             r => 40,
                                                             t => 50
                                                 },
                                                 width => 592
                                     }
);

Chart::Plotly::show_plot($plot);
