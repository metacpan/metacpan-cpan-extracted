package Chart::GGPlot::Backend;

# ABSTRACT: Role for backend classes for Chart::GGPlot 

use Chart::GGPlot::Role;
use namespace::autoclean;

our $VERSION = '0.0001'; # VERSION

use Chart::GGPlot::Layout;
use Chart::GGPlot::Built;


requires 'show';
requires 'save';


classmethod build($ggplot) {
    # A convient function for debug logging.
    state $debug_data = sub {
        my ($dataframes, $step) = @_;
        $log->debug( "Backend::build : data $step :\n"
              . join( "\n", map { $_->string } @$dataframes ) )
          if ( $log->is_debug );
    };

    my $plot = $ggplot->clone();

    if ( $plot->layers->isempty ) {
        $plot->geom_blank();
    }

    my $layers = $plot->layers;

    # if layer has data, then use layer's data, else use plot's data.
    my $layer_data = $layers->map( sub { $_->layer_data( $plot->data ) } );

    my $scales = $plot->scales;

    my $layout = Chart::GGPlot::Layout->new(
        facet => $plot->facet,
        coord => $plot->coordinates
    );
    my $data = $layout->setup( $layer_data, $plot->data );

    # Apply function to layer and matching data
    my $by_layer = fun($f) {
        return [ 0 .. $#$data ]
          ->map( sub { &$f( $layers->at($_), $data->[$_] ) } );
    };

    # Compute aesthetics to produce data with generalised variable names
    $data = &$by_layer( fun( $l, $d ) { $l->compute_aesthetics( $d, $plot ) } );
    $debug_data->($data, 'after compute_aesthetics()');

    $data = $data->map(sub { $scales->transform_df($_); });
    $debug_data->($data, 'after transform_df()');

    my $scale_x = sub { $scales->get_scales('x') };
    my $scale_y = sub { $scales->get_scales('y') };
    $layout->train_position( $data, $scale_x->(), $scale_y->() );

    # keep raw column on first time of map_position()
    $data = $layout->map_position($data, true);
    $debug_data->($data, 'after map_position()');

    # Apply and map statistics
    $data = &$by_layer( fun( $l, $d ) { $l->compute_statistic( $d, $layout ) }
    );

    $debug_data->($data, 'after compute_statistic()');
    $data = &$by_layer( fun( $l, $d ) { $l->map_statistic( $d, $plot ) } );
    $debug_data->($data, 'after map_statistic()');

    # Make sure missing (but required) aesthetics are added
    $scales->add_missing( [qw(x y)] );

    # Reparameterise geoms from (e.g.) y and width to ymin and ymax
    $data = &$by_layer( fun( $l, $d ) { $l->compute_geom_1($d); } );
    $debug_data->($data, 'after compute_geom_1()');

    # Apply position adjustments
    $data = &$by_layer( fun( $l, $d ) { $l->compute_position( $d, $layout ); }
    );
    $debug_data->($data, 'after compute_position()');

    # Reset position scales, then re-train and map.  This ensures that facets
    # have control over the range of a plot: is it generated from what is
    # displayed, or does it include the range of underlying data
    $layout->reset_scales();

    $layout->train_position( $data, $scale_x->(), $scale_y->() );
    $layout->setup_panel_params();
    $data = $layout->map_position($data);
    $debug_data->($data, 'after map_position() again');

    # Train and map non-position scales
    my $npscales = $scales->non_position_scales();
    if ( $npscales->length > 0 ) {
        $data->map(sub { $npscales->train_df($_) });
        $data = $data->map(sub { $npscales->map_df($_) });
        $debug_data->($data, 'after mapping non-position scales');
    }

    $data = &$by_layer( fun( $l, $d ) { $l->compute_geom_2($d) } );
    $debug_data->($data, 'after compute_geom_2()');
    $data = &$by_layer( fun( $l, $d ) { $l->finish_statistics($d) } );
    $debug_data->($data, 'after finish_statistics()');

    $data = $layout->finish_data($data);
    $debug_data->($data, 'after finish_data()');

    # build guides
    $plot->guides->build($scales, labels => $plot->labels);

    return Chart::GGPlot::Built->new(
        data   => $data,
        layout => $layout,
        plot   => $plot
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend - Role for backend classes for Chart::GGPlot 

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This module is the role for Chart::GGPlot backend classes. 

=head1 CLASS METHODS

=head2 build

    build($ggplot)

This method takes a Chart::GGPlot object, and performs all steps necessary
to produce a Chart::GGPlot::Built object that can be rendered.

=head1 METHODS

=head2 show

    show($ggplot, HashRef $opts={})

Show the plot (like in web browser).

=head2 save

    save($ggplot, $filename, HashRef $opts={})

Export the plot to a static image file.

=head1 SEE ALSO

L<Chart::GGPlot>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
