package Chart::GGPlot::Backend::Plotly::Geom::Boxplot;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Boxplot

use Chart::GGPlot::Class qw(:pdl);

our $VERSION = '0.002000'; # VERSION

with qw(Chart::GGPlot::Backend::Plotly::Geom);

use JSON;
use List::AllUtils qw(max pairmap);
use Module::Load;

use Chart::GGPlot::Backend::Plotly::Util qw(to_px to_rgb pdl_to_plotly);
use Chart::GGPlot::Geom::Boxplot;
use Chart::GGPlot::Geom::Point;

classmethod split_on () { [qw(color fill size)] }

classmethod prepare_data ($data, $prestats_data, @rest) {
    my @join_on_columns = qw(PANEL group);
    my @prestats_data_columns = map { $prestats_data->at($_) } @join_on_columns;

    my $prestats_y = $prestats_data->at('y');
    my %prestats_y_grouped;    # PANEL;group => $y_data
    for my $ridx ( 0 .. $prestats_data->nrow - 1 ) {
        my @key_values =
          map { $_->at($ridx) } @prestats_data_columns;
        my $k = join( $;, @key_values );
        $prestats_y_grouped{$k} //= [];
        push @{ $prestats_y_grouped{$k} }, $prestats_y->at($ridx);
    }

    my @data_y = map {
        my $ridx       = $_;
        my @key_values = map { $data->at($_)->at($ridx) } @join_on_columns;
        my $k          = join( $;, @key_values );
        pdl( $prestats_y_grouped{$k} );
    } ( 0 .. $data->nrow - 1 );

    $data->set( 'y', PDL::SV->new( \@data_y ) );
    return $data;
}

classmethod to_traces ($df, $params, $plot) {
    load Chart::Plotly::Trace::Box;
    load Chart::Plotly::Trace::Box::Line;
    load Chart::Plotly::Trace::Box::Marker;
    load Chart::Plotly::Trace::Box::Marker::Line;

    my $geom_point_default_aes = Chart::GGPlot::Geom::Point->default_aes;
    my $marker_opacity         = $params->at('outlier_alpha')
      // $df->at('alpha')->setbadtoval(1)->at(0);

    # If neither outlier_color or outlier_fill are defined, they use box color.
    my $params_outlier_color = $params->at('outlier_color');
    my $params_outlier_fill  = $params->at('outlier_fill');
    my $marker_color;
    my $marker_fill;
    if ( !$params_outlier_color and !$params_outlier_fill ) {
        $marker_color = $marker_fill = $df->at('color')->at(0);
    }
    $marker_color = to_rgb( $marker_color // $params_outlier_color
          // $df->at('color')->at(0) );
    $marker_fill =
      to_rgb( $marker_fill // $params_outlier_fill // $df->at('color')->at(0) );

    my $marker_size = do {
        my $s = $params->at('outlier_size');
        $s ? max( to_px($s), 2 ) : 2;
    };
    my $marker_stroke = to_px( $params->at('outlier_stroke')
          // $geom_point_default_aes->at('stroke')->at(0) );
    my $marker = Chart::Plotly::Trace::Box::Marker->new(
        opacity      => $marker_opacity,
        outliercolor => $marker_fill,
        color        => $marker_fill,
        size         => $marker_size,
        line         => Chart::Plotly::Trace::Box::Marker::Line->new(
            width => $marker_stroke,
            color => $marker_color,
        ),
    );

    my $line = Chart::Plotly::Trace::Box::Line->new(
        color => to_rgb( $df->at('color') )->at(0),
        width => max( to_px( $df->at('size')->at(0) ), 2 ),
    );
    my $fillcolor = to_rgb( $df->at('fill'), $df->at('alpha') )->at(0);

    my $data_y = $df->at('y');
    my $y = [ map { $data_y->at($_)->unpdl; } ( 0 .. $data_y->length - 1 ) ];
    my $data_x = $df->at('x');
    my $x =
      [ map { ( $data_x->at($_) ) x @{ $y->[$_] } }
          ( 0 .. $data_x->length - 1 ) ];
    $y = [ map { @$_ } @$y ];    # flatten y data

    my $flip = $plot->coordinates->DOES('Chart::GGPlot::Coord::Flip');
    my $trace = Chart::Plotly::Trace::Box->new(
        x          => $x,
        y          => $y,
        type       => 'box',
        fillcolor  => $fillcolor,
        marker     => $marker,
        line       => $line,
        notched    => ( $params->at('notch') ? JSON::true : JSON::false ),
        notchwidth => $params->at('notchwidth'),
        hoverinfo  => ( $flip ? 'x' : 'y' ),
        hoveron    => $class->hover_on,

        # plotly defaults to 'suspectedoutliers' to show outliers and
        # suspected in different styles.
        # we use 'outliers' here to align with ggplot2 behavior.
        boxpoints => 'outliers',
    );
    return [ $class->_adjust_trace_for_flip($trace, $plot) ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Boxplot - Chart::GGPlot's Plotly implementation for Geom::Boxplot

=head1 VERSION

version 0.002000

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Boxplot>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
