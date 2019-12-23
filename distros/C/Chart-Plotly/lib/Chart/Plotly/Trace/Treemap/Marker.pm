package Chart::Plotly::Trace::Treemap::Marker;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Treemap::Marker::Colorbar;
use Chart::Plotly::Trace::Treemap::Marker::Line;
use Chart::Plotly::Trace::Treemap::Marker::Pad;

our $VERSION = '0.035';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace treemap.

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
      "Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `marker.colorscale`. Has an effect only if colorsis set to a numerical array. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has cauto => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not the color domain is computed with respect to the input data (here colors) or the bounds set in `marker.cmin` and `marker.cmax`  Has an effect only if colorsis set to a numerical array. Defaults to `false` when `marker.cmin` and `marker.cmax` are set by the user.",
);

has cmax => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the upper bound of the color domain. Has an effect only if colorsis set to a numerical array. Value should have the same units as colors and if set, `marker.cmin` must be set as well.",
);

has cmid => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the mid-point of the color domain by scaling `marker.cmin` and/or `marker.cmax` to be equidistant to this point. Has an effect only if colorsis set to a numerical array. Value should have the same units as colors. Has no effect when `marker.cauto` is `false`.",
);

has cmin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the lower bound of the color domain. Has an effect only if colorsis set to a numerical array. Value should have the same units as colors and if set, `marker.cmax` must be set as well.",
);

has coloraxis => (
    is => "rw",
    documentation =>
      "Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Treemap::Marker::Colorbar", );

has colors => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Sets the color of each sector of this trace. If not specified, the default trace color set is used to pick the sector colors.",
);

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale. Has an effect only if colorsis set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)'], [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`marker.cmin` and `marker.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.",
);

has colorssrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on plot.ly for  colors .",
);

has depthfade => (
    is => "rw",
    documentation =>
      "Determines if the sector colors are faded towards the background from the leaves up to the headers. This option is unavailable when a `colorscale` is present, defaults to false when `marker.colors` is set, but otherwise defaults to true. When set to *reversed*, the fading direction is inverted, that is the top elements within hierarchy are drawn with fully saturated colors while the leaves are faded towards the background color.",
);

has line => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Treemap::Marker::Line", );

has pad => ( is  => "rw",
             isa => "Maybe[HashRef]|Chart::Plotly::Trace::Treemap::Marker::Pad", );

has reversescale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Reverses the color mapping if true. Has an effect only if colorsis set to a numerical array. If true, `marker.cmin` will correspond to the last color in the array and `marker.cmax` will correspond to the first color.",
);

has showscale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not a colorbar is displayed for this trace. Has an effect only if colorsis set to a numerical array.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Treemap::Marker - This attribute is one of the possible options for the trace treemap.

=head1 VERSION

version 0.035

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use JSON;
 use Chart::Plotly::Trace::Treemap;
 
 # Example from https://github.com/plotly/plotly.js/blob/3004a9ac8300f8d8681ba2cdfb9833856a6f37fa/test/image/mocks/treemap_with-without_values.json
 my $trace1 = Chart::Plotly::Trace::Treemap->new({'name' => 'without values', 'domain' => {'x' => [0.01, 0.33, ], }, 'labels' => ['Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot', 'Golf', 'Hotel', 'India', 'Juliet', 'Kilo', 'Lima', 'Mike', 'November', 'Oscar', 'Papa', 'Quebec', 'Romeo', 'Sierra', 'Tango', 'Uniform', 'Victor', 'Whiskey', 'X ray', 'Yankee', 'Zulu', ], 'parents' => ['', 'Alpha', 'Alpha', 'Charlie', 'Charlie', 'Charlie', 'Foxtrot', 'Foxtrot', 'Foxtrot', 'Foxtrot', 'Juliet', 'Juliet', 'Juliet', 'Juliet', 'Juliet', 'Oscar', 'Oscar', 'Oscar', 'Oscar', 'Oscar', 'Oscar', 'Uniform', 'Uniform', 'Uniform', 'Uniform', 'Uniform', 'Uniform', ], 'hoverinfo' => 'all', 'level' => 'Oscar', 'textinfo' => 'label+value+percent parent+percent entry+percent root+text+current path', });
 
 my $plot = Chart::Plotly::Plot->new(
     traces => [$trace1, ],
     layout => 
         {'width' => 1500, 'height' => 600, 'annotations' => [{'xanchor' => 'center', 'y' => 0, 'x' => 0.17, 'showarrow' => JSON::false, 'text' => '<b>with counted leaves<br>', 'yanchor' => 'top', }, {'showarrow' => JSON::false, 'x' => 0.5, 'yanchor' => 'top', 'text' => '<b>with values and branchvalues: total<br>', 'xanchor' => 'center', 'y' => 0, }, {'y' => 0, 'xanchor' => 'center', 'yanchor' => 'top', 'text' => '<b>with values and branchvalues: remainder<br>', 'showarrow' => JSON::false, 'x' => 0.83, }, ], 'margin' => {'r' => 0, 't' => 50, 'b' => 25, 'l' => 0, }, 'shapes' => [{'x1' => 0.33, 'type' => 'rect', 'x0' => 0.01, 'y0' => 0, 'layer' => 'above', 'y1' => 1, }, {'y0' => 0, 'x0' => 0.34, 'x1' => 0.66, 'type' => 'rect', 'y1' => 1, 'layer' => 'above', }, {'y0' => 0, 'x0' => 0.67, 'x1' => 0.99, 'type' => 'rect', 'y1' => 1, 'layer' => 'above', }, ], }
 ); 
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace treemap.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#treemap>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * autocolorscale

Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `marker.colorscale`. Has an effect only if colorsis set to a numerical array. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * cauto

Determines whether or not the color domain is computed with respect to the input data (here colors) or the bounds set in `marker.cmin` and `marker.cmax`  Has an effect only if colorsis set to a numerical array. Defaults to `false` when `marker.cmin` and `marker.cmax` are set by the user.

=item * cmax

Sets the upper bound of the color domain. Has an effect only if colorsis set to a numerical array. Value should have the same units as colors and if set, `marker.cmin` must be set as well.

=item * cmid

Sets the mid-point of the color domain by scaling `marker.cmin` and/or `marker.cmax` to be equidistant to this point. Has an effect only if colorsis set to a numerical array. Value should have the same units as colors. Has no effect when `marker.cauto` is `false`.

=item * cmin

Sets the lower bound of the color domain. Has an effect only if colorsis set to a numerical array. Value should have the same units as colors and if set, `marker.cmax` must be set as well.

=item * coloraxis

Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.

=item * colorbar

=item * colors

Sets the color of each sector of this trace. If not specified, the default trace color set is used to pick the sector colors.

=item * colorscale

Sets the colorscale. Has an effect only if colorsis set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)'], [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`marker.cmin` and `marker.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.

=item * colorssrc

Sets the source reference on plot.ly for  colors .

=item * depthfade

Determines if the sector colors are faded towards the background from the leaves up to the headers. This option is unavailable when a `colorscale` is present, defaults to false when `marker.colors` is set, but otherwise defaults to true. When set to *reversed*, the fading direction is inverted, that is the top elements within hierarchy are drawn with fully saturated colors while the leaves are faded towards the background color.

=item * line

=item * pad

=item * reversescale

Reverses the color mapping if true. Has an effect only if colorsis set to a numerical array. If true, `marker.cmin` will correspond to the last color in the array and `marker.cmax` will correspond to the first color.

=item * showscale

Determines whether or not a colorbar is displayed for this trace. Has an effect only if colorsis set to a numerical array.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
