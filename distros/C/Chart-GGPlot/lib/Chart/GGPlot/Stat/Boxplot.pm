package Chart::GGPlot::Stat::Boxplot;

# ABSTRACT: Statistic method that gets the statistics data for boxplot

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.002000'; # VERSION

use Data::Frame;
use List::AllUtils qw(pairwise);
use PDL::Primitive qw(which);
use POSIX qw(floor);

use Chart::GGPlot::Aes::Functions qw(aes);
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(
  is_discrete range_ has_groups resolution remove_missing
);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

with qw(
  Chart::GGPlot::Stat
);

classmethod required_aes () { ['y'] }
classmethod non_missing_aes() { ['weight'] }

classmethod _parameters () {
    [
        qw(
          na_rm
          bins binwidth boundary breaks center pad
          )
    ]
}

my $stat_boxplot_pod = layer_func_pod(<<'EOT');

        stat_boxplot(:$mapping=undef, :$data=undef,
                     :$geom='boxplot', :$position='dodge2',
                     :$coef=1.5,
                     :$na_rm=false, :$show_legend='auto', :$inherit_aes=true,
                     %rest)

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =item * $coef

    Length of the whiskers as multiple of IQR. Defaults to 1.5.

    =back

EOT

my $stat_boxplot_code = fun (
        :$mapping=undef, :$data=undef,
        :$geom='boxplot', :$position='dodge2',
        :$coef=1.5, :$na_rm=false,
        :$show_legend='auto', :$inherit_aes=true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => 'boxplot',
        geom        => $geom,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            na_rm => $na_rm,
            coef  => $coef,
            %rest,
        }
    );
};

classmethod ggplot_functions () {
    return [
        {
            name => 'stat_boxplot',
            code => $stat_boxplot_code,
            pod  => $stat_boxplot_pod,
        }
    ];
}

method setup_data($data, $params) {
    unless ($data->exists('x')) {
        $data->set('x', pdl(0));
    } 
    return remove_missing(
        $data,
        na_rm => false,
        vars  => ['x'],
        name  => 'stat_boxplot'
    );
}

method setup_params ($data, $params) {
    unless ( $params->exists('width') ) {
        $params->set( 'width',
            resolution( $data->exists('x') ? $data->at('x') : 0 ) * 0.75 );
    }

    if ( $data->exists('x') ) {
        my $x = $data->at('x');
        if ( !is_discrete($x) and !has_groups($data) and $x->uniq->length > 1 )
        {
            warn("Continuous x aesthetic -- did you forget aes(group=>...)?");
        }
    }
    return $params;
}

method compute_group ($data, $scales, $params) {
    my $width = $params->at('width');
    my $na_rm = $params->at('na_rm') // false;
    my $coef  = $params->at('coef') // 1.5;

    my @qs = ( 0, 0.25, 0.5, 0.75, 1 );

    my @stats;
    if ( $data->exists('weight') ) {
        ...;
    }
    else {
        @stats = map { $data->at('y')->pct($_) } @qs;
    }
    my $iqr = $stats[3] - $stats[1];

    my $y = $data->at('y');
    my $outliers =
      ( ( $y < $stats[1] - $coef * $iqr ) | ( $y > $stats[3] + $coef * $iqr ) );
    if ( $outliers->any ) {    # ajust min and max for outliers
        ( $stats[0], $stats[4] ) = $y->where( !$outliers )->minmax;
    }

    if ( $data->at('x')->uniq->length > 1 ) {
        $width = range_( $data->at('x') )->diff->at(0) * 0.9;
    }

    my @names = qw(ymin lower middle upper ymax);
    my $df    = Data::Frame->new(
        columns => [ pairwise { $a => pdl( [$b] ) } @names, @stats ] );
    $df->set( 'outliers', PDL::SV->new( [ $y->where($outliers) ] ) );

    my $n;
    if ( $data->exists('weight') ) {

        # Sum up weights for non-NA positions of y and weight
        my $weight = $data->at('weight');
        $n = int( $weight->where( $y->isgood & $weight->isgood )->sum );
    }
    else {
        $n = int( $y->isgood->sum );
    }

    my $middle = $df->at('middle');
    my $sqrt_n = sqrt($n);
    $df->set( 'notchupper', $middle + 1.58 * $iqr / $sqrt_n );
    $df->set( 'notchlower', $middle - 1.58 * $iqr / $sqrt_n );

    my $x = $data->at('x');
    $df->set( 'x',
        pdl( [ $x->$_DOES('PDL::Factor') ? $x->at(0) : range_($x)->average ] )
    );
    $df->set( 'width',       pdl( [$width] ) );
    $df->set( 'relvarwidth', pdl( [$sqrt_n] ) );

    return $df;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Boxplot - Statistic method that gets the statistics data for boxplot

=head1 VERSION

version 0.002000

=head1 SEE ALSO

L<Chart::GGPlot::Stat>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
