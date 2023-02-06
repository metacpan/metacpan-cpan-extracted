package Chart::GGPlot::Backend::Plotly::Geom::Tile;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Tile

use Chart::GGPlot::Class;

our $VERSION = '0.002003'; # VERSION

extends qw(Chart::GGPlot::Backend::Plotly::Geom::Rect);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Tile - Chart::GGPlot's Plotly implementation for Geom::Tile

=head1 VERSION

version 0.002003

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Tile>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
