package Chart::Plotly::Trace::Treemap::Hoverlabel::Font;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

our $VERSION = '0.042';    # VERSION

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

has color => ( is  => "rw",
               isa => "Str|ArrayRef[Str]", );

has colorsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on Chart Studio Cloud for `color`.",
);

has description => ( is      => "ro",
                     default => "Sets the font used in hover labels.", );

has family => (
    is            => "rw",
    isa           => "Str|ArrayRef[Str]",
    documentation =>
      "HTML font family - the typeface that will be applied by the web browser. The web browser will only be able to apply a font if it is available on the system which it operates. Provide multiple font families, separated by commas, to indicate the preference in which to apply fonts if they aren't available on the system. The Chart Studio Cloud (at https://chart-studio.plotly.com or on-premise) generates images on a server, where only a select number of fonts are installed and supported. These include *Arial*, *Balto*, *Courier New*, *Droid Sans*,, *Droid Serif*, *Droid Sans Mono*, *Gravitas One*, *Old Standard TT*, *Open Sans*, *Overpass*, *PT Sans Narrow*, *Raleway*, *Times New Roman*.",
);

has familysrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on Chart Studio Cloud for `family`.",
);

has size => ( is  => "rw",
              isa => "Num|ArrayRef[Num]", );

has sizesrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on Chart Studio Cloud for `size`.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Treemap::Hoverlabel::Font - This attribute is one of the possible options for the trace treemap.

=head1 VERSION

version 0.042

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

=item * color

=item * colorsrc

Sets the source reference on Chart Studio Cloud for `color`.

=item * description

=item * family

HTML font family - the typeface that will be applied by the web browser. The web browser will only be able to apply a font if it is available on the system which it operates. Provide multiple font families, separated by commas, to indicate the preference in which to apply fonts if they aren't available on the system. The Chart Studio Cloud (at https://chart-studio.plotly.com or on-premise) generates images on a server, where only a select number of fonts are installed and supported. These include *Arial*, *Balto*, *Courier New*, *Droid Sans*,, *Droid Serif*, *Droid Sans Mono*, *Gravitas One*, *Old Standard TT*, *Open Sans*, *Overpass*, *PT Sans Narrow*, *Raleway*, *Times New Roman*.

=item * familysrc

Sets the source reference on Chart Studio Cloud for `family`.

=item * size

=item * sizesrc

Sets the source reference on Chart Studio Cloud for `size`.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
