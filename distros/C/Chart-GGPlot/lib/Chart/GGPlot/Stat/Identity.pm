package Chart::GGPlot::Stat::Identity;

# ABSTRACT: Statistic method that does identity

use Chart::GGPlot::Class;
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.002001'; # VERSION

use Chart::GGPlot::Layer;
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

with qw(
  Chart::GGPlot::Stat
);

my $stat_identity_pod = layer_func_pod(<<'EOT');

        stat_identity(:$mapping=undef, :$data=undef,
                      :$geom="point", :$position="identity",
                      :$show_legend=undef, :$inherit_aes=true,
                      %rest)

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =back

EOT

my $stat_identity_code = fun (
        :$mapping = undef, :$data = undef,
        :$geom = "point", :$position = "identity",
        :$show_legend = undef, :$inherit_aes = true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        mapping     => $mapping,
        data        => $data,
        stat        => 'identify',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        geom        => 'blank',
        params      => { na_rm => false, %rest },
    );
};

classmethod ggplot_functions() {
    return [
        {
            name => 'stat_identity',
            code => $stat_identity_code,
            pod  => $stat_identity_pod,
        }
    ];
}

method compute_layer( $data, $params, $layout ) {
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Identity - Statistic method that does identity

=head1 VERSION

version 0.002001

=head1 SEE ALSO

L<Chart::GGPlot::Stat>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
