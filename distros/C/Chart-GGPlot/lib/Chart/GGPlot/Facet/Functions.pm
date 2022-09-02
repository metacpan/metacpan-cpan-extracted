package Chart::GGPlot::Facet::Functions;

# ABSTRACT: Function interface for Chart::GGPlot::Facet

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.002001'; # VERSION

use Chart::GGPlot::Facet::Null;
use Chart::GGPlot::Util qw(:all);

use parent qw(Exporter::Tiny);

my @export_ggplot = qw(facet_null);
our @EXPORT_OK = ( @export_ggplot );
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);


sub facet_null {
    return Chart::GGPlot::Facet::Null->new(@_);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Facet::Functions - Function interface for Chart::GGPlot::Facet

=head1 VERSION

version 0.002001

=head1 FUNCTIONS

=head2 facet_null

    facet_null(:$shrink=true)

This method creates a L<Chart::GGPlot::Facet::Null> object.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
