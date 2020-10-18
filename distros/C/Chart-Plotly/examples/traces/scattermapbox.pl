use Chart::Plotly;
use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Scattermapbox;
use Chart::Plotly::Trace::Scattermapbox::Marker;
my $mapbox_access_token =
  'Insert your access token here';
my $scattermapbox = Chart::Plotly::Trace::Scattermapbox->new(
                mode => 'markers',
                text => [ "The coffee bar",
                          "Bistro Bohem", "Black Cat", "Snap", "Columbia Heights Coffee",
                          "Azi's Cafe", "Blind Dog Cafe",
                          "Le Caprice", "Filter", "Peregrine", "Tryst", "The Coupe", "Big Bear Cafe"
                ],
                lon => [ '-77.02827', '-77.02013', '-77.03155', '-77.04227', '-77.02854',  '-77.02419',
                         '-77.02518', '-77.03304', '-77.04509', '-76.99656', '-77.042438', '-77.02821',
                         '-77.01239'
                ],
                lat => [ '38.91427', '38.91538', '38.91458', '38.92239', '38.93222', '38.90842', '38.91931', '38.93260',
                         '38.91368', '38.88516', '38.921894', '38.93206', '38.91275'
                ],
                marker => Chart::Plotly::Trace::Scattermapbox::Marker->new( size => 9 ),
);
my $plot = Chart::Plotly::Plot->new( traces => [$scattermapbox],
                                     layout => { autosize  => JSON::true,
                                                 hovermode => 'closest',
                                                 mapbox    => {
                                                             style       => 'open-street-map',
                                                             #accesstoken => $mapbox_access_token,
                                                             bearing     => 0,
                                                             center      => {
                                                                         lat => 38.92,
                                                                         lon => -77.07
                                                             },
                                                             pitch => 0,
                                                             zoom  => 10
                                                 }
                                     }
);
Chart::Plotly::show_plot($plot);

