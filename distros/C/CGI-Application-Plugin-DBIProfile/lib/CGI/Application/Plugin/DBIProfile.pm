package CGI::Application::Plugin::DBIProfile;

use strict;

use CGI::Application::Plugin::DBIProfile::Driver;
# DBI::ProfileData doesn't support reading from filehandles.
#use DBI::ProfileData;
use CGI::Application::Plugin::DBIProfile::Data;

use IO::Scalar;
use HTML::Template;
use Data::JavaScript;


use vars qw($VERSION);

our $VERSION = '0.07';

sub import
{
    my $c = scalar caller;
    if ($ENV{CAP_DBIPROFILE_EXEC})
    {
        $c->add_callback( 'prerun', \&_start );
        # use devpopup if installed, or do our own thing.
        if ($c->can('devpopup') && $ENV{'CAP_DEVPOPUP_EXEC'})
        {
            $c->add_callback( 'devpopup_report', \&_devpopup_stop);
        } else {
            $c->add_callback( 'postrun', \&_stop);
        }
    }
}

# _start : clear anything that is currently stored (incase stuff ran without us)
sub _start
{
    my $self = shift;

    _empty_profile();
}

# _stop : standalone report output, called in postrun hook.
sub _stop
{
    my ($self, $output) = @_;

    # header handling borrowed from CAP::DevPopup
    return unless $self->header_type eq 'header';       # don't operate on redirects or 'none'
    my %props = $self->header_props;
    my ($type) = grep /type/i, keys %props;
    return if defined $type and                         # no type defaults to html, so we have work to do.
      $props{$type} !~ /html/i;                         # else skip any other types.


    our $TEMPLATE2;

    my $template = HTML::Template->new(scalarref        => \$TEMPLATE2 );
    $template->param(page_body => _build_content($self) );

    my $content = $template->output();

    _open_window($self, $content, $output);

    _empty_profile();
}

