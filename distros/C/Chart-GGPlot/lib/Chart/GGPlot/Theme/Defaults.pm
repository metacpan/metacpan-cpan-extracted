package Chart::GGPlot::Theme::Defaults;

# ABSTRACT: Pre-defined themes

use Chart::GGPlot::Setup;

our $VERSION = '0.0016'; # VERSION

use Chart::GGPlot::Theme;
use Chart::GGPlot::Theme::Element::Functions qw(:all);

use parent qw(Exporter::Tiny);

my @theme_funcs = qw(
  theme_grey theme_gray theme_bw
  theme_linedraw theme_light theme_dark
  theme_minimal theme_classic theme_void
);
our @EXPORT_OK   = @theme_funcs;
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@theme_funcs,
);


fun theme_grey (:$base_size=11, :$base_family="",
                :$base_line_size=$base_size/22,
                :$base_rect_size=$base_size/22) {

    # The half-line (base-fontsize / 2) sets up the basic vertical
    # rhythm of the theme.
    my $half_line = $base_size / 2;

    return Chart::GGPlot::Theme->new(
        line => element_line(
            color    => 'black',
            size     => $base_line_size,
            linetype => 1,
            lineend  => "butt",
        ),
        rect => element_rect(
            fill     => 'white',
            color    => 'black',
            size => $base_rect_size,
            linetype => 1,
        ),
        text => element_text(
            family     => $base_family,
            face       => 'plain',
            color      => 'black',
            size       => $base_size,
            lineheight => 0.9,
            hjust      => 0.5,
            vjust      => 0.5,
            angle      => 0,
#            margin     => margin(),
        ),
        axis_line   => element_blank(),
        axis_line_x => undef,
        axis_line_y => undef,
        axis_text   => element_text( size => rel(0.8), color => "grey30" ),
        axis_text_x => element_text(
#            margin => margin( t => 0.8 * $half_line / 2 ),
            vjust  => 1
        ),
        axis_text_x_top => element_text(
#            margin => margin( b => 0.8 * $half_line / 2 ),
            vjust  => 0
        ),
        axis_text_y => element_text(
#            margin => margin( r => 0.8 * $half_line / 2 ),
            hjust  => 1
        ),
        axis_text_y_right => element_text(
#            margin => margin( l => 0.8 * $half_line / 2 ),
            hjust  => 0
        ),
        axis_ticks        => element_line( color => "grey20" ),
#        axis_ticks_length => unit( $half_line / 2, "pt" ),
        axis_title_x      => element_text(
#            margin => margin( t => $half_line / 2 ),
            vjust  => 1
        ),
        axis_title_x_top => element_text(
#            margin => margin( b => $half_line / 2 ),
            vjust  => 0
        ),
        axis_title_y => element_text(
            angle  => 90,
#            margin => margin( r => $half_line / 2 ),
            vjust  => 1
        ),
        axis_title_y_right => element_text(
            angle  => -90,
#            margin => margin( l => $half_line / 2 ),
            vjust  => 0
        ),

        # TODO: What would this NA behave?
        #legend_background =>  element_rect(color = NA),
        legend_background => element_rect(),
#        legend_spacing    => unit( 2 * $half_line, "pt" ),
#        legend_spacing_x  => undef,
#        legend_spacing_y  => undef,
#        legend_margin =>
#          margin( t => $half_line, r => $half_line, b => $half_line, l => $half_line ),
        legend_key        => element_rect( fill => "grey95", color => "white" ),
#        legend_key_size   => unit( 1.2, "lines" ),
#        legend_key_height => undef,
#        legend_key_width  => undef,
        legend_text       => element_text( size => rel(0.8) ),
        legend_text_align => undef,
        legend_title      => element_text( hjust => 0 ),
        legend_title_align    => undef,
        legend_position       => "right",
        legend_direction      => undef,
        legend_justification  => "center",
        legend_box            => undef,
#        legend_box_margin     => margin(),
        legend_box_background => element_blank(),
#        legend_box_spacing    => unit( 2 * $half_line, "pt" ),

        # TODO: What would this NA behave?
        #panel_background =>  element_rect(fill => "grey92", color => NA),
        panel_background => element_rect( fill => "grey92" ),
        panel_border     => element_blank(),
        panel_grid       => element_line( color => "white" ),
        panel_grid_minor => element_line( size => rel(0.5) ),
#        panel_spacing    => unit( $half_line, "pt" ),
#        panel_spacing_x  => undef,
#        panel_spacing_y  => undef,
        panel_ontop      => false,

        #strip_background =   element_rect(fill => "grey85", color => NA),
        strip_background => element_rect( fill => "grey85" ),
        strip_text => element_text(
            color  => "grey10",
            size   => rel(0.8),
#            margin => margin(
#                t => 0.8 * $half_line,
#                r => 0.8 * $half_line,
#                b => 0.8 * $half_line,
#                l => 0.8 * $half_line
#            )
        ),
        strip_text_x          => undef,
        strip_text_y          => element_text( angle => -90 ),
        strip_placement       => "inside",
        strip_placement_x     => undef,
        strip_placement_y     => undef,
#        strip_switch_pad_grid => unit( $half_line / 2, "pt" ),
#        strip_switch_pad_wrap => unit( $half_line / 2, "pt" ),

        plot_background => element_rect( color => "white" ),
        plot_title      => element_text(                     # font size "large"
            size   => rel(1.2),
            hjust  => 0,
            vjust  => 1,
#            margin => margin( b => $half_line )
        ),
        plot_subtitle => element_text(    # font size "regular"
            hjust  => 0,
            vjust  => 1,
#            margin => margin( b => $half_line )
        ),
        plot_caption => element_text(     # font size "small"
            size   => rel(0.8),
            hjust  => 1,
            vjust  => 1,
#            margin => margin( t => $half_line )
        ),
        plot_tag => element_text(
            size  => rel(1.2),
            hjust => 0.5,
            vjust => 0.5
        ),
        plot_tag_position => 'topleft',
#        plot_margin => margin( t => $half_line, r => $half_line, b => $half_line, l => $half_line ),

        complete => true,
    );
}

