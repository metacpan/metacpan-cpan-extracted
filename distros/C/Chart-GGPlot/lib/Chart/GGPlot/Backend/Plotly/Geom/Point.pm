package Chart::GGPlot::Backend::Plotly::Geom::Point;

# ABSTRACT: Chart::GGPlot's Plotly support for Geom::Point

use Chart::GGPlot::Class;

our $VERSION = '0.0003'; # VERSION

extends qw(Chart::GGPlot::Backend::Plotly::Geom::Path);

use Module::Load;

use Chart::GGPlot::Backend::Plotly::Util qw(cex_to_px to_rgb pdl_to_plotly);
use Chart::GGPlot::Util qw(ifelse);

sub mode {
    return 'markers';
}

classmethod marker ($df, $params, @rest) {
    my $color = to_rgb( $df->at('color') );
    my $fill =
      $df->exists('fill')
      ? ifelse( $df->at('fill')->isbad, $color, to_rgb( $df->at('fill') ) )
      : $color;
    my $size = cex_to_px( $df->at('size') );
    $size = ifelse( $size > 2, $size, 2 );
    my $opacity = $df->at('alpha')->setbadtoval(1);
    my $stroke  = cex_to_px( $df->at('stroke') );

    my $use_webgl = $class->use_webgl($df);
    my $plotly_trace_class =
      $use_webgl
      ? 'Chart::Plotly::Trace::Scattergl'
      : 'Chart::Plotly::Trace::Scatter';
    my $plotly_marker_class = "${plotly_trace_class}::Marker";

    load $plotly_marker_class;

    return $plotly_marker_class->new(
        color => pdl_to_plotly( $fill, true ),
        size  => pdl_to_plotly( $size, true ),
        line  => {
            color => pdl_to_plotly( $color,  true ),
            width => pdl_to_plotly( $stroke, true ),
        },

        # TODO: support scatter symbol
        symbol  => [ (0) x $df->at('size')->length ],
        opacity => pdl_to_plotly( $opacity, true ),
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Point - Chart::GGPlot's Plotly support for Geom::Point

=head1 VERSION

version 0.0003

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Point>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
