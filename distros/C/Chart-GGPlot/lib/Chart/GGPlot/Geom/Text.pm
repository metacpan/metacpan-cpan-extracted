## Please see file perltidy.ERR
package Chart::GGPlot::Geom::Text;

# ABSTRACT: Class for line geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

extends qw(Chart::GGPlot::Geom::Path);

our $VERSION = '0.002001'; # VERSION

use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(NA);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

has '+default_aes' => (
    default => sub {
        Chart::GGPlot::Aes->new(
            color  => PDL::SV->new( ['black'] ),
            size   => pdl(3.88),
            angle  => pdl(0),
            hjust  => PDL::SV->new( ['center'] ),
            vjust  => PDL::SV->new( ['center'] ),
            alpha  => NA(),
            family => PDL::SV->new( ["sans"] ),
        );
    }
);

classmethod required_aes() { [qw(x y label)] }

my $geom_text_pod = layer_func_pod(<<'EOT');

        geom_text(:$mapping=undef, :$data=undef, :$stat='identity',
                  :$position='identity',
                  :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                  %rest)

    C<geom_text()> adds text to the plot.

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =item * $hjust, $vjust

    You can modify text alignment with the C<hjust> and C<vjust> aesthetics.
    These can either be a number between 0 (right/bottom) and 1 (top/left) or a
    string, (C<"left">, C<"right">, C<"bottom">, C<"top">,
    C<"center">/C<"middle">).

    =item * $family

    Font family. Default is C<"sans">.

    =item * $size

    Font size in mm. Default is 3.88 mm (11pt).

    =back

EOT

my $geom_text_code = fun(
    : $mapping     = undef,
    : $data        = undef,
    : $stat        = 'identity',
    : $position    = 'identity',
    : $na_rm       = false,
    : $show_legend = undef,
    : $inherit_aes = true,
    %rest
  )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        geom        => 'text',
        params      => { na_rm => $na_rm, %rest },
    );
};

classmethod ggplot_functions() {
    return [
        {
            name => 'geom_text',
            code => $geom_text_code,
            pod  => $geom_text_pod,
        }
    ];
}

method setup_data( $data, $params ) {
    return $data->sort( [qw(PANEL group x)] );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Text - Class for line geom

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