*theme_gray = \&theme_grey;


fun theme_bw (%rest) {

    # Starts with theme_grey and then modify some parts
    return theme_grey(%rest)->replace(
        Chart::GGPlot::Theme->new(

            # white background and dark border
            panel_background => element_rect( fill  => "white" ),
            panel_border     => element_rect( color => "grey20" ),

            # make gridlines dark, same contrast with white as in theme_grey
            panel_grid       => element_line( color => "grey92" ),
            panel_grid_minor => element_line( size  => rel(0.5) ),

            # contour strips to match panel contour
            strip_background =>
              element_rect( fill => "grey85", color => "grey20" ),

            # match legend key to background
            legend_key => element_rect( fill => "white" ),

            complete => true,
        )
    );
}


fun theme_linedraw ( :$base_size = 11, %rest ) {
    my $half_line = $base_size / 2;

    # Starts with theme_bw and then modify some parts
    # = replace all greys with pure black or white
    theme_bw( base_size => $base_size, %rest )->replace(
        Chart::GGPlot::Theme->new(

            # black text and ticks on the axes
            axis_text  => element_text( color => "black", size => rel(0.8) ),
            axis_ticks => element_line( color => "black", size => rel(0.5) ),

            # NB: match the *visual* thickness of axis ticks to the panel border
            #     0.5 clipped looks like 0.25

            # pure black panel border and grid lines, but thinner
            panel_border => element_rect( color => "black", size => rel(1) ),
            panel_grid   => element_line( color => "black" ),
            panel_grid_major => element_line( size => rel(0.1) ),
            panel_grid_minor => element_line( size => rel(0.05) ),

            # strips with black background and white text
            strip_background => element_rect( fill => "black" ),
            strip_text       => element_text(
                color  => "white",
                size   => rel(0.8),
#                margin => margin(
#                    t => 0.8 * $half_line,
#                    r => 0.8 * $half_line,
#                    b => 0.8 * $half_line,
#                    l => 0.8 * $half_line
#                ),

            ),
            complete => true,
        )
    );
}


