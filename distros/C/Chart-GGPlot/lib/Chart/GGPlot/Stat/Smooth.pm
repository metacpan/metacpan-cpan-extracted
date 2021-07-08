package Chart::GGPlot::Stat::Smooth;

# ABSTRACT: Statistic method that does smoothing

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.0016'; # VERSION

use Data::Frame;
use Module::Load;
use PDL::Core ();
use PDL::MatrixOps ();

use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(seq_n);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);
use Chart::GGPlot::Util::Stats;

with qw(
  Chart::GGPlot::Stat
);

classmethod required_aes () { [qw(x y)] }

classmethod _parameters () {
    [   
        qw(
          na_rm
          method se n span fullrange level method_args
          )
    ]   
}

my $stat_smooth_pod = layer_func_pod(<<'EOT');

        stat_smooth(:$maping=undef, :$data=undef,
                    :$geom='smooth', :$position='identity',
                    :$method='auto', :$se=true,
                    :$n=80, :$span=0.75, :$fullrange=false, :$level=0.95,
                    :$method_args={},
                    :$na_rm=false, :$show_legend='auto', :$inherit_aes=true,
                    %rest)

    Arguments:
    
    =over 4

    %TMPL_COMMON_ARGS%

    =item * method

    Smoothing method (function) to use.
    
    The available methods are,

    =over 8
    
    =item * 'auto'

    'loess' is used for less than 1000 observations, 'glm' otherwise 

    =item * 'loess'

    Locally Weighted Regression

    Requires L<Math::LOESS>.

    Supported C<$method_args>, (see L<Math::LOESS::Model> for details)

    =over 12

    =item * $degree

    =item * $parametric
    
    =item * $drop_square

    =item * $normalize

    =item * $family

    =back

    =item * 'glm' : Generalized Linear Model

    Requires L<PDL::Stats::GLM> and L<PDL::GSL::CDF>.

    At this moment we can do only simple linear modeling. Still to support
    logistic and polynomial in future.

    Supported C<$method_args>,

    =over 12

    =item * $family

    =back

    =back

    =item * method_args

    Additional optional arguments passed on to the modeling function
    defined by C<$method>.

    =item * se

    Display confidence interval around smooth? (true by default, see
    C<$level> to control.)

    =item * fullrange

    Should the fit span the full range of the plot, or just the data?

    =item * level

    Level of confidence interval to use (0.95 by default). Effective when
    C<$se> is true.

    =item * span

    Controls the amount of smoothing for the default loess smoother.
    Larger number means more smoothing. It should be in the C<(0, 1)> range.

    =item * n
        
    Number of points at which to evaluate smoother.

    =back

EOT

my $stat_smooth_code = fun (
    :$maping=undef, :$data=undef,
    :$geom='smooth', :$position='identity',
    :$method='auto', :$se=true,
    :$n=80, :$span=0.75, :$fullrange=false, :$level=0.95,
    :$method_args={},
    :$na_rm=false, :$show_legend='auto', :$inherit_aes=true,
    %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $maping,
        stat        => 'smooth',
        geom        => $geom,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        parmas      => {
            method      => $method,
            se          => $se,
            n           => $n,
            fullrange   => $fullrange,
            level       => $level,
            na_rm       => $na_rm,
            method_args => $method_args,
            span        => $span,
            %rest
        },
    );
};

classmethod ggplot_functions() {
    return [
        {
            name => 'stat_smooth',
            code => $stat_smooth_code,
            pod => $stat_smooth_pod,
        },
    ];  
}

classmethod _predictdf($method) {
    my $func = "Chart::GGPlot::Util::Stats::${method}";
    no strict 'refs';
    unless (exists &{$func}) {
        die "Unsupported smooth method: $method";
    }
    return $func;
}

method setup_params($data, $params) {
    my $method = $params->at('method');
    if ($method eq 'auto') {

        # Use loess for small datasets
        # Based on size of the "largest" group to avoid bad memory
        #  behaviour of loess
        my $data1    = $data->select_columns( [qw(group PANEL)] );
        my $splitted = $data1->split( $data1->id );
        my $max_group =
          List::AllUtils::max( map { $_->nrow } ( values %$splitted ) );

        if ($max_group < 1000) {
            $method = 'loess';
            $params->set('method', $method);
        }

        $log->debugf("geom_smooth() using method = %s", $method);
    }

    # check if method is supported or not
    $self->_predictdf($method);
    return $params;
}
 
around compute_layer( $data, $params, $layout ) {

    # remove all "*_raw" columns, to avoid backends like plotly from
    #  generating wrong hovertext.
    my $data1 = $data->copy;
    for my $colname ( $data1->names->flatten ) {
        if ( $colname =~ /_raw$/ ) {
            $data1->delete($colname);
        }
    }
    $self->$orig( $data1, $params, $layout );
}

method compute_group($data, $scales, $params) {
    my $method      = $params->at('method');
    my $se          = $params->at('se') // true;
    my $n           = $params->at('n') // 80;
    my $span        = $params->at('span') // 0.75;
    my $fullrange   = $params->at('fullrange') // false;
    my $xseq        = $params->at('xseq');
    my $level       = $params->at('level') // 0.95;
    my $method_args = $params->at('method_args') // {};
    my $na_rm       = $params->at('na_rm') // false;

    if ($data->at('x')->uniq->length <  2) {
        # Not enough data to perform fit
        return Data::Frame->new();
    }

    unless (defined $xseq) {
        my $x = $data->at('x');
        if ($x->type < PDL::float) {
            $xseq =
                $fullrange
              ? $scales->at('x')->dimension
              : $x->uniq->qsort;
        }
        else {
            my $range =
                $fullrange
              ? $scales->at('x')->dimension
              : pdl($x->minmax);
            $xseq = seq_n($range->at(0), $range->at(1), $n);
        }
    }

    my $predictdf = $self->_predictdf($method);

    my %base_args = (
        x       => $data->at('x'),
        y       => $data->at('y'),
        weights => (
              $data->exists('weight')
            ? $data->at('weight')
            : PDL::Core::ones( $data->nrow )
        ),
        xseq    => $xseq,
        se      => $se,
        level   => $level,
    );
    if ($method eq 'loess') {
        $method_args->{span} = $span;
    }

    no strict 'refs';
    return $predictdf->( %base_args, %$method_args );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Smooth - Statistic method that does smoothing

=head1 VERSION

version 0.0016

=head1 DESCRIPTION

Some of the stats methods may require additional modules be installed. For
example the C<"loess"> method requires L<Math::LOESS>. At present those
dependencies are specified as "recommends" instead of "requires" of the 
C<Chart-GGPlot> distribution on CPAN. So depending on your cpan client
they may or may not be installed when you tell your cpan client to install
Chart::GGPlot. If you see errors about missing modules, you can install
the modules.

=head1 SEE ALSO

L<Chart::GGPlot::Stat>, L<Chart::GGPlot::Util::Stats>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
