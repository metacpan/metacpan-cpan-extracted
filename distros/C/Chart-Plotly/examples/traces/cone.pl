use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Cone;

my $cone = Chart::Plotly::Trace::Cone->new(
                x => [1, 2],
                y => [1, 2],
                z => [1, 2],
                u => [1, 2],
                v => [1, 2],
                w => [1, 2]
);

show_plot([ $cone ]);

