package Chart::GGPlot::Layer::Functions;

# ABSTRACT: Layer functions

use Chart::GGPlot::Setup;

our $VERSION = '0.0001'; # VERSION

use Chart::GGPlot::Util qw(:all);

use Chart::GGPlot::Layer;
use Chart::GGPlot::Aes::Functions qw(aes);

use parent qw(Exporter::Tiny);

my @export_ggplot = qw(layer);

our @EXPORT_OK   = @export_ggplot;
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot
);


sub layer {
    return Chart::GGPlot::Layer->new(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Layer::Functions - Layer functions

=head1 VERSION

version 0.0001

=head1 FUNCTIONS

=head2 layer(...)

Returns a Chart::GGPlot::Layer object.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
