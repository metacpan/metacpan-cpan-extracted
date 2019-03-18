package Chart::GGPlot::Geom::Rect;

# ABSTRACT: Class for rect geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.0001'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Util qw(:all);

with qw(Chart::GGPlot::Geom);

has '+non_missing_aes' => ( default => sub { [qw(size shape color)] } );
has '+default_aes'     => (
    default => sub {
        Chart::GGPlot::Aes->new(
            color    => NA(),
            fill     => PDL::SV->new(["grey35"]),
            size     => pdl(0.5),
            linetype => PDL::SV->new(["solid"]),
            alpha    => NA(),
        );
    }
);

classmethod required_aes() { [qw(xmin xmax ymin ymax)] };

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Rect - Class for rect geom

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
