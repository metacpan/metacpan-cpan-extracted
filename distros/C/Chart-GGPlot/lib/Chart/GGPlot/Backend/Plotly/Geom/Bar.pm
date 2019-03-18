package Chart::GGPlot::Backend::Plotly::Geom::Bar;

# ABSTRACT: Chart::GGPlot's Plotly support for Geom::Bar

use Chart::GGPlot::Class;

our $VERSION = '0.0001'; # VERSION

with qw(Chart::GGPlot::Backend::Plotly::Geom);

use Module::Load;

use Chart::GGPlot::Backend::Plotly::Util qw(to_rgb);

classmethod to_trace ($df, %rest) {
    load Chart::Plotly::Trace::Bar;
    load Chart::Plotly::Trace::Bar::Marker;

    my $fill    = to_rgb( $df->at('fill') );
    my $opacity = $df->at('alpha')->setbadtoval(1);

    my $marker = Chart::Plotly::Trace::Bar::Marker->new(
        color   => $fill->unpdl,
        opacity => $opacity->unpdl,
    );

    my $x     = $df->at('x')->unpdl;
    my $y     = ( $df->at('ymax') - $df->at('ymin') )->unpdl;
    my $base  = $df->at('ymin')->unpdl;
    my $width = ( $df->at('xmax') - $df->at('xmin') )->unpdl;

    return Chart::Plotly::Trace::Bar->new(
        x         => $x,
        y         => $y,
        base      => $base,
        width     => $width,
        marker    => $marker,
        hovertext => $df->at('hovertext')->unpdl,
        hoverinfo => 'text',
    );
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

Chart::GGPlot::Backend::Plotly::Geom::Bar - Chart::GGPlot's Plotly support for Geom::Bar

=head1 VERSION

version 0.0001

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
