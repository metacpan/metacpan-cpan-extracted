package Chart::GGPlot::Geom::Bar;

# ABSTRACT: Class for bar geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

extends qw(Chart::GGPlot::Geom::Rect);

our $VERSION = '0.002003'; # VERSION

use Chart::GGPlot::Aes;
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(:all);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

has '+non_missing_aes' => ( default => sub { [qw(xmin xmax ymin ymax)] } );

classmethod required_aes() { [qw(x y)] }
classmethod extra_params() { [qw(na_rm width)] }

my $geom_bar_pod = layer_func_pod(<<'EOT');

        geom_bar(:$mapping=undef, :$data=undef, :$stat='count',
                 :$position='stack', :$width=undef,
                 :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                 %rest)

    The "bar" geom makes the height bar proportional to the number of cases
    in each group (or if the C<weight> aesthetic is supplied, the sum of the
    C<weights>). 
    It uses C<stat_count()> by default: it counts the number of cases at
    each x position. 

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =item * $width

    Bar width. By default, set to 90% of the resolution of the data.

    =back

    See also L<Chart::GGPlot::Stat::Functions/stat_count>.

EOT

my $geom_bar_code = fun (
        :$mapping = undef, :$data = undef,
        :$stat = 'count', :$position = 'stack',
        :$width = undef, :$na_rm = false,
        :$show_legend = undef, :$inherit_aes = true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'bar',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            width => $width,
            na_rm => $na_rm,
            %rest,
        },
    );
};

my $geom_histogram_pod = layer_func_pod(<<'EOT');

        geom_histogram(:$mapping=undef, :$data=undef, :$stat="bin",
                       :$position="stack", :$binwidth=undef, :$bins=undef,
                       :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                       %rest)

    Visualise the distribution of a single continuous variable by dividing
    the x axis into bins and counting the number of observations in each
    bin. This "histogram" geom displays the counts with bars.

    =over 4

    %TMPL_COMMON_ARGS%

    =item * $binwidth

    The width of the bins.
    Can be specified as a numeric value, or a function that calculates width
    from x. The default is to use C<$bins> bins that cover the range of the
    data.

    =item * $bins

    Number of bins. Overridden by C<$binwidth>. Defaults to 30.

    You should always override this C<$bins> or C<$binwidth>, exploring
    multiple widths to find the best to illustrate the stories in your data.

    =back

    See also L<Chart::GGPlot::Stat::Functions/stat_bin>.

EOT

my $geom_histogram_code = fun (
        :$data = undef, :$mapping = undef,
        :$stat = "bin", :$position = "stack",
        :$binwidth = undef, :$bins = undef,
        :$na_rm = false,
        :$show_legend = undef, :$inherit_aes = true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'bar',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            binwidth => $binwidth,
            bins     => $bins,
            na_rm    => $na_rm,
            pad      => false,
            %rest
        },
    );  
};

my $geom_col_pod = layer_func_pod(<<'EOT');

        geom_col(:$mapping=undef, :$data=undef, :$position="stack",
                 :$width=undef, :$na_rm=false, :$show_legend=undef,
                 :$inherit_aes=true,
                 %rest)

    Bar plot. Different from geom_bar(), geom_col() uses stat_identity():
    it leaves the data as is.

    =over 4

    %TMPL_COMMON_ARGS%

    =item * $width

    Bar width. By default, set to 90% of the resolution of the data.

    =back

EOT

my $geom_col_code = fun (
        :$data = undef, :$mapping = undef, :$position = "stack",
        :$width = undef,
        :$na_rm = false, :$show_legend = undef, :$inherit_aes = true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => 'identity',
        geom        => 'bar',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            width => $width,
            na_rm => $na_rm,
            %rest,
        },
    );  
};

classmethod ggplot_functions() {
    return [
        {
            name => 'geom_bar',
            code => $geom_bar_code,
            pod => $geom_bar_pod,
        },
        {
            name => 'geom_histogram',
            code => $geom_histogram_code,
            pod => $geom_histogram_pod,
        },
        {
            name => 'geom_col',
            code => $geom_col_code,
            pod => $geom_col_pod,
        },
    ];  
}

method setup_data ($data, $params) {
    unless ( $data->exists('width') ) {
        $data->set( 'width',
            $params->at('width')
              // pdl( resolution( $data->at('x'), false ) * 0.9 ) );
    }
    return $data->transform( {
            ymin => fun($col, $df) { pmin($df->at('y'), 0) }, 
            ymax => fun($col, $df) { pmax($df->at('y'), 0) },
            xmin => fun($col, $df) { $df->at('x') - $df->at('width') / 2 },
            xmax => fun($col, $df) { $df->at('x') + $df->at('width') / 2 },
            width => undef,
        } );
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Bar - Class for bar geom

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
