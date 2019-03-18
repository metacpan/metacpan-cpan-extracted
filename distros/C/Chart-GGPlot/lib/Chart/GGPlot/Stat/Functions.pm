package Chart::GGPlot::Stat::Functions;

# ABSTRACT: Function interface for stats

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0001'; # VERSION

use Chart::GGPlot::Layer::Functions qw(layer);
use Chart::GGPlot::Types;
use Chart::GGPlot::Util qw(:all);

use parent qw(Exporter::Tiny);

my @export_ggplot = qw(
  stat_identity stat_count
);
our @EXPORT_OK   = @export_ggplot;
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);


fun stat_identity (:$mapping = undef, :$data = undef,
                   :$geom = "point", :$position = "identity",
                   :$show_legend = undef, :$inherit_aes = true, %rest) {
    return layer(
        mapping     => $mapping,
        data        => $data,
        stat        => 'identify',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        geom        => 'blank',
        params      => { na_rm => false, %rest },
    );
}


fun stat_count (:$mapping = undef, :$data = undef,
                :$geom = 'bar', :$position = 'stack', 
                :$width = undef, :$na_rm = false,
                :$show_legend = undef, :$inherit_aes = true,
                %rest ) {
    my $params = {
        na_rm => $na_rm,
        width => $width,
        %rest
    };
    if ( $data->exists('y') ) {
        die "stat_count() must not be used with a y aesthetic.";
    }

    return layer(
        data        => $data,
        mapping     => $mapping,
        stat        => 'count',
        geom        => $geom,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => $params,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Functions - Function interface for stats

=head1 VERSION

version 0.0001

=head1 FUNCTIONS

=head2 stat_identity

=head2 stat_count

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
