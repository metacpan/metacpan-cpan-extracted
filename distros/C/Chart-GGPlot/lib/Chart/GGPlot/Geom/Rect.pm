package Chart::GGPlot::Geom::Rect;

# ABSTRACT: Class for rect geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.0007'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Util qw(NA);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

with qw(Chart::GGPlot::Geom);

has '+non_missing_aes' => ( default => sub { [qw(size shape color)] } );
has '+default_aes'     => (
    default => sub {
        Chart::GGPlot::Aes->new(
            color    => NA(),
            fill     => PDL::SV->new(["grey35"]),
            size     => pdl(0.5),
            linetype => PDL::SV->new(["solid"]),
            alpha    => NA(),
        );
    }
);

classmethod required_aes() { [qw(xmin xmax ymin ymax)] };

my $geom_rect_pod = layer_func_pod(<<'EOT');

        geom_rect(:$mapping=undef, :$data=undef, :$stat='count',
                  :$position='stack', :$width=undef,
                  :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                  %rest)

    C<geom_rect()> uses the locations of the four corners
    (aethetics C<xmin>, C<xmax>, C<ymin> and C<ymax>) to define rectangles.

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =back

EOT

my $geom_rect_code = fun(
    :$mapping = undef, :$data = undef,
    :$stat = 'identity', :$position = 'identity',
    :$na_rm = false, :$show_legend = undef, :$inherit_aes = true,
    %rest)
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'rect',
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
            name => 'geom_rect',
            code => $geom_rect_code,
            pod  => $geom_rect_pod,
        },
    ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Rect - Class for rect geom

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
