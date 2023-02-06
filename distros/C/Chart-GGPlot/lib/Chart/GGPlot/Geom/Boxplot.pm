package Chart::GGPlot::Geom::Boxplot;

# ABSTRACT: Class for boxplot geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

extends qw(Chart::GGPlot::Geom::Rect);

our $VERSION = '0.002003'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Layer;
use Chart::GGPlot::Position::Functions qw(position_dodge2);
use Chart::GGPlot::Util qw(:all);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

has '+default_aes' => (
    default => sub {
        Chart::GGPlot::Aes->new(
            weight   => pdl(1),
            color    => PDL::SV->new( ['grey20'] ),
            fill     => PDL::SV->new( ['white'] ),
            size     => pdl(0.5),
            alpha    => NA(),
            shape    => pdl(19),
            linetype => PDL::SV->new( ['solid'] ),
        );
    }
);

classmethod required_aes() { [qw(x lower upper middle ymin ymax)] }
classmethod extra_params () {
    [
        qw(
          fatten
          outlier_color outlier_fill outlier_shape outlier_size
          outlier_stroke outlier_alpha
          notch notchwidth varwidth na_rm width
          )
    ]
}

my $geom_boxplot_pod = layer_func_pod(<<'EOT');

        geom_boxplot(:$mapping=undef, :$data=undef, 
                     :$stat='boxplot', :$position='dodge2',
                     :$outlier_color=undef, :$outlier_colour=undef,
                     :$outlier_fill=undef, :$outlier_shape=undef,
                     :$outlier_size=1.5, :$outlier_stroke=undef,
                     :$outlier_alpha=undef,
                     :$notch=false, :$notchwidth=0.25,
                     :$varwidth=false, :$na_rm=false,
                     :$show_legend=undef, :$inherit_aes=true,
                     %rest)

    The boxplot compactly displays the distribution of a continuous
    variable. It visualises five summary statistics (the median, two hinges
    and two whiskers), and all "outlying" points individually.

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =item * $outlier_color, $outlier_fill, $outlier_size, $outlier_stroke,
    $outlier_alpha

    Default aesthetics for outliers. Set to C<undef> to inherit from the
    aesthetics used for the box.

    Sometimes it can be useful to hide the outliers, for example when
    overlaying the raw data points on top of the boxplot. Hiding the
    outliers can be achieved by setting C<outlier_shape =E<gt> ''>.
    Importantly, this does not remove the outliers, it only hides them, so
    the range calculated for the y-axis will be the same with outliers
    shown and outliers hidden.

    =item * $notch

    If false (default) make a standard box plot. If true, make a notched
    box plot. Notches are used to compare groups; if the notches of two
    boxes do not overlap, this suggests that the medians are significantly
    different.

    =item * $notchwidth

    For a notched box plot, width of the notch relative to the body. 

    =back

    See also L<Chart::GGPlot::Stat::Functions/stat_boxplot>.

EOT

my $geom_boxplot_code = fun (
        :$data=undef, :$mapping=undef, 
        :$stat='boxplot', :$position='dodge2',
        :$outlier_color=undef, :$outlier_colour=undef,
        :$outlier_fill=undef, :$outlier_shape=undef,
        :$outlier_size=1.5, :$outlier_stroke=undef,
        :$outlier_alpha=undef,
        :$notch=false, :$notchwidth=0.25,
        :$varwidth=false, :$na_rm=false,
        :$show_legend=undef, :$inherit_aes=true,
        %rest )
{
    if ( not Ref::Util::is_ref($position) ) {
        if ($varwidth) {
            $position = position_dodge2( preserve => 'single' );
        }
    }
    else {
        if ( $position->preserve eq 'total' and $varwidth ) {
            warn "Can't preserve total widths when varwidth is true.";
            $position->preserve('single');
        }
    }

    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'boxplot',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            outlier_color  => ( $outlier_color // $outlier_colour ),
            outlier_fill   => $outlier_fill,
            outlier_shape  => $outlier_shape,
            outlier_size   => $outlier_size,
            outlier_stroke => $outlier_stroke,
            outlier_alpha  => $outlier_alpha,
            notch          => $notch,
            notchwidth     => $notchwidth,
            varwidth       => $varwidth,
            na_rm          => $na_rm,
            %rest
        },
    );
};

classmethod ggplot_functions() {
    return [
        {
            name => 'geom_boxplot',
            code => $geom_boxplot_code,
            pod => $geom_boxplot_pod,
        }
    ];
}

method setup_data ($data, $params) {
    unless ( $data->exists('width') ) {
        $data->set( 'width',
            $params->at('width')
              // pdl( resolution( $data->at('x'), false ) * 0.9 ) );
    }

    if ( $data->exists('outliers') ) {
        my $outliers = $data->at('outliers')->unpdl;
        my ( $out_min, $out_max ) = map { pdl( $outliers->map($_) ) } (
            sub { $_->isempty ? "inf"  : $_->min },
            sub { $_->isempty ? "-inf" : $_->max }
        );
        $data->set( 'ymin_final', pmin( $out_min, $data->at('ymin') ) );
        $data->set( 'ymax_final', pmax( $out_max, $data->at('ymax') ) );
    }

    # if 'varwidth' not requested or not available, don't use it
    if (   $params->length == 0
        or !$params->at('varwidth')
        or !$params->at('relvarwidth') )
    {
        $data->set( 'xmin', $data->at('x') - $data->at('width') / 2 );
        $data->set( 'xmax', $data->at('x') + $data->at('width') / 2 );
    }
    else {
        # make 'relvarwidth' relative to the size of the largest group
        my $relvarwidth = $data->at('relvarwidth');
        my $width = $data->at('width');
        $data->set( 'relvarwidth', $relvarwidth / $relvarwidth->max );
        $data->set( 'xmin', $data->at('x') - $relvarwidth * $width / 2 );
        $data->set( 'xmax', $data->at('x') + $relvarwidth * $width / 2 );
    }

    $data->delete('width');
    if ($data->exists('relvarwidth')) {
        $data->delete('relvarwidth');
    }

    return $data;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Boxplot - Class for boxplot geom

=head1 VERSION

version 0.002003

=head1 SEE ALSO

L<Chart::GGPlot::Geom>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
