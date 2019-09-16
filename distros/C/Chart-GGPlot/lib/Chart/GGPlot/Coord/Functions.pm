package Chart::GGPlot::Coord::Functions;

# ABSTRACT: Functions of coordination systems

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0007'; # VERSION

use Chart::GGPlot::Util qw(collect_functions_from_package);

use parent qw(Exporter::Tiny);

my @export_ggplot;

our @sub_namespaces = qw(Cartesian Flip);

for my $name (@sub_namespaces) {
    my $package = "Chart::GGPlot::Coord::$name";
    my @func_names = collect_functions_from_package($package);
    push @export_ggplot, @func_names;
}

our @EXPORT_OK = (
    @export_ggplot,
);

our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Coord::Functions - Functions of coordination systems

=head1 VERSION

version 0.0007

=head1 FUNCTIONS

=head2 coord_cartesian

    coord_cartesian(:$xlim=undef, :$ylim=undef, :$expand=true)

The Cartesian coordinate system is the most familiar, and common, type of
coordinate system.
Setting limits on the coordinate system will zoom the plot (like you're
looking at it with a magnifying glass), and will not change the underlying
data like setting limits on a scale will.

Arguments:

=over 4

* $xlim, $ylim 	

Limits for the x and y axes.

* $expand 	

If true, the default, adds a small expansion factor to the limits to ensure
that data and axes don't overlap.
If false, limits are taken exactly from the data or C<$xlim>/C<$ylim>.

=back

=head2 coord_flip

    coord_flip(:$xlim=undef, :$ylim=undef, :$expand=true)

Flip cartesian coordinates so that horizontal becomes vertical, and
vertical becoms horizontal.

=head1 SEE ALSO

L<Chart::GGPlot::Coord>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
