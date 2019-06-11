package Chart::GGPlot::Backend::Plotly::Geom::Bar;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Bar

use Chart::GGPlot::Class;

our $VERSION = '0.0005'; # VERSION

with qw(Chart::GGPlot::Backend::Plotly::Geom);

use Module::Load;

use Chart::GGPlot::Backend::Plotly::Util qw(to_rgb pdl_to_plotly);

classmethod split_on () { [qw(fill)] }

classmethod to_traces ($df, $params, $plot) {
    load Chart::Plotly::Trace::Bar;
    load Chart::Plotly::Trace::Bar::Marker;

    my $fill    = to_rgb( $df->at('fill') );
    my $opacity = $df->at('alpha')->setbadtoval(1);

    my $marker = Chart::Plotly::Trace::Bar::Marker->new(
        color   => pdl_to_plotly( $fill,    true ),
        opacity => pdl_to_plotly( $opacity, true ),
    );

    my $x     = $df->at('x');
    my $base  = $df->at('ymin');
    my $y     = $df->at('ymax') - $base;
    my $width = $df->at('xmax') - $df->at('xmin');

    my $trace = Chart::Plotly::Trace::Bar->new(
        x         => pdl_to_plotly($x),
        y         => pdl_to_plotly($y),
        base      => pdl_to_plotly( $base, true ),
        width     => pdl_to_plotly( $width, true ),
        marker    => $marker,
        hovertext => pdl_to_plotly( $df->at('hovertext') ),
        hoverinfo => 'text',
        hoveron   => $class->hover_on,
    );
    return [ $class->_adjust_trace_for_flip($trace, $plot) ];
}

around _hovertext_data_for_aes( $orig, $class : $df, $aes ) {
    return (
          $aes eq 'y'
        ? $df->at('ymax') - $df->at('ymin')
        : $class->$orig( $df, $aes )
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Bar - Chart::GGPlot's Plotly implementation for Geom::Bar

=head1 VERSION

version 0.0005

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Bar>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
