package Chart::Plotly::Trace::Scattermapbox;
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

has lon => ( is            => 'rw',
             documentation => "Sets the longitude coordinates (in degrees East).", );

has marker => ( is  => 'rw',
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Marker" );

has mode => (
    is => 'rw',
    documentation =>
      "Determines the drawing mode for this scatter trace. If the provided `mode` includes *text* then the `text` elements appear at the coordinates. Otherwise, the `text` elements appear on hover.",
);

has text => (
    is  => 'rw',
    isa => "Maybe[ArrayRef]|Str",
    documentation =>
      "Sets text elements associated with each (lon,lat) pair If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (lon,lat) coordinates.",
);

has textfont => ( is            => 'rw',
                  documentation => "Sets the icon text font. Has an effect only when `type` is set to *symbol*.", );

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

Chart::Plotly::Trace::Scattermapbox

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Scattermapbox;
 use Chart::Plotly::Trace::Attribute::Marker;
 my $mapbox_access_token =
   'pk.eyJ1IjoiY2hlbHNlYXBsb3RseSIsImEiOiJjaXFqeXVzdDkwMHFrZnRtOGtlMGtwcGs4In0.SLidkdBMEap9POJGIe1eGw';
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
                 marker => Chart::Plotly::Trace::Attribute::Marker->new( size => 9 ),
 );
 my $plot = Chart::Plotly::Plot->new( traces => [$scattermapbox],
                                      layout => { autosize  => 'True',
                                                  hovermode => 'closest',
                                                  mapbox    => {
                                                              accesstoken => $mapbox_access_token,
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

=head1 DESCRIPTION

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#scattermapbox>

=head1 NAME 

Chart::Plotly::Trace::Scattermapbox

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

=item * lon

Sets the longitude coordinates (in degrees East).

=item * marker

=item * mode

Determines the drawing mode for this scatter trace. If the provided `mode` includes *text* then the `text` elements appear at the coordinates. Otherwise, the `text` elements appear on hover.

=item * text

Sets text elements associated with each (lon,lat) pair If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (lon,lat) coordinates.

=item * textfont

Sets the icon text font. Has an effect only when `type` is set to *symbol*.

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
