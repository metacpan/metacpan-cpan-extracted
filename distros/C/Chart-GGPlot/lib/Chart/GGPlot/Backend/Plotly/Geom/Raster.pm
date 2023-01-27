package Chart::GGPlot::Backend::Plotly::Geom::Raster;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Raster

use Chart::GGPlot::Class qw(:pdl);

our $VERSION = '0.002002'; # VERSION

with qw(Chart::GGPlot::Backend::Plotly::Geom);

use List::AllUtils qw(pairwise);
use Module::Load;
use PDL::Primitive qw(which);

use Chart::GGPlot::Backend::Plotly::Util qw(to_rgb);
use Chart::GGPlot::Util qw(rescale);

classmethod to_traces ($df, $params, $plot) {

    # TODO: see when we shall use Heatmapgl.
    # It looks like that Heatmapgl's has a performance problem, see
    # https://github.com/plotly/plotly.js/issues/1827
    my $plotly_trace_class = 'Chart::Plotly::Trace::Heatmap';
    load $plotly_trace_class;

    my ( $x, $y ) = map { $df->at($_)->uniq->qsort } qw(x y);

    my $to_2d_arrayref = sub {
        my ($p) = @_;
        return $p->copy->reshape( $x->length, $y->length )->unpdl;
    };

    my $z    = &$to_2d_arrayref( $df->at('fill_raw') );
    my $text = &$to_2d_arrayref( $df->at('hovertext') );

    my $color_scale = $df->select_columns( ['fill'] );

    # color scale must not have BAD values
    my $rindices = which( $color_scale->at('fill')->isgood );
    $color_scale = $color_scale->select_rows($rindices);
    $color_scale->set( 'fill_raw', $df->at('fill_raw')->slice($rindices) );
    $color_scale->set( 'alpha',    $df->at('alpha')->slice($rindices) );

    $color_scale = $color_scale->sort( ['fill_raw'] )->uniq;

    # colorscale must cover [0, 1]
    my @values = do {
        my $fill_raw = $color_scale->at('fill_raw');
        rescale( $fill_raw, pdl( [ 0, 1 ] ), pdl( $fill_raw->minmax ) )->list;
    };
    my @colors =
      to_rgb( $color_scale->at('fill'), $color_scale->at('alpha') )->list;

    $color_scale = [ pairwise { [ $a, $b ] } @values, @colors ];

    my $trace = $plotly_trace_class->new(
        x              => $x->unpdl,
        y              => $y->unpdl,
        z              => $z,
        hoverinfo      => 'text',
        text           => $text,
        colorscale     => $color_scale,
        showscale      => 0,
        autocolorscale => 0,
    );
    return [ $class->_adjust_trace_for_flip( $trace, $plot ) ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Raster - Chart::GGPlot's Plotly implementation for Geom::Raster

=head1 VERSION

version 0.002002

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Path>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
