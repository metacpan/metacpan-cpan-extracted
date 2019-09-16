package Chart::GGPlot::Geom::Raster;

# ABSTRACT: Class for raster geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

with qw(Chart::GGPlot::Geom);

our $VERSION = '0.0007'; # VERSION

use Machine::Epsilon qw(machine_epsilon);
use Types::Standard qw(Num);

use Chart::GGPlot::Aes;
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(NA resolution);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

has '+default_aes' => (
    default => sub {
        Chart::GGPlot::Aes->new(
            fill     => PDL::SV->new( ['grey20'] ),
            alpha    => NA(),
        );
    }
);

has '+non_missing_aes' => (
    default => sub { [qw(fill)] },
);

classmethod require_aes () { [qw(x y)] }
classmethod extra_params () { [qw(na_rm)] }
classmethod _parameters () { [qw(hjust vjust interpolate)] }

my $geom_raster_pod = layer_func_pod(<<'EOT');

        geom_raster(:$mapping=undef, :$data=undef, :$stat='count',
                    Num :$hjust=0.5, Num :$vjust=0.5,
                    :$position='stack', :$width=undef,
                    :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                    %rest)

    C<geom_raster()> is a high performance special case of C<geom_tile()>
    for when all the tiles are the same size.

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =back

EOT

my $geom_raster_code = fun(
    :$mapping = undef, :$data = undef,
    :$stat = 'identity', :$position = 'identity',
    Num :$hjust = 0.5, Num :$vjust = 0.5,
    #:$interpolate = false,
    :$na_rm = false, :$show_legend = undef, :$inherit_aes = true,
    %rest)
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'raster',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            na_rm       => $na_rm,
            hjust       => $hjust,
            vjust       => $vjust,
            #interpolate => $interpolate,
            %rest
        },
    );
};

classmethod ggplot_functions () {
    return [
        {
            name => 'geom_raster',
            code => $geom_raster_code,
            pod  => $geom_raster_pod,
        },
    ];
}

method setup_data ($data, $params) {
    my $hjust = $params->at('hjust') // 0.5;
    my $vjust = $params->at('vjust') // 0.5;

    my $precision = sqrt( machine_epsilon() );

    my $calc = sub {
        my ($axis) = @_;

        my $diff = $data->at($axis)->uniq->qsort->diff;
        if ( $diff->length == 0 ) {
            return 1;
        }
        elsif ( ( $diff->diff->abs > $precision )->any ) {
            my $desc = $axis eq 'x' ? 'horizontal' : 'vertical';
            warn(   "Raster pixels are placed at uneven $desc intervals "
                  . "and will be shifted. Consider using geom_tile() instead."
            );
            return $diff->min;
        }
        else {
            return $diff->at(0);
        }
    };

    my $w = $calc->('x');
    my $h = $calc->('y');

    my $x = $data->at('x');
    my $y = $data->at('y');

    $data->set( 'xmin', $x - $w * ( 1 - $hjust ) );
    $data->set( 'xmax', $x + $w * $hjust );
    $data->set( 'ymin', $y - $h * ( 1 - $vjust ) );
    $data->set( 'ymax', $y + $h * $vjust );

    # adjust x and y if necessary
    $data->set( 'x', $data->at('xmin') + $w * 0.5 ) if $hjust != 0.5;
    $data->set( 'y', $data->at('ymin') + $h * 0.5 ) if $vjust != 0.5;

    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Raster - Class for raster geom

=head1 VERSION

version 0.0007

=head1 SEE ALSO

L<Chart::GGPlot::Geom>,
L<Chart::GGPlot::Geom::Tile>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
