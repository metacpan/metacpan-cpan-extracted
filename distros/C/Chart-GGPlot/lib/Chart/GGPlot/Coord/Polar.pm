package Chart::GGPlot::Coord::Polar;

# ABSTRACT: The polar coordinate system

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use List::AllUtils;
use PDL::Primitive qw(which);
use Types::Standard qw(Bool Enum Int Num);

use Chart::GGPlot::Util qw(:all);


has theta => ( is => 'ro', isa => Enum [qw(x y)] );
has r => ( is => 'ro', lazy => 1, builder => '_build_r', init_arg => undef );


has start => ( is => 'ro', isa => Num );


has direction =>
  ( is => 'ro', isa => Int->where(sub { $_ == 1 or $_ == -1 }), default => 1 );

sub _build_r {
    my $self = shift;
    return ( $self->theta eq 'x' ? 'y' : 'x' );
}

has limits =>
  ( is => 'ro', lazy => 1, builder => '_build_limits', init_arg => undef );

with qw(
  Chart::GGPlot::Coord
  Chart::GGPlot::HasCollectibleFunctions
);

my $coord_polar_pod = unindent(<<'EOT');

        coord_ploar(:$theta='x', :$start=0, :$direction=1)

EOT

my $coord_polar_code = fun (:$theta ='x', :$start = 0, :$direction = 1) {
    return __PACKAGE__->new(
        theta     => $theta,
        start     => $start,
        direction => ( $direction <=> 0 ) 
    );  
}

classmethod ggplot_functions () {
    return [
        {
            name => 'coord_polar',
            code => $coord_polar_code,
            pod  => $coord_polar_pod,
        }
    ];  
}

sub _build_limits {
    my $self = shift;
    return { x => $self->xlim, y => $self->ylim };
}

method aspect ($details) { 1 }

method distance ($x, $y, $details) {
    my $r;
    my $theta;
    if ( $self->theta eq 'x' ) {
        $r = rescale( $y, $details->at('r_range') );
        $theta = theta_rescale_no_clip( $self, $x, $details );
    }
    else {
        $r = rescale( $x, $details->at('r_range') );
        $theta = theta_rescale_no_clip( $self, $y, $details );
    }

    return dist_polar( $r, $theta );
}

method range ($panel_params) {
    return {
        $self->theta => $panel_params->at('theta_range'),
        $self->r     => $panel_params->at('r_range'),
    };
}

method setup_panel_params ($scale_x, $scale_y, $params = {}) {
    my $details = {};
    for my $n (qw(x y)) {
        my $scale = $n eq 'x' ? $scale_x : $scale_y;
        my $limits = $self->limits->at($n);

        my $range;
        if ( $limits->isempty ) {
            my $expand =
              $self->theta eq $n
              ? expand_default( $scale, [ 0, 0.5 ], [ 0, 0 ] )
              : expand_default( $scale, [ 0, 0 ],   [ 0, 0 ] );
            $range = $scale->dimension($expand);
        }
        else {
            $range = range( scale_transform( $scale, $limits ) );
        }

        my $out = $scale->break_info($range);

        $details->merge(
            {
                "${n}_range"      => $out->at('range'),
                "${n}_major"      => $out->at('major_source'),
                "${n}_minor"      => $out->at('minor_source'),
                "${n}_labels"     => $out->at('labels'),
                "${n}_sec_range"  => $out->at('sec_range'),
                "${n}_sec_major"  => $out->at('sec_major_source'),
                "${n}_sec_minor"  => $out->at('sec_minor_source'),
                "${n}_sec_labels" => $out->at('sec_labels'),
            }
        );
    }

    if ( $self->theta eq 'y' ) {
        $details = {
            $details->keys->map(
                sub { $_ => ( $_ =~ s/^x_/r_/r =~ s/^y_/theta_/r ) }
            )->flatten
        };
        $details->{r_arrange} = $scale_x->axis_order();
    }
    else {
        $details = {
            $details->keys->map(
                sub { $_ => ( $_ =~ s/^x_/theta_/r =~ s/^y_/r_/r ) }
            )->flatten
        };
        $details->{r_arrange} = $scale_y->axis_order();
    }

    return $details;
}

method transform ($data, $panel_params) {
    my $data = rename_data( $self, $data );

    $data->set( 'r', r_rescale( $self, $data->at('r'), $panel_params ) );
    $data->set( 'theta',
        theta_rescale( $self, $data->at('theta'), $panel_params ) );
    $data->set( 'x', $data->r * $data->theta->sin + 0.5 );
    $data->set( 'y', $data->r * $data->theta->cos + 0.5 );
    return $data;
}

method labels ($panel_params) {
    if ( $self->theta eq 'y' ) {
        return { x => $panel_params->at('y'), y => $panel_params->at('x') };
    }
    else {
        return $panel_params;
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Coord::Polar - The polar coordinate system

=head1 VERSION

version 0.002000

=head1 DESCRIPTION

The ploar coordinate system is most commonly used for pie charts, which
are a stacked bar chart in polar coordinates.

=head1 ATTRIBUTES

=head2 theta

Variable to map angle to C<x> or C<y>.

=head2 start

Offset of starting point from 12 o'clock in radians.

=head2 direction

1 for clockwise and -1 for anticlockwise.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
