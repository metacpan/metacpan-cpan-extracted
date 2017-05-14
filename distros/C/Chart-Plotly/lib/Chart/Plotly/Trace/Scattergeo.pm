package Chart::Plotly::Trace::Scattergeo;
use Moose;

use Chart::Plotly::Trace::Attribute::Line;
use Chart::Plotly::Trace::Attribute::Marker;

our $VERSION = '0.012';    # VERSION

sub TO_JSON {
    my $self = shift;
    my %hash = %$self;
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has connectgaps => (
           is  => 'rw',
           isa => "Bool",
           documentation =>
             "Determines whether or not gaps (i.e. {nan} or missing values) in the provided data arrays are connected.",
);

has fill => (
    is => 'rw',
    documentation =>
      "Sets the area to fill with a solid color. Use with `fillcolor` if not *none*. *toself* connects the endpoints of the trace (or each segment of the trace if it has gaps) into a closed shape.",
);

has fillcolor => (
    is => 'rw',
    documentation =>
      "Sets the fill color. Defaults to a half-transparent variant of the line color, marker color, or marker line color, whichever is available.",
);

has hoverinfo => (
    is => 'rw',
    documentation =>
      "Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.",
);

has lat => ( is            => 'rw',
             documentation => "Sets the latitude coordinates (in degrees North).", );

has line => ( is  => 'rw',
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Line" );

has locationmode => (
         is            => 'rw',
         documentation => "Determines the set of locations used to match entries in `locations` to regions on the map.",
);

has locations => (
    is => 'rw',
    documentation =>
      "Sets the coordinates via location IDs or names. Coordinates correspond to the centroid of each location given. See `locationmode` for more info.",
);

has lon => ( is            => 'rw',
             documentation => "Sets the longitude coordinates (in degrees East).", );

has marker => ( is  => 'rw',
                isa => "Maybe[HashRef]|Maybe[ArrayRef]|Chart::Plotly::Trace::Attribute::Marker" );

has mode => (
    is => 'rw',
    documentation =>
      "Determines the drawing mode for this scatter trace. If the provided `mode` includes *text* then the `text` elements appear at the coordinates. Otherwise, the `text` elements appear on hover. If there are less than 20 points, then the default is *lines+markers*. Otherwise, *lines*.",
);

has text => (
    is  => 'rw',
    isa => "Maybe[ArrayRef]|Str",
    documentation =>
      "Sets text elements associated with each (lon,lat) pair or item in `locations`. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (lon,lat) or `locations` coordinates.",
);

has textfont => ( is            => 'rw',
                  documentation => "Sets the text font.", );

has textposition => (
                   is            => 'rw',
                   documentation => "Sets the positions of the `text` elements with respects to the (x,y) coordinates.",
);

has name => ( is            => 'rw',
              isa           => "Str",
              documentation => "Sets the trace name",
);

sub type {
    my @components = split( /::/, __PACKAGE__ );
    return lc( $components[-1] );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Scattergeo

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Scattergeo;
 use Chart::Plotly::Trace::Attribute::Marker;
 my $scattergeo = Chart::Plotly::Trace::Scattergeo->new(
     mode => 'markers+text',
     text => [ 'Mount Everest', 'K2',      'Kangchenjunga', 'Lhotse', 'Makalu', 'Cho Oyu',
               'Dhaulagiri I',  'Manaslu', 'Nanga Parbat',  'Annapurna I'
     ],
     lon => [ 86.9252777778, 76.5133333333, 88.1475,       86.9330555556, 87.0888888889, 86.6608333333,
              83.4930555556, 84.5597222222, 74.5891666667, 83.8202777778
     ],
     lat => [ 27.9880555556, 35.8813888889, 27.7033333333, 27.9616666667, 27.8897222222, 28.0941666667,
              28.6966666667, 28.55,         35.2372222222, 28.5955555556
     ],
     name => "Highest mountains
         https://en.wikipedia.org/wiki/List_of_highest_mountains_on_Earth",
     textposition => [ 'top right',
                       'top center',
                       'bottom center',
                       'bottom left',
                       'right',
                       'left',
                       'left',
                       'right',
                       'bottom center',
                       'top center'
     ],
     marker => Chart::Plotly::Trace::Attribute::Marker->new(
                                                    size  => 7,
                                                    color => [
                                                        '#bebada', '#fdb462', '#fb8072', '#d9d9d9', '#bc80bd', '#b3de69',
                                                        '#8dd3c7', '#80b1d3', '#fccde5', '#ffffb3'
                                                    ]
     )
 );
 
 my $plot = Chart::Plotly::Plot->new( traces => [$scattergeo],
                                      layout => { title => 'Mountains',
                                                  geo   => { scope => 'asia', }
                                      }
 );
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#scattergeo>

=head1 NAME 

Chart::Plotly::Trace::Scattergeo

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * connectgaps

Determines whether or not gaps (i.e. {nan} or missing values) in the provided data arrays are connected.

=item * fill

Sets the area to fill with a solid color. Use with `fillcolor` if not *none*. *toself* connects the endpoints of the trace (or each segment of the trace if it has gaps) into a closed shape.

=item * fillcolor

Sets the fill color. Defaults to a half-transparent variant of the line color, marker color, or marker line color, whichever is available.

=item * hoverinfo

Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.

=item * lat

Sets the latitude coordinates (in degrees North).

=item * line

=item * locationmode

Determines the set of locations used to match entries in `locations` to regions on the map.

=item * locations

Sets the coordinates via location IDs or names. Coordinates correspond to the centroid of each location given. See `locationmode` for more info.

=item * lon

Sets the longitude coordinates (in degrees East).

=item * marker

=item * mode

Determines the drawing mode for this scatter trace. If the provided `mode` includes *text* then the `text` elements appear at the coordinates. Otherwise, the `text` elements appear on hover. If there are less than 20 points, then the default is *lines+markers*. Otherwise, *lines*.

=item * text

Sets text elements associated with each (lon,lat) pair or item in `locations`. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (lon,lat) or `locations` coordinates.

=item * textfont

Sets the text font.

=item * textposition

Sets the positions of the `text` elements with respects to the (x,y) coordinates.

=item * name

Sets the trace name

=back

=head2 type

Trace type.

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
