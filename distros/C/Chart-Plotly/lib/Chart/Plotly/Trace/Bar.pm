package Chart::Plotly::Trace::Bar;
use Moose;

use Chart::Plotly::Trace::Attribute::Error_x;
use Chart::Plotly::Trace::Attribute::Error_y;
use Chart::Plotly::Trace::Attribute::Marker;

our $VERSION = '0.011';    # VERSION

sub TO_JSON {
    my $self = shift;
    my %hash = %$self;
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has base => (
    is  => 'rw',
    isa => "Any",
    documentation =>
      "Sets where the bar base is drawn (in position axis units). In *stack* or *relative* barmode, traces that set *base* will be excluded and drawn in *overlay* mode instead.",
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

has insidetextfont => ( is            => 'rw',
                        documentation => "Sets the font used for `text` lying inside the bar.", );

has marker => ( is  => 'rw',
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Marker" );

has offset => (
    is  => 'rw',
    isa => "Num",
    documentation =>
      "Shifts the position where the bar is drawn (in position axis units). In *group* barmode, traces that set *offset* will be excluded and drawn in *overlay* mode instead.",
);

has orientation => (
    is => 'rw',
    documentation =>
      "Sets the orientation of the bars. With *v* (*h*), the value of the each bar spans along the vertical (horizontal).",
);

has outsidetextfont => ( is            => 'rw',
                         documentation => "Sets the font used for `text` lying outside the bar.", );

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
                  documentation => "Sets the font used for `text`.", );

has textposition => (
    is => 'rw',
    documentation =>
      "Specifies the location of the `text`. *inside* positions `text` inside, next to the bar end (rotated and scaled if needed). *outside* positions `text` outside, next to the bar end (scaled if needed). *auto* positions `text` inside or outside so that `text` size is maximized.",
);

has width => ( is            => 'rw',
               isa           => "Num",
               documentation => "Sets the bar width (in position axis units).",
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

Chart::Plotly::Trace::Bar

=head1 VERSION

version 0.011

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#bar>

=head1 NAME 

Chart::Plotly::Trace::Bar

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * base

Sets where the bar base is drawn (in position axis units). In *stack* or *relative* barmode, traces that set *base* will be excluded and drawn in *overlay* mode instead.

=item * dx

Sets the x coordinate step. See `x0` for more info.

=item * dy

Sets the y coordinate step. See `y0` for more info.

=item * error_x

=item * error_y

=item * insidetextfont

Sets the font used for `text` lying inside the bar.

=item * marker

=item * offset

Shifts the position where the bar is drawn (in position axis units). In *group* barmode, traces that set *offset* will be excluded and drawn in *overlay* mode instead.

=item * orientation

Sets the orientation of the bars. With *v* (*h*), the value of the each bar spans along the vertical (horizontal).

=item * outsidetextfont

Sets the font used for `text` lying outside the bar.

=item * r

For polar chart only.Sets the radial coordinates.

=item * t

For polar chart only.Sets the angular coordinates.

=item * text

Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates.

=item * textfont

Sets the font used for `text`.

=item * textposition

Specifies the location of the `text`. *inside* positions `text` inside, next to the bar end (rotated and scaled if needed). *outside* positions `text` outside, next to the bar end (scaled if needed). *auto* positions `text` inside or outside so that `text` size is maximized.

=item * width

Sets the bar width (in position axis units).

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
