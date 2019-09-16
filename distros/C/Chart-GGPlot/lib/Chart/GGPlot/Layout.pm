package Chart::GGPlot::Layout;

# ABSTRACT: Layout

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0007'; # VERSION

use Data::Frame::Types qw(DataFrame);
use List::AllUtils qw(pairwise reduce);
use PDL::Primitive qw(which);
use Types::PDL qw(Piddle1D);
use Types::Standard qw(ArrayRef InstanceOf HashRef Maybe);

use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Coord::Functions qw(:all);
use Chart::GGPlot::Facet::Functions qw(:all);
use Chart::GGPlot::Util qw(:all);


has coord => ( is => 'ro', isa => Coord, default => sub { coord_cartesian() } );
has facet => ( is => 'ro', isa => Facet, default => sub { facet_null() } );
has [qw(coord_params facet_params)] => (
    is       => 'rw',
    isa      => GGParams,
    coerce   => 1,
    init_arg => undef
);

has layout => ( is => 'rw', isa => DataFrame, init_arg => undef );

has [qw(panel_scales_x panel_scales_y)] => (
    is  => 'rw',
    isa => Maybe [ArrayRef]
);
has panel_params => ( is => 'rwp', isa => ArrayRef [HashRef] );

method setup (ArrayRef $data, $plot_data=Data::Frame->new()) {
    $data = [ $plot_data, @$data ];

    $self->facet_params(
        $self->facet->setup_params( $data, $self->facet->params ) );

    #$self->facet_params->plot_env($plot_env);
    $data = $self->facet->setup_data( $data, $self->facet_params );

    $self->coord_params( $self->coord->setup_params($data) );
    $data = $self->coord->setup_data( $data, $self->coord_params );

    $self->layout(
        $self->facet->compute_layout( $data, $self->facet->params ) );
    $self->layout(
        $self->coord->setup_layout( $self->layout, $self->coord_params ) );
    $self->_check_layout( $self->layout );

    # Add panel coordinates to the data for each layer
    shift @$data;
    $data = $data->map(
        sub {
            $self->facet->map_data( $_, $self->layout, $self->facet_params );
        }
    );

    return $data;
}

method _check_layout ($layout_df) {
    my @columns = qw(PANEL SCALE_X SCALE_Y);
    if ( List::AllUtils::all { $layout_df->exists($_) } @columns ) {
        return;
    }
    die "Facet layout has bad format. It must contain columns: "
      . join( ', ', map { "'$_'" } @columns );
}


method train_position ($data, $x_scale, $y_scale) {
    my $layout = $self->layout;
    unless ( defined $self->panel_scales_x ) {
        $self->panel_scales_x(
            $self->facet->init_scales( $layout, $self->facet_params,
                x_scale => $x_scale )->at('x')
        );
    }
    unless ( defined $self->panel_scales_y ) {
        $self->panel_scales_y(
            $self->facet->init_scales( $layout, $self->facet_params,
                y_scale => $y_scale )->at('y')
        );
    }

    return $self->facet->train_scales(
        $data, $layout, $self->facet_params,
        x_scales => $self->panel_scales_x,
        y_scales => $self->panel_scales_y
    );
}

method map_position (ArrayRef $data, $keep_raw_column=false) {
    my $layout = $self->layout;

    return $data->map(
        sub {
            my ($layer_data) = @_;

            my $match_id =
              match( $layer_data->at('PANEL'), $layout->at('PANEL') );

            my $do_axis = sub {
                my ($axis) = @_;

                my $column_name  = "SCALE_" . uc($axis);
                my $panel_scales = "panel_scales_" . lc($axis);

                my $vars =
                  $self->$panel_scales->at(0)->aesthetics->intersect( $layer_data->names );
                my $scale = $layout->at($column_name)->slice($match_id);
                my $new_data =
                  $self->scale_apply( $layer_data, $vars, "map_to_limits", $scale,
                    $self->$panel_scales );

                for my $var (@$vars) {

                    if ($keep_raw_column) {
                        my $colname_raw = "${var}_raw";
                        unless ( $layer_data->exists($colname_raw) ) {
                            $layer_data->set(
                                $colname_raw => $layer_data->at($var) );
                        }
                    }
                    $layer_data->set( $var => $new_data->{$var} );
                }
            };

            &$do_axis('x') if defined $self->panel_scales_x;
            &$do_axis('y') if defined $self->panel_scales_y;

            return $layer_data;
        }
    );
}

