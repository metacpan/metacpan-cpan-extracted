package Catalyst::View::Chart::Strip::Example;
use strict;
# POD Only, no code here.
1;

=head1 NAME

Catalyst::View::Chart::Strip::Example - Example Chart Data Generation

=head1 SYNOPSIS

This document contains an example Catalyst controller action which
generates a valid graph using L<Catalyst::View::Chart::Strip>.
The graph itself was lifted from the examples bundled with
L<Chart::Strip>, and modified a little to fit the data structure
style of L<Catalyst::View::Chart::Strip>.

Feel free to cut and paste this into a controller to see how
everything works, and as an example to work from while figuring out
how to chart real data from your Model classes.

Note that the last line of this action subroutine references the local
ChartStrip View-class, that you presumably setup via
C<script/myapp_create.pl view MyChartStrip Chart::Strip>.  You'll need
to change that to whatever you named your View class.

=head1 CODE

 sub sample_graph : Local {
    my ( $self, $c ) = @_;

    my @set;
    my( $data );

    for(my $t=0; $t<200; $t++){
        my $v = sin( $t/40 ) ;
        my $z = abs( sin( $t/8 )) / 2;
        push @$data, {
                time  => $^T + $t  * 5000,
                value => $v,
                min   => $v - $z,
                max   => $v + $z,
        };
    }

    push(@set, { data => $data, opts => { label => 'Drakh',
                                          style => 'range',
                                          color => '00FF00'} });

    push(@set, { data => $data, opts => { style => 'line',
                                          color => '0000FF'} });

    $data = [];
    for(my $t=10; $t<210; $t++){
        my $v = (.07,0,0,-.15,1,0,-.3,0,0,0,.07,.07)[$t % 25] || 0;
    
        push @$data, {
                time  => $^T + $t  * 5000,
                value => ($v + $t / 100 - 1.5),
        };
    }

    push(@set,{ data=> $data, opts => { label => 'Scarran',
                                        color => 'FF0000'} });

    $data = [];
    for(my $t=10; $t<210; $t+=15){

        push @$data, {
                time  => $^T + $t  * 5000,
                value => sin( $t/30 + 1 ) - .2,
                diam  => abs(20*sin($t/55 - 1)) + 3,
        };
    }

    push(@set, { data => $data, opts => { label => "G'ould",
                                          style => 'points',
                                          color => '0000FF'} });

    $c->stash->{chart_opts}->{title} =
        'Alient Experimentation on the Population of New England';
    $c->stash->{chart_data} = \@set;

    $c->forward('MyApp::View::MyChartStrip');
 }

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Catalyst::Helper::View::Chart::Strip>,
L<Catalyst::View::Chart::Strip>, L<Chart::Strip>,
L<Chart::Strip::Stacked>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

