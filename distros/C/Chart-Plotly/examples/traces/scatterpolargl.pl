use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Scatterpolargl;
my $scatterpolargl = Chart::Plotly::Trace::Scatterpolargl->new(
    r          => [ 5, 4, 7, 8, 6 ],
    theta      => [ 0, 75, 134, 237, 307 ],
    mode       => "markers",
    marker     => {
        color   => "rgb(27,158,119)",
        size    => 15,
        line    => {
            color => "white"
        },
        opacity => 0.7
    },
    cliponaxis => 0
);

show_plot([ $scatterpolargl ]);

