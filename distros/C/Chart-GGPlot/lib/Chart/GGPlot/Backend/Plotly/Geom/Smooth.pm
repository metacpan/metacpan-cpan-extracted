package Chart::GGPlot::Backend::Plotly::Geom::Smooth;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Smooth

use Chart::GGPlot::Class qw(:pdl);

our $VERSION = '0.002002'; # VERSION

extends qw(Chart::GGPlot::Backend::Plotly::Geom::Line);

use Module::Load;

use Chart::GGPlot::Backend::Plotly::Util qw(
  to_rgb group_to_NA pdl_to_plotly
);
use Chart::GGPlot::Backend::Plotly::Geom::Polygon;
use Chart::GGPlot::Backend::Plotly::Util qw(ribbon);
use Chart::GGPlot::Util qw(BAD);

around to_traces( $orig, $class : $df, $params, $plot ) {
    return [] if $df->nrow == 0;

    my $path = $df->copy;
    $path->set('alpha', pdl(1));    # alpha for the path is always 1
    my $traces_fitted = $class->$orig( $path, $params, $plot );
    unless ( $df->exists('ymin') and $df->exists('ymax') ) {
        return [@$traces_fitted];
    }

    my $ribbon = ribbon($df);
    $ribbon->set( 'color', BAD() );
    my $traces_confintv =
      Chart::GGPlot::Backend::Plotly::Geom::Polygon->to_traces( $ribbon,
        $params, $plot );
    for my $trace (@$traces_confintv) {
        $trace->{hoverinfo} = 'x+y';
    }

    return [ @$traces_confintv, @$traces_fitted ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Smooth - Chart::GGPlot's Plotly implementation for Geom::Smooth

=head1 VERSION

version 0.002002

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Smooth>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