fun theme_light (:$base_size = 11, %rest) {
    my $half_line = $base_size / 2;

    # Starts with theme_grey and then modify some parts
    theme_grey( base_size => $base_size, %rest )->replace(
        Chart::GGPlot::Theme->new(

            # white panel with light grey border
            panel_background => element_rect( fill => "white" ),
            panel_border => element_rect( color => "grey70", size => rel(1) ),

            # light grey, thinner gridlines
            # => make them slightly darker to keep acceptable contrast
            panel_grid       => element_line( color => "grey87" ),
            panel_grid_major => element_line( size  => rel(0.5) ),
            panel_grid_minor => element_line( size  => rel(0.25) ),

            # match axes ticks thickness to gridlines and color to panel border
            axis_ticks => element_line( color => "grey70", size => rel(0.5) ),

            # match legend key to panel.background
            legend_key => element_rect( fill => "white" ),

         # dark strips with light text (inverse contrast compared to theme_grey)
            strip_background => element_rect( fill => "grey70" ),
            strip_text       => element_text(
                color  => "white",
                size   => rel(0.8),
#                margin => margin(
#                    t => 0.8 * $half_line,
#                    r => 0.8 * $half_line,
#                    b => 0.8 * $half_line,
#                    l => 0.8 * $half_line
#                )
            ),

            complete => true,
        )
    );
}


fun theme_dark (:$base_size = 11, %rest) {
    my $half_line = $base_size / 2;

    # Starts with theme_grey and then modify some parts
    return theme_grey( base_size => $base_size, %rest )->replace(
        Chart::GGPlot::Theme->new(

            # dark panel
            panel_background => element_rect( fill => "grey50" ),

  # inverse grid lines contrast compared to theme_grey
  # make them thinner and try to keep the same visual contrast as in theme_light
            panel_grid       => element_line( color => "grey42" ),
            panel_grid_major => element_line( size   => rel(0.5) ),
            panel_grid_minor => element_line( size   => rel(0.25) ),

            # match axes ticks thickness to gridlines
            axis_ticks => element_line( color => "grey20", size => rel(0.5) ),

            # match legend key to panel.background
            legend_key => element_rect( fill => "grey50" ),

         # dark strips with light text (inverse contrast compared to theme_grey)
            strip_background => element_rect( fill => "grey15" ),
            strip_text       => element_text(
                color => "grey90",
                size   => rel(0.8),
#                margin => margin(
#                    t => 0.8 * $half_line,
#                    r => 0.8 * $half_line,
#                    b => 0.8 * $half_line,
#                    l => 0.8 * $half_line
#                )
            ),

            complete => true,
        )
    );
}


fun theme_minimal (:$base_size=11, :$base_family="",
               :$base_line_size=$base_size/22,
               :$base_rect_size=$base_size/22) {

    # Starts with theme_bw and remove most parts
    return theme_bw(
        base_size      => $base_size,
        base_family    => $base_family,
        base_line_size => $base_line_size,
        base_rect_size => $base_rect_size
    )->replace(
        Chart::GGPlot::Theme->new(
            axis_ticks        => element_blank(),
            legend_background => element_blank(),
            legend_key        => element_blank(),
            panel_background  => element_blank(),
            panel_border      => element_blank(),
            strip_background  => element_blank(),
            plot_background   => element_blank(),

            complete => true,
        )
    );
}


fun theme_classic (%rest) {
    return theme_bw(%rest)->replace(
        Chart::GGPlot::Theme->new(

            # no background and no grid
            panel_border     => element_blank(),
            panel_grid_major => element_blank(),
            panel_grid_minor => element_blank(),

            # show axes
            axis_line => element_line( color => "black", size => rel(1) ),

            # match legend key to panel.background
            legend_key => element_blank(),

            # simple, black and white strips
            strip_background => element_rect(
                fill  => "white",
                color => "black",
                size  => rel(2)
            ),

            # NB: size is 1 but clipped, it looks like the 0.5 of the axes

            complete => true,
        )
    );
}


