package Chart::GGPlot::Geom::Blank;

# ABSTRACT: Class for blank geom

use Chart::GGPlot::Class;
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.0001'; # VERSION

with qw(Chart::GGPlot::Geom);

method handle_na ( $data, $params ) { $data; }

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Blank - Class for blank geom

=head1 VERSION

version 0.0001

=head1 SEE ALSO

L<Chart::GGPlot::Geom>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
