package Chart::GGPlot::Geom::Tile;

# ABSTRACT: Class for tile geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

with qw(Chart::GGPlot::Geom);

our $VERSION = '0.0005'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(NA resolution);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

has '+default_aes' => (
    default => sub {
        Chart::GGPlot::Aes->new(
            color    => NA(),
            fill     => PDL::SV->new( ['grey20'] ),
            size     => pdl(0.1),
            linetype => PDL::SV->new( ['solid'] ),
            alpha    => NA(),
            width    => NA(),
            height   => NA(),
        );
    }
);

classmethod require_aes () { [qw(x y)] }
classmethod extra_params () { [qw(na_rm)] }

my $geom_tile_pod = layer_func_pod(<<'EOT');

        geom_tile(:$mapping=undef, :$data=undef, :$stat='count',
                  :$position='stack', :$width=undef,
                  :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                  %rest)

    C<geom_tile()> uses the center of the tile and its size
    (aesthetics C<x>, C<y>, C<width> and C<height>) to define rectangles.

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =back

EOT

my $geom_tile_code = fun(
    :$mapping = undef, :$data = undef,
    :$stat = 'identity', :$position = 'identity',
    :$na_rm = false, :$show_legend = undef, :$inherit_aes = true,
    %rest)
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'tile',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            na_rm => $na_rm,
            %rest
        },
    );
};

classmethod ggplot_functions () {
    return [
        {
            name => 'geom_tile',
            code => $geom_tile_code,
            pod  => $geom_tile_pod,
        },
    ];
}

method setup_data ($data, $params) {
    my $x = $data->at('x');
    my $y = $data->at('y');
    my $width;
    if ( $data->exists('width') ) {
        $width = $data->delete('width');
    }
    else {
        $width = $params->at('width') // resolution( $x, false );
    }
    my $height;
    if ( $data->exists('height') ) {
        $height = $data->delete('height');
    }
    else {
        $height = $params->at('height') // resolution( $y, false );
    }

    $data->set('xmin', $x - $width / 2);
    $data->set('xmax', $x + $width / 2);
    $data->set('ymin', $y - $height / 2);
    $data->set('ymax', $y + $height / 2);

    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Tile - Class for tile geom

=head1 VERSION

version 0.0005

=head1 SEE ALSO

L<Chart::GGPlot::Geom>,
L<Chart::GGPlot::Geom::Rect>,
L<Chart::GGPlot::Geom::Raster>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