# _devpopup_stop : similar to _stop, but compatable with CAP:DevPopup
sub _devpopup_stop
{
    my $self = shift;
    my $output = shift;

    my $content = _build_content($self);

    $self->devpopup->add_report(
        title => 'DBI Profile',
        summary => 'DBI statement profiling',
        report => qq(
        <style type="text/css">
        tr.even{background-color:#eee}
        </style>
        <table><tbody> $content </tbody></table>
        )
    );

    _empty_profile();
}

# clear profile if running in per-request (unless running in per-process)
sub _empty_profile
{
    unless ($ENV{CAP_DBIPROFILE_PERPROCESS}) {
        CGI::Application::Plugin::DBIProfile::Driver->empty();
    }
}

# main content builder. Builds datasets, and pushs to template.
sub _build_content
{
    my $self = shift;

    my %opts = (
        number  => $self->param('__DBIProfile_number') || 10,
        );

    my @pages;

    # for each sort type, add a graph in a hidden div
    foreach my $sort (qw(total count shortest longest))
    {
        my $page = {};

        my ($nodes, $data) = _get_nodes($self, (%opts, sort => $sort) );

        my @legends = map { $nodes->[$_][7] } (0 .. $#$nodes);
        my $count   = 1;
        $$page{sort}          = $sort;
        $$page{legend_loop}   = [ map { { number => $count++, legend => $_ } } @legends];
        $$page{profile_title} = _page_title($self, (%opts, sort => $sort) );
        $$page{profile_text}  = join("\n\n", map { $data->format($nodes->[$_]) } (0 .. $#$nodes));
        $$page{profile_graph} = _dbiprof_graph($self, (%opts, sort => $sort, nodes => $nodes) );

        push(@pages, $page);
    }

    our $TEMPLATE;

    my $template = HTML::Template->new(scalarref        => \$TEMPLATE,
                                       loop_context_vars => 1, );
    $template->param(profile_pages => \@pages);

    # add full text only dump of all data (well, last 1000 queries)
    my ($nodes, $data) = _get_nodes($self, number => 1000, sort => 'count');
    $template->param('profile_full_text', join("\n\n", map { $data->format($nodes->[$_]) } (0 .. $#$nodes)) );

    return $template->output();
}

# wrapper to ease getting data from DBI
sub _get_nodes
{
    my $self = shift;
    my %opts = @_;

    my $sort   = $opts{sort};
    my $number = $opts{number};

    my $profile_data = CGI::Application::Plugin::DBIProfile::Driver->get_current_stats();

    my $fh = new IO::Scalar \$profile_data;

    my $data = CGI::Application::Plugin::DBIProfile::Data->new(File => $fh);
    $data->sort(field => $sort);
    $data->exclude(key1 => qr/^\s*$/);

    # get list trimmed to number
    my $nodes  = $data->nodes();
    $number    = @$nodes if $number > @$nodes;
    $#$nodes   = $number - 1;

    return wantarray ? ($nodes, $data) : $nodes;
}

sub _open_window
{
    my ($self, $content, $output) = @_;

    my $js = qq|<script language="javascript">|;
    my $d = Data::JavaScript::jsdump( 'dbi_prof_data', [ $content ] );
    # an end script tag will mess things up... so we break the string.
    $d =~ s/<\/script>/<\/s"+"cript>/g;
    $js .= $d;
    $js   .= <<END;
  var dbi_prof_window = window.open("", "dbiprof_window_$$", "height=600,width=800,scrollbars=1,toolbars");
  dbi_prof_window.document.write(dbi_prof_data[0]);
  dbi_prof_window.document.close();
  dbi_prof_window.focus(); 
</script>
END

    if ($$output =~ m!</body>!i) {
        $$output =~ s!</body>!$js\n</body>!i;
    } else {
        $$output .= $js;
    }
}

sub _page_title
{
    my $self = shift;
    my %opts = @_;

    my $title = "Top $opts{number} Statements By " .
                ($opts{sort} eq 'count' ? "Count of Executions" :
                            (ucfirst($opts{sort}) . " Runtime"));

}

sub _dbiprof_graph
{
    my $self = shift;
    my %opts = @_;

    my $nodes  = $opts{nodes};
    my $number = $opts{number};
    my $sort   = $opts{sort};

    my $index = $sort eq 'count'   ? 0 :
                $sort eq 'total'   ? 1 :
                $sort eq 'shortest'? 3 :
                $sort eq 'longest' ? 4 : die "Unknown sort '$sort'";

    my $title = _page_title($self, %opts);
    my $data  = [ map { $nodes->[$_][$index] } (0 .. $#$nodes) ];
    my $tag   = 1;
    my $tags  = [ map { $tag++ } @$data ];

    # load graphing plugin, and run it.
    my $graph_plug = _load_graph_module ($self);

    my $graph = $graph_plug->build_graph(
                        self        => $self,
                        mode_param  => $self->mode_param,
                        title       => $title,
                        ylabel      => $sort eq 'count' ? 'Count' : 'Seconds',
                        data        => $data,
                        tags        => $tags,
                        );
    warn "Unable to build graph." unless defined $graph;

    return ref($graph) ? $$graph : $graph  || "";
}

sub _load_graph_module
{
    my $self = shift;

    my $module = $ENV{CAP_DBIPROFILE_GRAPHMODULE};
    $module  ||= 'CGI::Application::Plugin::DBIProfile::Graph::HTML';

    eval "require $module";

    if ($@)
    {
        die "CAP::DBIProfile: Unable to load graphing module \"$module\": $@";
    }

    return $module;
}

our $TEMPLATE2 = <<END2;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>

<head>
  <title>CGI::Application::Plugin::DBIProfile Profiling Screen</title>

    <style type="text/css">
        div.report { border: dotted 1px black; margin: 1em;}
        div.report h2 { color: #000; background-color: #ddd; padding:.2em; margin-top:0;}
        div.report_full, div.report_summary { padding: 0em 1em; }
        a:hover, div.report h2:hover { cursor: pointer; background-color: #eee; }
        a { text-decoration: underline }
    </style>

    <script language="javascript"><!--
        function swap(id1,id2)
        {
            var d1 = document.getElementById(id1);
            var d2 = document.getElementById(id2);
            var s = d1.style.display;
            d1.style.display = d2.style.display;
            d2.style.display = s;
        }
    // --></script>


</head>

<body onload="swap('#DBIPS_count', '#DBIPR_count');">
<div class="report">

<tmpl_var page_body>

</div>
</body></html>

END2

our $TEMPLATE = <<END;

<style type="text/css">
   .legend_header {
     background-color: #7187C7;
     color: #FFF;
   }
   .legend_odd_row {
     background-color: #FFF;
   }
   .legend_even_row {
     background-color: #EEE;
   }
</style>

<table border=0 cellspacing=0 cellpadding=0 width=100%>

<tr>
<td valign="top">

<tmpl_loop profile_pages>

  <h2 onclick="swap('#DBIPS_<tmpl_var sort>', '#DBIPR_<tmpl_var sort>');"><tmpl_var profile_title></h2>

  <div id="#DBIPS_<tmpl_var sort>" class="report_summary"></div>
  <div id="#DBIPR_<tmpl_var sort>" class="report_full" style="display:none">

    <span><tmpl_var profile_graph></span>

    <table border=0 width=100% cellspacing=0 style="margin: 5px">
    <tr>
      <td class="legend_header" align="center">#</td>
      <td class="legend_header" width="90%">SQL Statement</td>
    </tr>
    <tmpl_loop legend_loop>
      <tr>
        <td <tmpl_if __odd__>class="legend_odd_row"<tmpl_else>class="legend_even_row"</tmpl_if>><tmpl_var number></td>
        <td <tmpl_if __odd__>class="legend_odd_row"<tmpl_else>class="legend_even_row"</tmpl_if>><tmpl_var legend></td>
      </tr>
    </tmpl_loop>
    </table>

    <table border=0 cellspacing=0 cellpadding=0 width=100%>
    <tr>
    <td valign="top">
        <h2 onclick="swap('#DBIPS_t_<tmpl_var sort>', '#DBIPR_t_<tmpl_var sort>');">Full Text Profile Dump</h2>
        <div id="#DBIPS_t_<tmpl_var sort>" class="report_summary"></div>
        <div id="#DBIPR_t_<tmpl_var sort>" class="report_full" style="display:none">
            <span  style="white-space: pre;"><tmpl_var profile_text></span>
        </div>
    </td>
    </tr>
    </table>

  </div>

</tmpl_loop>

<!-- full dump of log -->
<h2 onclick="swap('#DBIPS_full', '#DBIPR_full');">Full Text Dump By Runtime</h2>
<div id="#DBIPS_full" class="report_summary"></div>
<div id="#DBIPR_full" class="report_full" style="display:none">
    <span  style="white-space: pre;"><tmpl_var profile_full_text></span>
</div>

</td>

</tr></table>

END



1;

__END__

=head1 NAME

CGI::Application::Plugin::DBIProfile - DBI profiling plugin

=head1 SYNOPSIS

    # Set env in apache or in perl.
    $ENV{DBI_PROFILE} = '2/CGI::Application::Plugin::DBIProfile::Driver';
    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DBIProfile;

    The rest of your application follows
    ...

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make 
    make test
    make install

=head1 DESCRIPTION

CGI::Application::Plugin::DBIProfile provides popup (using CAP::DevPopup if available) holding DBI Profile information (see L<DBI::Profile>, L<DBI::ProfileDumper>). It will output both graphed output and a DBI::ProfileDumper report.

=head1 CONFIGURATION

To enable, set the DBI_PROFILE environment variables. For example

=over

=item in apache config for cgi

    SetVar DBI_PROFILE 2/CGI::Application::Plugin::DBIProfile::Driver
    SetVar CAP_DBIPROFILE_EXEC 1

=item in apache config for mod_perl

    PerlSetVar DBI_PROFILE 2/CGI::Application::Plugin::DBIProfile::Driver
    PerlSetVar CAP_DBIPROFILE_EXEC 1

=item in your CAP module

    BEGIN {
        $ENV{DBI_PROFILE} = '2/CGI::Application::Plugin::DBIProfile::Driver';
        $ENV{CAP_DBIPROFILE_EXEC} = 1;
    }

=back

If you disable it, be sure to unset the DBI_PROFILE env var, as it will continue to accumulate stats regardless of the setting of CAP_DBIPROFILE_EXEC, you just won't see them.

=head2 MODES OF OPERATION

It has two modes of opperation; per-request or per-process. In a CGI environment, there is no difference.

=over

=item per-request - this is the default.

=item per-process - set the following env var to a true value.

    CAP_DBIPROFILE_PERPROCESS 1

=back

Under mod_perl, the per-request setup will show the DBI Profile specific to each page hit.
The per-process setup will show the DBI Profile that has accumulated for the life of the apache process you are hitting.

Please note, running under the per-process setting can cause your memory usage to grow significantly, as the profile data is never cleared.

=head2 GRAPHING PLUGINS

The default graphing module is L<CGI::Application::Plugin::DBIProfile::Graph::HTML>, which generates a minimal inline HTML graph. To change which graphing plugin is used, it's just another environment variable (no need to set this if you like the default).

    CAP_DBIPROFILE_GRAPHMODULE Your::Graph::Module::Name

Please see  L<CGI::Application::Plugin::DBIProfile::Graph::HTML> for information on writing new graph modules.

=head1 TODO

Tests. None exist at this time.

Other graphing plugins (Plotr, Open Flash Chart, GraphML using Graph::Easy).

Add checks to be sure $dbh->{Profile} isn't disabled (probably better in ::Driver).

=head1 REQUIREMENTS

=over

=item L<Data::JavaScript>

=item L<IO::Scalar>

=item L<HTML::Template>

=back


Optional:

=over

=item * L<GD::Graph>

For CGI::Application::Plugin::DBIProfile::Graph::GDGraphInline support.

=item * L<SVG::TT::Graph>

For CGI::Application::Plugin::DBIProfile::Graph::SVGTT support.

=item * L<HTML::BarGraph>

For CGI::Application::Plugin::DBIProfile::Graph::HTMLBarGraph support.

=back

=head1 SEE ALSO

=over

=item L<CGI::Application>

=item L<CGI::Application::Plugin::DevPopup>

=item L<CGI::Application::Plugin::DBIProfile::Data>

=item L<CGI::Application::Plugin::DBIProfile::Driver>

=item L<CGI::Application::Plugin::DBIProfile::Graph::HTML>

=item L<CGI::Application::Plugin::DBIProfile::Graph::HTML::Horizontal>

=item L<CGI::Application::Plugin::DBIProfile::Graph::HTMLBarGraph>

=item L<CGI::Application::Plugin::DBIProfile::Graph::GDGraphInline>

=item L<CGI::Application::Plugin::DBIProfile::Graph::SVGTT>

=back

=head1 SPECIAL THANKS

To Sam Tregar, for the original codebase on which this was based, and DBI::ProfileDumper itself.

=head1 AUTHOR

    Sam Tregar, C<< <sam@tregar.com> >>
    Joshua I Miller, C<< <unrtst@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<bug-cgi-application-plugin-dbiprofile@rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-DBIProfile>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Joshua Miller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

