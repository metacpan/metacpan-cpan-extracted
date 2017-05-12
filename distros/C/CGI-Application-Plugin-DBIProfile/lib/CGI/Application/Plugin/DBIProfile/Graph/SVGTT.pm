package CGI::Application::Plugin::DBIProfile::Graph::SVGTT;

use strict;
use CGI();
use SVG::TT::Graph::Bar;

our $WIDTH  = 600;
our $HEIGHT = 300;

sub import
{
    my $c = scalar caller;
    $c->add_callback('init', \&_add_runmode);
}

sub _add_runmode
{
    my $self = shift;
    $self->run_modes( dbiprof_graph_svgtt => \&graph );
}

sub graph
{
    my $self = shift;

    my $q = $self->query();

    my %opts = (
        title   => $q->param('title'),
        ylabel  => $q->param('ylabel'),
        data    => [ $q->param('data') ],
        tags    => [ $q->param('tags') ],
        );

    $opts{data} ||= [];

    my $stmt_count = @{$opts{data}};
    my $title = "Top $stmt_count statements"; # by total runtime
    my $tag = 1;
    my $tags = [ map { $tag++ } @{$opts{data}} ];

    my %defs = (
        tags        => $tags,
        data        => [],
        title       => $title,
        ylabel      => '',
        );

    # merge options with defaults.
    %opts = (%defs, map { $_ => $opts{$_} }
                    grep { defined $opts{$_} }
                    keys %opts );

    # build the graph image
    my $graph_data;
    {
        # BUG in SVG::TT::Graph... if all values are less than 0.5,
        # the code to determine the scale ticks does an illegal division by zero
        # So, we turn on 'scale_integers' if that's the case.
        my $maxval = 0;
        foreach (@{$opts{data}}) {
            $maxval = $_ if $_ > $maxval;
        }
        my %extra_opt = ($maxval < 0.5) ? (scale_integers => 1) : ();

        my $graph = SVG::TT::Graph::Bar->new({
            width       => $WIDTH,
            height      => $HEIGHT,
            fields      => $opts{tags},
            graph_title => $opts{title},
            y_title     => $opts{ylabel},
            show_y_title        => 1,
            show_y_labels       => 1,
            show_graph_title    => 1,
            %extra_opt,
            });
        $graph->add_data({
            data        => $opts{data},
            title       => $opts{title},
            });
        $graph_data = $graph->burn();
    }

    $self->header_add(-type => 'image/svg+xml');
    return $graph_data;
}

sub build_graph
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %opts = @_;

    my $mode_param = $opts{mode_param} || 'rm';

    my @url;
    push(@url, $mode_param.'=dbiprof_graph_svgtt');
    push(@url, 'ylabel=' .CGI::escape($opts{ylabel}) );
    push(@url, 'title='  .CGI::escape($opts{title}) );
    my @data  = map { 'data=' .CGI::escape($_) }
                ref($opts{data}) ? @{$opts{data}} : ();
    push(@url, @data);
    my @tags  = map { 'tags=' .CGI::escape($_) }
                ref($opts{tags}) ? @{$opts{tags}} : ();
    push(@url, @tags);

    my $url = $opts{self}->query->url();
    $url   .= '?'.join('&', @url);

    my $h_title = CGI::escapeHTML($opts{title});
    #return qq(<img width="$WIDTH" height="$HEIGHT" src="$url">\n);

    # embed/object/iframe... dunno which is best
    # http://www.spartanicus.utvinternet.ie/embed.htm#svg
#    return qq(<object type="image/svg+xml" name="$h_title" width="$WIDTH" height="$HEIGHT"
#    data="$url">
#Requires SVG plugin.
#</object>);
    return qq(<embed type="image/svg+xml" src="$url" width="$WIDTH" height="$HEIGHT"  pluginspage="http://www.adobe.com/svg/viewer/install/" />);

}

1;

__END__

=head1 NAME

CGI::Application::Plugin::DBIProfile::Graph::SVGTT - SVT::TT::Graph::Bar Graph output for CAP:DBIProfile.

=head1 SYNOPSIS

    # in httpd.conf
    SetVar CAP_DBIPROFILE_GRAPHMODULE CGI::Application::Plugin::DBIProfile::Graph::SVGTT
    PerlSetVar CAP_DBIPROFILE_GRAPHMODULE CGI::Application::Plugin::DBIProfile::Graph::SVGTT

    # in your CGI::Application subclass (needed to install callback)
    use CGI::Application;
    use CGI::Application::Plugin::DBIProfile::Graph::SVGTT;


=head1 DESCRIPTION

This module provides a SVG::TT::Graph::Bars graphing option for CAP:DBIProfile.

This also provides an example of non-inline graphs for DBIProfile.

The following settings control the output:

=over

=item $CGI::Application::Plugin::DBIProfile::Graph::SVGTT::WIDTH

Width of output image.

=item $CGI::Application::Plugin::DBIProfile::Graph::SVGTT::HEIGHT

Height of output image.

=back

=head1 REQUIREMENTS

=over

=item L<SVG::TT::Graph>

=back

=head1 SEE ALSO

=over

=item L<SVG::TT::Graph::Bar>

=item L<CGI::Application::Plugin::DBIProfile>

=item L<CGI::Application::Plugin::DBIProfile::Graph::HTML>

=back

=head1 AUTHOR

    Joshua I Miller, L<unrtst@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Joshua Miller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
