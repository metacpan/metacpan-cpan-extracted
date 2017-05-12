package CGI::Application::Plugin::DBIProfile::Graph::HTMLBarGraph;

use strict;
use HTML::Template;
use HTML::BarGraph;

# NOTE: HTML::BarGraph is a little broken on its pure HTML output.
# if you have issues, try changing the "bartype" to "pixel", and 
# setup the pixel directory ("/dbiprofile_images") in your webroot. 
# NOTE: HTML::BarGraph is also pure broken.. can't call graph more
# than once, cause your maxval scaling will stick!
sub build_graph
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %opts = @_;

    #my $self = { };
    #bless $self, $class;

    $opts{data} ||= [];

    my $stmt_count = @{$opts{data}};
    my $title = "Top $stmt_count statements"; # by total runtime
    my $tag = 1;
    my $tags = [ map { $tag++ } @{$opts{data}} ];

    my %defs = (
        direction       => 'v',
        graphminsize    => 50,
        bartype         => 'html', # pixel or html
        pixeldir        => '/dbiprofile_images',
        pixelfmt        => 'PNG',
        barlength       => 150,
        barwidth        => 10,
        #baraspect       => 0.5,
        colors          => ["#7187C7"], # this is color per-dataset.
        data            => [ ],
        tags            => $tags,
        setspacer       => 0,
        #highlighttag    => undef,
        #highlightpos    => [],
        addalt          => 1,
        showaxistags    => 1,
        showvalues      => 1,
        valuesuffix     => '', # s
        valueprefix     => '',
        bordertype      => 'flat', # reised or flat
        bordercolor     => 'black',
        borderwidth     => '3',
        bgcolor         => 'white',
        textcolor       => 'black',
        title           => $title,
        titlecolor      => 'black',
        titlealign      => 'center',
        fontface        => 'Verdana,Arial,San-Serif',
        xlabel          => '',
        ylabel          => 'Seconds',
        xlabelalign     => 'center',
        ylabelalign     => 'middle',
        labeltextcolor  => 'black',
        labelbgcolor    => '#aaaaaa',
        );
    %defs = (%defs, %opts);

    return HTML::BarGraph::graph(%defs);
}


1;

__END__

=head1 NAME

CGI::Application::Plugin::DBIProfile::Graph::HTMLBarGraph - If it weren't for HTML::BarGraph bugs, this would work.

=head1 DO NOT USE THIS

This is provided because I had it done, and it provides another example, but there are bugs in HTML::BarGraph.

If HTML::BarGraph ever gets fixed, this will start to work correctly. The problem is its use of globals to track things like $maxval, which throws off scaling of the graph for subsequent calls to graph().

=head1 BUGS

HTML::BarGraph is not mod_perl safe. It has globals that track, for instance, $maxval. That doesn't get reset accross calls to graph(), so whatever your largest value graphed is, that will set the scale of all graphs to come.
Actually, it's not even single process safe... you can't make more than one call to graph().

=head1 SEE ALSO

    L<CGI::Application::Plugin::DBIProfile>

=head1 AUTHOR

    Joshua I Miller, L<unrtst@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Joshua Miller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
