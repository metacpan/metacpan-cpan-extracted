package Chart::GGPlot::Geom::Smooth;

# ABSTRACT: Class for smooth geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

extends qw(Chart::GGPlot::Geom::Line);

our $VERSION = '0.002002'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

has '+default_aes'     => (
    default => sub {
        Chart::GGPlot::Aes->new(
            color    => PDL::SV->new( ['#3366FF'] ),
            fill     => PDL::SV->new( ['grey60'] ),
            size     => pdl(1),
            linetype => PDL::SV->new( ['solid'] ),
            weight   => pdl(1),
            alpha    => pdl(0.4),
        );
    }   
);

classmethod required_aes() { [qw(x y)] }
classmethod optional_aes() { [qw(ymin ymax)] }

my $geom_smooth_pod = layer_func_pod(<<'EOT');

        geom_smooth(:$mapping=undef, :$data=undef,
                    :$stat='smooth', :$position='identity',
                    :$method='auto', :$se=true,
                    :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                    %rest)

    Aids the eye in seeing patterns in the presence of overplotting, by
    calculating a smoothed conditional mean.

    C<geom_smooth()> and C<stat_smooth()> are effectively aliases: they
    both use the same arguments. Use C<stat_smooth()> if you want to
    display the results with a non-standard geom.

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =back

    See also L<Chart::GGPlot::Stat::Functions/stat_smooth>.

EOT

my $geom_smooth_code = fun (
        :$mapping = undef, :$data = undef,
        :$stat = 'smooth', :$position = 'identity',
        :$method = 'auto',
        :$se = true,
        :$na_rm = false, :$show_legend = undef, :$inherit_aes = true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'smooth',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            na_rm  => $na_rm,
            se     => $se,
            method => $method,
            %rest
        },
    );  
};

classmethod ggplot_functions() {
    return [
        {
            name => 'geom_smooth',
            code => $geom_smooth_code,
            pod => $geom_smooth_pod,
        },
    ];  
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Smooth - Class for smooth geom

=head1 VERSION

version 0.002002

=head1 SEE ALSO

L<Chart::GGPlot::Geom>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
