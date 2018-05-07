package Chart::Plotly::Trace::Bar::Marker::Line;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

our $VERSION = '0.019';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace bar.

sub TO_JSON {
    my $self       = shift;
    my $extra_args = $self->extra_args // {};
    my $meta       = $self->meta;
    my %hash       = %$self;
    for my $name ( sort keys %hash ) {
        my $attr = $meta->get_attribute($name);
        if ( defined $attr ) {
            my $value = $hash{$name};
            my $type  = $attr->type_constraint;
            if ( $type && $type->equals('Bool') ) {
                $hash{$name} = $value ? \1 : \0;
            }
        }
    }
    %hash = ( %hash, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has autocolorscale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `marker.line.color` is set to a numerical array. Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `marker.line.colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has cauto => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `marker.line.color` is set to a numerical array and `cmin`, `cmax` are set by the user. In this case, it controls whether the range of colors in `colorscale` is mapped to the range of values in the `color` array (`cauto: true`), or the `cmin`/`cmax` values (`cauto: false`). Defaults to `false` when `cmin`, `cmax` are set by the user.",
);

has cmax => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Has an effect only if `marker.line.color` is set to a numerical array. Sets the upper bound of the color domain. Value should be associated to the `marker.line.color` array index, and if set, `marker.line.cmin` must be set as well.",
);

has cmin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Has an effect only if `marker.line.color` is set to a numerical array. Sets the lower bound of the color domain. Value should be associated to the `marker.line.color` array index, and if set, `marker.line.cmax` must be set as well.",
);

has color => (
    is  => "rw",
    isa => "Maybe[ArrayRef]",
    documentation =>
      "Sets the marker.line color. It accepts either a specific color or an array of numbers that are mapped to the colorscale relative to the max and min values of the array or relative to `cmin` and `cmax` if set.",
);

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale and only has an effect if `marker.line.color` is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `marker.line.cmin` and `marker.line.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys, YlGnBu, Greens, YlOrRd, Bluered, RdBu, Reds, Blues, Picnic, Rainbow, Portland, Jet, Hot, Blackbody, Earth, Electric, Viridis, Cividis",
);

has colorsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  color .",
);

has reversescale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `marker.line.color` is set to a numerical array. Reverses the color mapping if true (`cmin` will correspond to the last color in the array and `cmax` will correspond to the first color).",
);

has width => ( is            => "rw",
               isa           => "Num|ArrayRef[Num]",
               documentation => "Sets the width (in px) of the lines bounding the marker points.",
);

has widthsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  width .",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Bar::Marker::Line - This attribute is one of the possible options for the trace bar.

=head1 VERSION

version 0.019

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

This attribute is part of the possible options for the trace bar.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#bar>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * autocolorscale

Has an effect only if `marker.line.color` is set to a numerical array. Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `marker.line.colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * cauto

Has an effect only if `marker.line.color` is set to a numerical array and `cmin`, `cmax` are set by the user. In this case, it controls whether the range of colors in `colorscale` is mapped to the range of values in the `color` array (`cauto: true`), or the `cmin`/`cmax` values (`cauto: false`). Defaults to `false` when `cmin`, `cmax` are set by the user.

=item * cmax

Has an effect only if `marker.line.color` is set to a numerical array. Sets the upper bound of the color domain. Value should be associated to the `marker.line.color` array index, and if set, `marker.line.cmin` must be set as well.

=item * cmin

Has an effect only if `marker.line.color` is set to a numerical array. Sets the lower bound of the color domain. Value should be associated to the `marker.line.color` array index, and if set, `marker.line.cmax` must be set as well.

=item * color

Sets the marker.line color. It accepts either a specific color or an array of numbers that are mapped to the colorscale relative to the max and min values of the array or relative to `cmin` and `cmax` if set.

=item * colorscale

Sets the colorscale and only has an effect if `marker.line.color` is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `marker.line.cmin` and `marker.line.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys, YlGnBu, Greens, YlOrRd, Bluered, RdBu, Reds, Blues, Picnic, Rainbow, Portland, Jet, Hot, Blackbody, Earth, Electric, Viridis, Cividis

=item * colorsrc

Sets the source reference on plot.ly for  color .

=item * reversescale

Has an effect only if `marker.line.color` is set to a numerical array. Reverses the color mapping if true (`cmin` will correspond to the last color in the array and `cmax` will correspond to the first color).

=item * width

Sets the width (in px) of the lines bounding the marker points.

=item * widthsrc

Sets the source reference on plot.ly for  width .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
