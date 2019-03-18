package Chart::GGPlot::Coord::Functions;

# ABSTRACT: Functions of coordination systems

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0001'; # VERSION

use Chart::GGPlot::Coord::Cartesian;
use Chart::GGPlot::Coord::Polar;
use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util qw(:all);

use parent qw(Exporter::Tiny);

my @export_ggplot = qw(coord_cartesian coord_polar);

our @EXPORT_OK = (
    @export_ggplot,
    qw(
      )
);

our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);

sub coord_cartesian {
    return Chart::GGPlot::Coord::Cartesian->new(@_);
}

fun coord_polar (:$theta ='x', :$start = 0, :$direction = 1) {
    return Chart::GGPlot::Coord::Polar->new(
        theta     => $theta,
        start     => $start,
        direction => ( $direction <=> 0 )
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Coord::Functions - Functions of coordination systems

=head1 VERSION

version 0.0001

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
