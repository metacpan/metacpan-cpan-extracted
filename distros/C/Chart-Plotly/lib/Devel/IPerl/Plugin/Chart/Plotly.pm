package Devel::IPerl::Plugin::Chart::Plotly;

use strict;
use warnings;
use utf8;

use Module::Find;
use Chart::Plotly;
use namespace::autoclean;

our $VERSION = '0.039';    # VERSION

# ABSTRACT: Inline display of plotly charts in Jupyter notebooks using L<Devel::IPerl> kernel

my $parameter_list = "(" . join( ", ", Chart::Plotly::plotlyjs_plot_function_parameters() ) . ")";
my $require_plotly = <<'EOJSFP';
<script>
//# sourceURL=iperl-devel-plugin-chart-plotly.js
            $('#Plotly').each(function(i, e) { $(e).attr('id', 'plotly') });

            if (!window.Plotly) {
                requirejs.config({
                  paths: {
                    plotly: ['https://cdn.plot.ly/plotly-latest.min']},
                });
                window.Plotly = {
EOJSFP

$require_plotly .= Chart::Plotly::plotlyjs_plot_function() . " : function " . $parameter_list . "{\n";
$require_plotly .= <<'EOJSSP';
                    require(['plotly'], function(plotly) {
                      window.Plotly=plotly;
EOJSSP
$require_plotly .= "Plotly." . Chart::Plotly::plotlyjs_plot_function() . $parameter_list . ";";
$require_plotly .= <<'EOJSTP';
                    });
                  }
                }
            }
</script>
EOJSTP

sub register {

    # only works registering the plugin for each notebook
    require Chart::Plotly::Plot;
    require Role::Tiny;

    Role::Tiny->apply_roles_to_package( 'Chart::Plotly::Plot',
                                        q(Devel::IPerl::Plugin::Chart::Plotly::Plot::IPerlRole) );
    for my $module ( findsubmod('Chart::Plotly::Trace') ) {
        Role::Tiny->apply_roles_to_package( $module, q(Devel::IPerl::Plugin::Chart::Plotly::Plot::Trace::IPerlRole) );
    }
}

{
    package Devel::IPerl::Plugin::Chart::Plotly::Plot::IPerlRole;

    use Moo::Role;

    use Devel::IPerl::Display::HTML;

    sub iperl_data_representations {
        my ($plot) = @_;
        Devel::IPerl::Display::HTML->new( $require_plotly . $plot->html( load_plotly_using_script_tag => 0 ) )
          ->iperl_data_representations;
    }

}

{
    package Devel::IPerl::Plugin::Chart::Plotly::Plot::Trace::IPerlRole;

    use Moo::Role;

    use Devel::IPerl::Display::HTML;

    sub iperl_data_representations {
        require Chart::Plotly::Plot;
        my ($trace) = @_;
        my $plot = Chart::Plotly::Plot->new( traces => [$trace] );
        Devel::IPerl::Display::HTML->new( $require_plotly . $plot->html( load_plotly_using_script_tag => 0 ) )
          ->iperl_data_representations;
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::Chart::Plotly - Inline display of plotly charts in Jupyter notebooks using L<Devel::IPerl> kernel

=head1 VERSION

version 0.039

=head1 SYNOPSIS

    # In notebook
    IPerl->load_plugin('Chart::Plotly');

    # Trace objects get displayed automatically
    use Chart::Plotly::Trace::Scatter;
    my $scatter_trace = Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] );

    # Also Plot objects
    use Chart::Plotly::Trace::Box;
    use Chart::Plotly::Plot;

    my $x = [ 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3 ];
    my $box1 = Chart::Plotly::Trace::Box->new( x => $x, y => [ map { rand() } ( 1 .. ( scalar(@$x) ) ) ], name => "box1" );
    my $box2 = Chart::Plotly::Trace::Box->new( x => $x, y => [ map { rand() } ( 1 .. ( scalar(@$x) ) ) ], name => "box2" );
    my $plot = Chart::Plotly::Plot->new( traces => [ $box1, $box2 ], layout => { boxmode => 'group' } );

=head1 DESCRIPTION

Plugin to display automatically L<Chart::Plotly> plot objects in Jupyter notebooks using kernel L<Devel::IPerl>

The example above can be viewed in L<nbviewer|http://nbviewer.jupyter.org/github/pablrod/p5-Devel-IPerl-Plugin-Chart-Plotly/blob/master/examples/PlotlyPlugin.ipynb>

=for Pod::Coverage EVERYTHING

=head1 INSTANCE METHODS

=head2 register

This method is called automatically by L<Devel::IPerl>. You only need to load the plugin:

    IPerl->load_plugin('Chart::Plotly');

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
