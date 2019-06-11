package Chart::GGPlot::Geom::Point;

# ABSTRACT: Class for point geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.0005'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(:all);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

with qw(Chart::GGPlot::Geom);

has '+non_missing_aes' => ( default => sub { [qw(size shape color)] } );
has '+default_aes'     => (
    default => sub {
        Chart::GGPlot::Aes->new(
            shape  => pdl(19),
            color  => PDL::SV->new(["black"]),
            size   => pdl(1.5),
            fill   => NA(),
            alpha  => NA(),
            stroke => pdl(0.5),
        );
    }
);

classmethod required_aes() { [qw(x y)] }

my $geom_point_pod = layer_func_pod(<<'EOT');

        geom_point(:$mapping=undef, :$data=undef, :$stat='identity',
                   :$position='identity',
                   :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                   %rest)

    The "point" geom is used to create scatterplots.
    The scatterplot is most useful for displaying the relationship between
    two continuous variables.
    A bubblechart is a scatterplot with a third variable mapped to the size
    of points.

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =back

EOT

my $geom_point_code = fun (
        :$mapping = undef, :$data = undef,
        :$stat = 'identity', :$position = 'identity',
        :$na_rm = false,
        :$show_legend = undef, :$inherit_aes = true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        geom        => 'point',
        params      => { na_rm => $na_rm, %rest },
    );
};

classmethod ggplot_functions() {
    return [
        {
            name => 'geom_point',
            code => $geom_point_code,
            pod => $geom_point_pod,
        }
    ];
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Point - Class for point geom

=head1 VERSION

version 0.0005

=head1 SEE ALSO

L<Chart::GGPlot::Geom>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
