use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Sankey;
# Example data from: https://plot.ly/javascript/sankey-diagram/#basic-sankey-diagram
my $sankey = Chart::Plotly::Trace::Sankey->new(
    orientation => "h",
    node        => {
        pad       => 15,
        thickness => 30,
        line      => {
            color => "black",
            width => 0.5
        },
        label     => [ "A1", "A2", "B1", "B2", "C1", "C2" ],
        color     => [ "blue", "blue", "blue", "blue", "blue", "blue" ]
    },

    link        => {
        source => [ 0, 1, 0, 2, 3, 3 ],
        target => [ 2, 3, 3, 4, 4, 5 ],
        value  => [ 8, 4, 2, 8, 4, 2 ]
    }
);

show_plot([ $sankey ]);

