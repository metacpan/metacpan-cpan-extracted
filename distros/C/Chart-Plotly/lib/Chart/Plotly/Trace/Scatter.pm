package Chart::Plotly::Trace::Scatter;
use Moose;

use Chart::Plotly::Trace::Attribute::Error_x;
use Chart::Plotly::Trace::Attribute::Error_y;
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

has dx => ( is            => 'rw',
            isa           => "Num",
            documentation => "Sets the x coordinate step. See `x0` for more info.",
);

has dy => ( is            => 'rw',
            isa           => "Num",
            documentation => "Sets the y coordinate step. See `y0` for more info.",
);

has error_x => ( is  => 'rw',
                 isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Error_x" );

has error_y => ( is  => 'rw',
                 isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Error_y" );

has fill => (
    is => 'rw',
    documentation =>
      "Sets the area to fill with a solid color. Use with `fillcolor` if not *none*. *tozerox* and *tozeroy* fill to x=0 and y=0 respectively. *tonextx* and *tonexty* fill between the endpoints of this trace and the endpoints of the trace before it, connecting those endpoints with straight lines (to make a stacked area graph); if there is no trace before it, they behave like *tozerox* and *tozeroy*. *toself* connects the endpoints of the trace (or each segment of the trace if it has gaps) into a closed shape. *tonext* fills the space between two traces if one completely encloses the other (eg consecutive contour lines), and behaves like *toself* if there is no trace before it. *tonext* should not be used if one trace does not enclose the other.",
);

has fillcolor => (
    is => 'rw',
    documentation =>
      "Sets the fill color. Defaults to a half-transparent variant of the line color, marker color, or marker line color, whichever is available.",
);

has hoveron => (
    is => 'rw',
    documentation =>
      "Do the hover effects highlight individual points (markers or line points) or do they highlight filled regions? If the fill is *toself* or *tonext* and there are no markers or text, then the default is *fills*, otherwise it is *points*.",
);

has ids => ( is            => 'rw',
             documentation => "A list of keys for object constancy of data points during animation", );

has line => ( is  => 'rw',
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Line" );

has marker => ( is  => 'rw',
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Marker" );

has mode => (
    is => 'rw',
    documentation =>
      "Determines the drawing mode for this scatter trace. If the provided `mode` includes *text* then the `text` elements appear at the coordinates. Otherwise, the `text` elements appear on hover. If there are less than 20 points, then the default is *lines+markers*. Otherwise, *lines*.",
);

has r => ( is            => 'rw',
           documentation => "For polar chart only.Sets the radial coordinates.", );

has t => ( is            => 'rw',
           documentation => "For polar chart only.Sets the angular coordinates.", );

has text => (
    is  => 'rw',
    isa => "Maybe[ArrayRef]|Str",
    documentation =>
      "Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates.",
);

has textfont => ( is            => 'rw',
                  documentation => "Sets the text font.", );

has textposition => (
                   is            => 'rw',
                   documentation => "Sets the positions of the `text` elements with respects to the (x,y) coordinates.",
);

has x => ( is            => 'rw',
           documentation => "Sets the x coordinates.", );

has x0 => (
    is  => 'rw',
    isa => "Any",
    documentation =>
      "Alternate to `x`. Builds a linear space of x coordinates. Use with `dx` where `x0` is the starting coordinate and `dx` the step.",
);

has y => ( is            => 'rw',
           documentation => "Sets the y coordinates.", );

has y0 => (
    is  => 'rw',
    isa => "Any",
    documentation =>
      "Alternate to `y`. Builds a linear space of y coordinates. Use with `dy` where `y0` is the starting coordinate and `dy` the step.",
);

has name => ( is            => 'rw',
              isa           => "Str",
              documentation => "Sets the trace name",
);

has xaxis => (
    is  => 'rw',
    isa => "Str",
    documentation =>
      "Sets a reference between this trace's x coordinates and a 2D cartesian x axis. If \"x\" (the default value), the x coordinates refer to `layout.xaxis`. If \"x2\", the x coordinates refer to `layout.xaxis2`, and so on. ",
);

has yaxis => (
    is  => 'rw',
    isa => "Str",
    documentation =>
      "Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If \"y\" (the default value), the y coordinates refer to `layout.yaxis`. If \"y2\", the y coordinates refer to `layout.yaxis2`, and so on. ",
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

Chart::Plotly::Trace::Scatter

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 use HTML::Show;
 use Chart::Plotly;
 use Chart::Plotly::Trace::Scatter;
 my $scatter = Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] );
 
 HTML::Show::show( Chart::Plotly::render_full_html( data => [$scatter] ) );

=head1 DESCRIPTION

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#scatter>

=head1 NAME 

Chart::Plotly::Trace::Scatter

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

=item * dx

Sets the x coordinate step. See `x0` for more info.

=item * dy

Sets the y coordinate step. See `y0` for more info.

=item * error_x

=item * error_y

=item * fill

Sets the area to fill with a solid color. Use with `fillcolor` if not *none*. *tozerox* and *tozeroy* fill to x=0 and y=0 respectively. *tonextx* and *tonexty* fill between the endpoints of this trace and the endpoints of the trace before it, connecting those endpoints with straight lines (to make a stacked area graph); if there is no trace before it, they behave like *tozerox* and *tozeroy*. *toself* connects the endpoints of the trace (or each segment of the trace if it has gaps) into a closed shape. *tonext* fills the space between two traces if one completely encloses the other (eg consecutive contour lines), and behaves like *toself* if there is no trace before it. *tonext* should not be used if one trace does not enclose the other.

=item * fillcolor

Sets the fill color. Defaults to a half-transparent variant of the line color, marker color, or marker line color, whichever is available.

=item * hoveron

Do the hover effects highlight individual points (markers or line points) or do they highlight filled regions? If the fill is *toself* or *tonext* and there are no markers or text, then the default is *fills*, otherwise it is *points*.

=item * ids

A list of keys for object constancy of data points during animation

=item * line

=item * marker

=item * mode

Determines the drawing mode for this scatter trace. If the provided `mode` includes *text* then the `text` elements appear at the coordinates. Otherwise, the `text` elements appear on hover. If there are less than 20 points, then the default is *lines+markers*. Otherwise, *lines*.

=item * r

For polar chart only.Sets the radial coordinates.

=item * t

For polar chart only.Sets the angular coordinates.

=item * text

Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates.

=item * textfont

Sets the text font.

=item * textposition

Sets the positions of the `text` elements with respects to the (x,y) coordinates.

=item * x

Sets the x coordinates.

=item * x0

Alternate to `x`. Builds a linear space of x coordinates. Use with `dx` where `x0` is the starting coordinate and `dx` the step.

=item * y

Sets the y coordinates.

=item * y0

Alternate to `y`. Builds a linear space of y coordinates. Use with `dy` where `y0` is the starting coordinate and `dy` the step.

=item * name

Sets the trace name

=item * xaxis

Sets a reference between this trace's x coordinates and a 2D cartesian x axis. If "x" (the default value), the x coordinates refer to `layout.xaxis`. If "x2", the x coordinates refer to `layout.xaxis2`, and so on. 

=item * yaxis

Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If "y" (the default value), the y coordinates refer to `layout.yaxis`. If "y2", the y coordinates refer to `layout.yaxis2`, and so on. 

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
