package Chart::GGPlot::Theme::ElementTree;

# ABSTRACT: Definitions of theme elements

use Chart::GGPlot::Setup;
use Function::Parameters qw(classmethod);
use namespace::autoclean;

our $VERSION = '0.0007'; # VERSION

use parent qw(Chart::GGPlot::Params);

use Types::Standard qw(Any ArrayRef Enum HashRef InstanceOf Num Str);

use Chart::GGPlot::Theme::Defaults qw(theme_grey);
use Chart::GGPlot::Theme::Element::Functions qw(:all);
use Chart::GGPlot::Theme::ElementTree;

# Overrides Chart::GGPlot::Params behavior to support both "foo.bar" and
# "foo_bar" as element name.
classmethod transform_key ($key) {
    return ( $key =~ s/\./_/gr );
}


classmethod el_def ( $type, $inherit = [], $desc = '' ) {
    $inherit = Ref::Util::is_arrayref($inherit) ? $inherit : [ $inherit // () ];
    return {
        type        => $type,
        inherit     => $inherit,
        description => $desc,
    };
}


classmethod default_element_tree () {
    my $ElementLine = InstanceOf ["Chart::GGPlot::Theme::Element::Line"];
    my $ElementRect = InstanceOf ["Chart::GGPlot::Theme::Element::Rect"];
    my $ElementText = InstanceOf ["Chart::GGPlot::Theme::Element::Text"];

    #my $Margin      = InstanceOf ["Chart::GGPlot::Margin"];

    my $Character =
      ( ArrayRef [ ( Str | Num ) ] )->plus_coercions( Any, sub { [ $_, $_ ] } );

    my $TagPosition = (
        (
            Enum [
                qw(
                  topleft top topright
                  left right bottomleft
                  bottom bottomright
                  )
            ]
        ) | ( ArrayRef [Num] )->where( sub { @$_ == 2 } )
    )->plus_coercions(
        Str,
        sub {
            state $mapping;
            unless ($mapping) {
                $mapping = {};
                my @setup = (
                    [qw(bottom left)],  [qw(top left)],
                    [qw(bottom right)], [qw(top right)],
                );
                for my $item (@setup) {
                    my ( $a, $b ) = @$item;
                    my $just = "$a$b";
                    $mapping->{"$b$a"} =
                      $mapping->{"${a}_$b"} = $mapping->{"${b}_$a"} = $just;
                }
            }
            return ( $mapping->{$_} // $_ );
        }
    );

    # this is just to have something shorter than $class->el_def
    my $el_def = sub { $class->el_def(@_); };

    return $class->new(
        line       => &$el_def($ElementLine),
        rect       => &$el_def($ElementRect),
        text       => &$el_def($ElementText),
        title      => &$el_def( $ElementText, "text" ),
        axis_line  => &$el_def( $ElementLine, "line" ),
        axis_text  => &$el_def( $ElementText, "text" ),
        axis_title => &$el_def( $ElementText, "title" ),
        axis_ticks => &$el_def( $ElementLine, "line" ),

        #        legend_key_size  => &$el_def($Unit),
        panel_grid       => &$el_def( $ElementLine, "line" ),
        panel_grid_major => &$el_def( $ElementLine, "panel_grid" ),
        panel_grid_minor => &$el_def( $ElementLine, "panel_grid" ),
        strip_text       => &$el_def( $ElementText, "text" ),

        axis_line_x        => &$el_def( $ElementLine, "axis_line" ),
        axis_line_x_top    => &$el_def( $ElementLine, "axis_line_x" ),
        axis_line_x_bottom => &$el_def( $ElementLine, "axis_line_x" ),
        axis_line_y        => &$el_def( $ElementLine, "axis_line" ),
        axis_line_y_left   => &$el_def( $ElementLine, "axis_line_y" ),
        axis_line_y_right  => &$el_def( $ElementLine, "axis_line_y" ),
        axis_text_x        => &$el_def( $ElementText, "axis_text" ),
        axis_text_x_top    => &$el_def( $ElementText, "axis_text_x" ),
        axis_text_x_bottom => &$el_def( $ElementText, "axis_text_x" ),
        axis_text_y        => &$el_def( $ElementText, "axis_text" ),
        axis_text_y_left   => &$el_def( $ElementText, "axis_text_y" ),
        axis_text_y_right  => &$el_def( $ElementText, "axis_text_y" ),

        #        axis_ticks_length   => &$el_def($Unit),
        axis_ticks_x        => &$el_def( $ElementLine, "axis_ticks" ),
        axis_ticks_x_top    => &$el_def( $ElementLine, "axis_ticks_x" ),
        axis_ticks_x_bottom => &$el_def( $ElementLine, "axis_ticks_x" ),
        axis_ticks_y        => &$el_def( $ElementLine, "axis_ticks" ),
        axis_ticks_y_left   => &$el_def( $ElementLine, "axis_ticks_y" ),
        axis_ticks_y_right  => &$el_def( $ElementLine, "axis_ticks_y" ),
        axis_title_x        => &$el_def( $ElementText, "axis_title" ),
        axis_title_x_top    => &$el_def( $ElementText, "axis_title_x" ),
        axis_title_x_bottom => &$el_def( $ElementText, "axis_title_x" ),
        axis_title_y        => &$el_def( $ElementText, "axis_title" ),
        axis_title_y_left   => &$el_def( $ElementText, "axis_title_y" ),
        axis_title_y_right  => &$el_def( $ElementText, "axis_title_y" ),

        legend_background => &$el_def( $ElementRect, "rect" ),

        # legend_margin     => &$el_def($Margin),

        #        legend_spacing     => &$el_def($Unit),
        #        legend_spacing_x   => &$el_def( $Unit, "legend_spacing" ),
        #        legend_spacing_y   => &$el_def( $Unit, "legend_spacing" ),
        legend_key => &$el_def( $ElementRect, "rect" ),

        #        legend_key_height  => &$el_def( $Unit, "legend_key_size" ),
        #        legend_key_width   => &$el_def( $Unit, "legend_key_size" ),
        legend_text        => &$el_def( $ElementText, "text" ),
        legend_text_align  => &$el_def($Character),
        legend_title       => &$el_def( $ElementText, "title" ),
        legend_title_align => &$el_def($Character),
        legend_position  => &$el_def($Character),  # Need to also accept numbers
        legend_direction => &$el_def($Character),
        legend_justification => &$el_def($Character),
        legend_box           => &$el_def($Character),
        legend_box_just      => &$el_def($Character),

        #        legend_box_margin     => &$el_def($Margin),
        legend_box_background => &$el_def( $ElementRect, "rect" ),

        #        legend_box_spacing    => &$el_def($Unit),

        panel_background => &$el_def( $ElementRect, "rect" ),
        panel_border     => &$el_def( $ElementRect, "rect" ),

        #        panel_spacing    => &$el_def($Unit),
        #        panel_spacing_x  => &$el_def( $Unit,         "panel_spacing" ),
        #        panel_spacing_y  => &$el_def( $Unit,         "panel_spacing" ),
        panel_grid_major_x => &$el_def( $ElementLine, "panel_grid_major" ),
        panel_grid_major_y => &$el_def( $ElementLine, "panel_grid_major" ),
        panel_grid_minor_x => &$el_def( $ElementLine, "panel_grid_minor" ),
        panel_grid_minor_y => &$el_def( $ElementLine, "panel_grid_minor" ),
        panel_ontop        => &$el_def(Any),

        strip_background   => &$el_def( $ElementRect, "rect" ),
        strip_background_x => &$el_def( $ElementRect, "strip_background" ),
        strip_background_y => &$el_def( $ElementRect, "strip_background" ),
        strip_text_x       => &$el_def( $ElementText, "strip_text" ),
        strip_text_y       => &$el_def( $ElementText, "strip_text" ),
        strip_placement    => &$el_def($Character),
        strip_placement_x  => &$el_def( $Character,   "strip_placement" ),
        strip_placement_y  => &$el_def( $Character,   "strip_placement" ),

        #        strip_switch_pad_grid => &$el_def($Unit),
        #        strip_switch_pad_wrap => &$el_def($Unit),

        plot_background   => &$el_def( $ElementRect, "rect" ),
        plot_title        => &$el_def( $ElementText, "title" ),
        plot_subtitle     => &$el_def( $ElementText, "title" ),
        plot_caption      => &$el_def( $ElementText, "title" ),
        plot_tag          => &$el_def( $ElementText, "title" ),
        plot_tag_position => &$el_def($TagPosition),

        #        plot_margin       => &$el_def($Margin),

        aspect_ratio => &$el_def($Character),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Theme::ElementTree - Definitions of theme elements

=head1 VERSION

version 0.0007

=head1 DESCRIPTION

An element tree is a specification of a set of elements usable by themes
in the Chart::GGPlot system. For each element its value type is defined.
Also an elment can inherit other elements, so that in case of an absent
element Chart::GGPlot knows to look for values from its parent elements.

A consumer of Chart::GGPlot::Theme shall follow the element tree and
specify values to elements. A Chart::GGPlot::Backend consumer, depend on
its implementation, shall support (at least a subset of) theme elements
defined in the element tree.

This module provides a default element tree, and normally you do not need
to define your own element tree.

=head1 CLASS METHODS

=head2 el_def

This method defines a theme element.

    my $href = el_def($type, $inherits=[], $desc='')

=over 4

=item *

$type: A Type::Tiny type.

=item *

$inherits: An element can inherit other elements.

=item *

$desc: Description of the element.

=back

=head2 default_element_tree

Returns an object of Chart::GGPlot::ElementTree.

    my $element_tree = Chart::GGPlot::ElementTree->default_element_tree();

=head1 SEE ALSO

L<Chart::GGPlot::Theme::Defaults>,
L<Chart::GGPlot::Theme::Element>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
