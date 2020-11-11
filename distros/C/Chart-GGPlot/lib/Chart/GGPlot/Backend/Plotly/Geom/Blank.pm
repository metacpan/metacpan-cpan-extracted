package Chart::GGPlot::Backend::Plotly::Geom::Blank;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Blank

use Chart::GGPlot::Class;

our $VERSION = '0.0011'; # VERSION

with qw(Chart::GGPlot::Backend::Plotly::Geom);

classmethod to_traces ($df, @rest) { [] }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Blank - Chart::GGPlot's Plotly implementation for Geom::Blank

=head1 VERSION

version 0.0011

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Blank>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
