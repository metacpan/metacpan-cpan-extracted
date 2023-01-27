package Chart::GGPlot::Stat::Count;

# ABSTRACT: Statistic method that counts number of data in bin

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean -except => 'stat';
use MooseX::Singleton;

our $VERSION = '0.002002'; # VERSION

use Data::Frame;

use Chart::GGPlot::Aes::Functions qw(aes);
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(resolution stat);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

with qw(
  Chart::GGPlot::Stat
);

has '+default_aes'  => (
    default => sub {
        aes(
            y      => q{stat($count)},
            weight => 1,
        );
    }
);

classmethod required_aes() { ['x'] }

my $stat_count_pod = layer_func_pod(<<'EOT');

        stat_count(:$mapping=undef, :$data=undef,
                   :$geom='bar', :$position='stack', 
                   :$width=undef,
                   :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
                   %rest)

    Arguments:

    =over 4

    %TMPL_COMMON_ARGS%

    =item * $width

    Bar width. By default, set to 90% of the resolution of the data.

    =back

EOT

my $stat_count_code = fun (
        :$mapping = undef, :$data = undef,
        :$geom = 'bar', :$position = 'stack', 
        :$width = undef, :$na_rm = false,
        :$show_legend = undef, :$inherit_aes = true,
        %rest )
{ 
    my $params = { 
        na_rm => $na_rm,
        width => $width,
        %rest
    };  
    if ( $data->exists('y') ) { 
        die "stat_count() must not be used with a y aesthetic.";
    }   

    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => 'count',
        geom        => $geom,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => $params,
    );  
};

classmethod ggplot_functions() {
    return [
        {
            name => 'stat_count',
            code => $stat_count_code,
            pod  => $stat_count_pod,
        }
    ];
}

method setup_params ($data, $params) {
    if ( $data->exists('y') ) {
        die "stat_count() must not be used with a y aesthetic.";
    }
    return $params;
}

method compute_group ($data, $scales, $params) {
    my $width  = $params->at('width');

    my $x      = $data->at('x');
    my $weight =
        $data->exists('weight')
      ? $data->at('weight')
      : PDL::Core::ones($x->length);
    $width  = $width // pdl(resolution($x) * 0.9);

    # TODO: R does tapply() here. It's somewhat like groupby and then
    #  summarise on #  each group. We can change this once we have
    #  groupby + summarize in our data frame implementations.

    my $uniq = $x->uniq->qsort;
    my $count = pdl(
        $uniq->unpdl->map( sub { int( $weight->where( $x == $_ )->sum ) } )
    );
    $count->setbadtoval(0);

    return Data::Frame->new(
        columns => [
            count => $count,
            prop  => $count / $count->abs->sum,
            x     => $uniq,
            width => $width,
        ]
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Count - Statistic method that counts number of data in bin

=head1 VERSION

version 0.002002

=head1 SEE ALSO

L<Chart::GGPlot::Stat>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