method reset_scales () {
    return unless $self->facet->shrink;
    if ( defined $self->panel_scales_x ) {
        $self->panel_scales_x->map( sub { $_->reset() } );
    }
    if ( defined $self->panel_scales_y ) {
        $self->panel_scales_y->map( sub { $_->reset() } );
    }
}

method finish_data ($data) {
    return $data->map(
        sub {
            $self->facet->finish_data(
                $_, $self->layout, $self->facet_params,
                x_scales => $self->panel_scales_x,
                y_scales => $self->panel_scales_y,
            );
        }
    );
}

method get_scales ($i) {
    my $this_panel =
      $self->layout->select_rows( which( $self->layout->at('PANEL') == $i ) );
    my $href = {
        x => $self->panel_scales_x->at( $this_panel->at('SCALE_X')->at(0) ),
        (
            defined $self->panel_scales_y
            ? (
                y => $self->panel_scales_y->at(
                    $this_panel->at('SCALE_Y')->at(0)
                )
              )
            : ()
        ),
    };
}

method setup_panel_params () {
    $self->coord->modify_scales( $self->panel_scales_x, $self->panel_scales_y );

    my $scales_x =
      $self->panel_scales_x->slice( $self->layout->at('SCALE_X')->unpdl );
    my $scales_y =
      $self->panel_scales_y->slice( $self->layout->at('SCALE_Y')->unpdl );

    my @params = pairwise {
        $self->coord->setup_panel_params( $a, $b, $self->coord_params );
    } @$scales_x, @$scales_y;
    $self->_set_panel_params( \@params );
}

fun _xylabel ($axis) {
    my $panel_scales = "panel_scales_${axis}";

    return method($labels) {
        my $scale0 = $self->$panel_scales->at(0);
        my $scale1 = $self->$panel_scales->at(1);
        my ( $primary, $secondary );
        $primary = $scale0->make_title( $scale0->name // $labels->at($axis) );
        if ( $scale1 and $scale1->secondary_axis ) {
            $secondary = $scale1->sec_name // $labels->at("sec_${axis}");
            $secondary = $primary if ( $secondary->is_derived );
            $secondary = $scale1->make_sec_title($secondary);
        }
        return { primary => $primary, secondary => $secondary };
    };
}
*xlabel = _xylabel('x');
*ylabel = _xylabel('y');

# Apply scale method to multiple variables in a data set.
# Returns a hash ref of { var => piddle }
classmethod scale_apply ($data, $vars, $method,
                         Piddle1D $scale_id, ArrayRef $scales) {
    return if ( $vars->length == 0 );
    return if ( $data->nrow == 0 );

    die if ( $scale_id->nbad );

    my $n = $scales->length;
    my $scale_indices = $class->_split_indices( $scale_id, $n );
    my $scale_indices_flattened =
      ( reduce { $a->glue( 0, $b ) } @$scale_indices )->qsorti;
    return {
        $vars->map(
            fun($var)
            {
                my $pieces = [ 0 .. $n - 1 ]->map(
                    sub {
                        # if $method is 'train', $scale is just trained here
                        my $scale = $scales->at($_);
                        $scale->$method(
                            $data->at($var)->slice( $scale_indices->[$_] ) );
                    }
                );
                $pieces = $pieces->[0]->glue( 0, @$pieces[ 1 .. $#$pieces ] );

                # Join pieces back together, if necessary
                if ( $pieces->length ) {
                    return ( $var => $pieces->slice($scale_indices_flattened) );
                }
                else {
                    return;
                }
            }
        )->flatten
    };
}

# Split indices of a piddle of indices into $n groups
# Return an arrayref of piddles.
classmethod _split_indices (Piddle1D $indices, $n=$indices->max+1) {
    my $indices1 = $indices->copy;
    $indices1->where($indices1 > $n - 1) .= $n - 1;
    return [ map { which( $indices1 == $_ ) } ( 0 .. $n - 1 ) ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Layout - Layout

=head1 VERSION

version 0.0007

=head1 DESCRIPTION

The job of "layout" is to coordinate:

=over 4

=item *

The coordinate system

=item *

The facetting specification

=item *

The individual position scales for each panel

=back

=head1 ATTRIBUTES

=head2 coord

The coordinate system.
Default is the output of C<coord_cartesian()>

=head2 facet

The facetting specification.
Default is the output of C<facet_null()>

=head1 METHODS

=head2 train_position

Trains the layout object's C<panel_scales_x> and C<panel_scales_y>
scales.

=head1 SEE ALSO

L<Chart::GGPlot::Coord>

L<Chart::GGPlot::Facet>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
