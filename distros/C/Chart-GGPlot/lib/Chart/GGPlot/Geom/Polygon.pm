package Chart::GGPlot::Geom::Polygon;

# ABSTRACT: Class for polygon geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

with qw(Chart::GGPlot::Geom);

our $VERSION = '0.002001'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(:all);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

has '+default_aes'     => (
    default => sub {
        Chart::GGPlot::Aes->new(
            color    => PDL::SV->new( ['NA'] )->setbadat(0),
            fill     => PDL::SV->new( ['grey20'] ),
            size     => pdl(0.5),
            linetype => PDL::SV->new( ['solid'] ),
            alpha    => NA(),
        );
    }   
);

classmethod required_aes() { [qw(x y)] }

my $geom_polygon_pod = layer_func_pod(<<'EOT');

        geom_polygon(:$mapping=undef, :$data=undef,
                     :$stat='identity', :$position='identity',
                     :$na_rm=false, :$show_legend=undef,
                     :$inherit_aes=true,
                     %rest)

    Polygons are very similar to paths (as drawn by C<geom_path()>)
    except that the start and end points are connected and the inside is
    colored by the C<fill> aesthetic. The C<group> aesthetic determines
    which cases are connected together into a polygon. 

    =over 4

    %TMPL_COMMON_ARGS%

    =back

EOT

my $geom_polygon_code = fun (
        :$mapping = undef, :$data = undef,
        :$stat = 'identity', :$position = 'identity',
        :$width = undef, :$na_rm = false,
        :$show_legend = undef, :$inherit_aes = true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'polygon',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            na_rm => $na_rm,
            %rest,
        },
    );
};

classmethod ggplot_functions() {
    return [
        {
            name => 'geom_polygon',
            code => $geom_polygon_code,
            pod => $geom_polygon_pod,
        },
    ];  
}

method handle_na ( $data, $params ) { $data }

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Polygon - Class for polygon geom

=head1 VERSION

version 0.002001

=head1 SEE ALSO

L<Chart::GGPlot::Geom>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