fun theme_void (:$base_size=11, :$base_family="",
                :$base_line_size=$base_size / 22,
                :$base_rect_size=$base_size / 22) {
    my $half_line = $base_size / 2;

    # Only keep indispensable text: legend and plot titles
    return Chart::GGPlot::Theme->new(
        line => element_blank(),
        rect => element_blank(),
        text => element_text(
            family     => $base_family,
            face       => "plain",
            color      => "black",
            size       => $base_size,
            lineheight => 0.9,
            hjust      => 0.5,
            vjust      => 0.5,
            angle      => 0,
#            margin     => margin()
        ),
        axis_text             => element_blank(),
        axis_title            => element_blank(),
#        axis_ticks_length     => unit( 0, "pt" ),
        legend_box            => undef,
#        legend_key_size       => unit( 1.2, "lines" ),
        legend_position       => "right",
        legend_text           => element_text( size => rel(0.8) ),
        legend_title          => element_text( hjust => 0 ),
        strip_text            => element_text( size => rel(0.8) ),
#        strip_switch_pad_grid => unit( $half_line / 2, "pt" ),
#        strip_switch_pad_wrap => unit( $half_line / 2, "pt" ),
        panel_ontop           => false,
#        panel_spacing         => unit( $half_line, "pt" ),
#        plot_margin           => margin(unit => "lines"),
        plot_title            => element_text(
            size   => rel(1.2),
            hjust  => 0,
            vjust  => 1,
#            margin => margin( t => $half_line )
        ),
        plot_subtitle => element_text(
            hjust  => 0,
            vjust  => 1,
#            margin => margin( t => $half_line )
        ),
        plot_caption => element_text(
            size   => rel(0.8),
            hjust  => 1,
            vjust  => 1,
#            margin => margin( t => $half_line )
        ),
        plot_tag => element_text(
            size  => rel(1.2),
            hjust => 0.5,
            vjust => 0.5
        ),
        plot_tag_position => 'topleft',

        complete => true,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Theme::Defaults - Pre-defined themes

=head1 VERSION

version 0.0016

=head1 SYNOPSIS

    use Chart::GGPlot::Theme::Defaults qw(:all);
    
    my $theme = theme_grey();

=head1 DESCRIPTION

Some predefined themes for the Chart::GGPlot library.

=head1 FUNCTIONS

=head2 theme_grey

    theme_grey(:$base_size=11, :$base_family="",
        :$base_line_size=$base_size / 22, :$base_rect_size=$base_size / 22)

The signature ggplot2 theme with a grey background and white gridlines.

=head2 theme_gray

This is same as the C<theme_grey()> method.

=head2 theme_bw

    theme_bw(:$base_size=11, :$base_family="",
        :$base_line_size=$base_size / 22, :$base_rect_size=$base_size / 22)

The classic dark-on-light ggplot2 theme.

=head2 theme_linedraw

    theme_linedraw(:$base_size=11, :$base_family="",
        :$base_line_size=$base_size / 22, :$base_rect_size=$base_size / 22)

A theme with only black lines of various widths on white backgrounds,
reminiscent of a line drawings.

=head2 theme_light

    theme_light(:$base_size=11, :$base_family="",
        :$base_line_size=$base_size / 22, :$base_rect_size=$base_size / 22)

A theme similar to C<theme_linedraw> but with light grey lines and axes,
to direct more attention towards the data.

=head2 theme_dark

    theme_dark(:$base_size=11, :$base_family="",
        :$base_line_size=$base_size / 22, :$base_rect_size=$base_size / 22)

The dark cousin of C<theme_light>, with similar line sizes but a dark
background. Useful to make thin colored lines pop out.

=head2 theme_minimal

    theme_minimal(:$base_size=11, :$base_family="",
        :$base_line_size=$base_size / 22, :$base_rect_size=$base_size / 22)

A minimalistic theme with no background annotations.

=head2 theme_classic

    theme_classic(:$base_size=11, :$base_family="",
        :$base_line_size=$base_size / 22, :$base_rect_size=$base_size / 22)

A classic-looking theme, with x and y axis lines and no gridlines.

=head2 theme_void

    theme_void(:$base_size=11, :$base_family="",
        :$base_line_size=$base_size / 22, :$base_rect_size=$base_size / 22)

A completely empyt theme.

=head1 SEE ALSO

L<Chart::GGPlot::Theme>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
