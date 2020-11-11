package Chart::GGPlot::Coord::Cartesian;

# ABSTRACT: The Cartesian coordinate system

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0011'; # VERSION

use Types::PDL qw(Piddle1D PiddleFromAny);
use Types::Standard qw(Maybe);

use Chart::GGPlot::Util qw(:all);


has [qw(xlim ylim)] => (
    is     => 'ro',
    isa    => Maybe [ Piddle1D->plus_coercions(PiddleFromAny) ],
    coerce => 1,
);

has limits =>
  ( is => 'ro', lazy => 1, builder => '_build_limits', init_arg => undef );

sub _build_limits {
    my $self = shift;
    return { x => $self->xlim, y => $self->ylim };
}


has expand => ( is => 'ro', default => sub { true } );


has default => (is => 'ro', default => sub { false } );

with qw(
  Chart::GGPlot::Coord
  Chart::GGPlot::HasCollectibleFunctions
);

my $coord_cartesian_pod = <<'=cut';

    coord_cartesian(:$xlim=undef, :$ylim=undef, :$expand=true)

The Cartesian coordinate system is the most familiar, and common, type of
coordinate system.
Setting limits on the coordinate system will zoom the plot (like you're
looking at it with a magnifying glass), and will not change the underlying
data like setting limits on a scale will.

Arguments:

=over 4

* $xlim, $ylim 	

Limits for the x and y axes.

* $expand 	

If true, the default, adds a small expansion factor to the limits to ensure
that data and axes don't overlap.
If false, limits are taken exactly from the data or C<$xlim>/C<$ylim>.

=back

=cut

my $coord_cartesian_code = sub {
    return __PACKAGE__->new(@_);
};

classmethod ggplot_functions () {
    return [
        {
            name => 'coord_cartesian',
            code => $coord_cartesian_code,
            pod  => $coord_cartesian_pod,
        }
    ];
}

classmethod is_linear() { true }

method distance ($x, $y, $panel_params) {
    my $max_dist = dist_euclidean( $panel_params->at('x_range'),
        $panel_params->at('y_range') );
    return dist_euclidean( $x, $y ) / $max_dist;
}

method transform ($data, $panel_params) {
    my ( $rescale_x, $rescale_y ) = map {
        fun($data) { rescale( $data, $panel_params->at($_) ) };
    } qw(x_range y_range);
    $data = transform_position( $data, $rescale_x, $rescale_y );
    return transform_position( $data, squish_infinite(), squish_infiniate() );
}

method setup_panel_params ($scale_x, $scale_y, $params = {}) {
    my $train_cartesian = fun( $scale, $limits, $xy ) {
        my $range = $self->scale_range( $scale, $limits, $self->expand );
        my $out = $scale->break_info($range);
        $out->set('arrange', $scale->axis_order);
        return $out->rename({ map { $_ => "${xy}.$_" } @{$out->names} });
    };

    return {
        $train_cartesian->( $scale_x, $self->limits->at('x'), 'x' )->flatten,
        $train_cartesian->( $scale_y, $self->limits->at('y'), 'y' )->flatten,
    };
}

method scale_range ($scale, $limits=undef, $expand=true) {
    my $expansion = $expand ? $self->expand_default($scale) : pdl([ 0, 0 ]);

    if ( not defined $limits or $limits->isempty ) {
        return $scale->dimension($expansion);
    }
    else {
        my $range = range_( $scale->transform($limits) );
        return expand_range( $range, $expansion->at(0), $expansion->at(1) );
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Coord::Cartesian - The Cartesian coordinate system

=head1 VERSION

version 0.0011

=head1 ATTRIBUTES

=head2 xlim

Limits for the x axis. 

=head2 ylim

Limits for the y axis. 

=head2 expand

If true, adds a small expansion factor to the limits to ensure
that data and axes do not overlap. If false, limits are taken
exactly from the data or C<xlim>/C<ylim>.

Default is true.

=head2 default

Is this the default coordinate system?

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
