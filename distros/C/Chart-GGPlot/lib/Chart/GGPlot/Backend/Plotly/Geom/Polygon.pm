package Chart::GGPlot::Backend::Plotly::Geom::Polygon;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Bar

use Chart::GGPlot::Class;

our $VERSION = '0.0011'; # VERSION

extends qw(Chart::GGPlot::Backend::Plotly::Geom::Line);

use PDL::Core qw(pdl);
use Module::Load;

use Chart::GGPlot::Backend::Plotly::Util qw(
  cex_to_px to_rgb group_to_NA pdl_to_plotly
);

classmethod split_on () { [qw(fill color size)] }
classmethod hover_on () { 'fills' }

around to_traces ($orig, $class : $df, $params, $plot) {
    my $traces = $class->$orig($df, $params, $plot);
    for my $trace (@$traces) {
        my $size = cex_to_px( $df->at('size')->slice( pdl(0) ) )->at(0);
        my $fillcolor = to_rgb( $df->at('fill'), $df->at('alpha') )->at(0);
        $trace->text($df->at('hovertext')->at(0));
        $trace->line->width($size);
        $trace->fill('toself');
        $trace->fillcolor($fillcolor);
    }
    return $traces;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Polygon - Chart::GGPlot's Plotly implementation for Geom::Bar

=head1 VERSION

version 0.0011

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Bar>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
