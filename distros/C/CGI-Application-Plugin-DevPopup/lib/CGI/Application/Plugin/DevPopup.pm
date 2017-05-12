package CGI::Application::Plugin::DevPopup;
{
  $CGI::Application::Plugin::DevPopup::VERSION = '1.08';
}

use warnings;
use strict;

use base 'Exporter';
use HTML::Template;
use CGI::Application 4.01;

our @EXPORT = qw/ devpopup /;

my ( $head, $script, $template );                       # html stuff for our screen

sub import
{
    my $caller = scalar(caller);
    $caller->add_callback( 'postrun', \&_devpopup_output ) if $ENV{'CAP_DEVPOPUP_EXEC'};
    $caller->new_hook('devpopup_report');
    goto &Exporter::import;
}

sub devpopup
{
    my $app = shift;                                    # a cgiapp object
    my $dp  = $app->param('__CAP_DEVPOPUP');
    unless ($dp)
    {
        $dp = bless [], __PACKAGE__;
        $app->param( '__CAP_DEVPOPUP' => $dp );
    }
    return $dp;
}

sub add_report
{
    my $self   = shift;                                 # a devpopup object
    my %params = @_;
    $params{severity} ||= 'info';
    push @$self, \%params;
}

sub _devpopup_output
{
    my ( $self, $outputref ) = @_;

    return unless $self->header_type eq 'header';       # don't operate on redirects or 'none'
    my %props = $self->header_props;
    my ($type) = grep /type/i, keys %props;
    return if defined $type and                         # no type defaults to html, so we have work to do.
      $props{$type} !~ /html/i;                         # else skip any other types.

    my $devpopup = $self->devpopup;
    $self->call_hook( 'devpopup_report', $outputref );  # process our callback hook

    my $tmpl = HTML::Template->new(
                                    scalarref         => \$template,
                                    die_on_bad_params => 0,
                                    loop_context_vars => 1,
                                  );
    $tmpl->param(
                  reports   => $devpopup,
                  app_class => ref($self),
                  runmode   => $self->get_current_runmode,
                );
    
    my $o = _escape_js($tmpl->output);
    my $h = _escape_js($head);
    my $j = _escape_js($script . join($/, map { $_->{script} } grep exists $_->{script},  @$devpopup) );

    my $js = qq{
    <script language="javascript">
    var devpopup_window = window.open("", "devpopup_window", "height=400,width=600,scrollbars,resizable");
    devpopup_window.document.write("$h");
    devpopup_window.document.write("\t<s");
    devpopup_window.document.write("cript type=\\"text/javascript\\">\\n");
    devpopup_window.document.write("//"+"<"+"![CDATA[\\n");
    
    devpopup_window.document.write("$j");
    devpopup_window.document.write("//]"+"]>\\n");
    devpopup_window.document.write("\t<");
    devpopup_window.document.write("/script>");
    devpopup_window.document.write("$o");
    devpopup_window.document.close();
    devpopup_window.focus();
    </script>
    };

    # insert the js code before the body close,
    # if one exists
    if ( $$outputref =~ m!</body>!i )
    {
        $$outputref =~ s!</body>!$js\n</body>!i;
    }
    else
    {
        $$outputref .= $js;
    }
}

sub _escape_js
{
    my $j = shift;
    $j =~ s/\r//g;
    $j =~ s/\\/\\\\/g;
    $j =~ s/"/\\"/g;
    $j =~ s/\n/\\n" + \n\t"/g;
    $j =~ s/script>/s" + "cript>/g;
    $j;
}

$head = <<HEAD;
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Devpopup results</title>
    <style type="text/css">
        div.report { border: dotted 1px black; margin: 1em;}
        div.report h2 { color: #000; background-color: #ddd; padding:.2em; margin-top:0;}
        div.report_full, div.report_summary { padding: 0em 1em; }
        a:hover, div.report h2:hover, a.print_button:hover { cursor: pointer; background-color: #eee; }
        a { text-decoration: underline }
        a.print_button { text-align: right; float: right; clear: right; padding: .2em; margin-right: 1em; color: #000; background-color:#ddd; border:solid 1px #444; }
        // severity colors
        .sev_debug             { background-color: #ccffcc; color: #000; }
        .sev_info              { } // default
        .sev_warning           { background-color: #ffff99; color: #000; }
        .sev_error             { background-color: #ff9999; color: #000; }
        .sev_fatal             { background-color: #ff6600; color: #fff; font-weight: bold; }
    </style>
HEAD

$script = <<JS;
        function swap(id1,id2)
        {
            var d1 = document.getElementById(id1);
            var d2 = document.getElementById(id2);
            var s = d1.style.display;
            d1.style.display = d2.style.display;
            d2.style.display = s;
        }
JS

$template = <<TMPL;
</head>
<body>
<h1>Devpopup report for <tmpl_var app_class> -&gt; <tmpl_var runmode></h1>
<a href="javascript:window.print()" class="print_button">Print</a>
<div id="titles">
<ul>
<tmpl_loop reports>
    <li class="sev_<tmpl_var severity>">
        <a onclick="swap('#DPS<tmpl_var __counter__>','#DPR<tmpl_var __counter__>')"><tmpl_var title></a> - <tmpl_var summary>
    </li>
</tmpl_loop>
</ul>
</div>

<tmpl_loop reports>
<div id="#DP<tmpl_var __counter__>" class="report">
    <h2 id="#DPH<tmpl_var __counter__>"
        class="sev_<tmpl_var severity>"
        onclick="swap('#DPS<tmpl_var __counter__>','#DPR<tmpl_var __counter__>')">
        <tmpl_var title>
    </h2>
    <div id="#DPS<tmpl_var __counter__>" class="report_summary">
        <tmpl_var summary>
    </div>
    <div id="#DPR<tmpl_var __counter__>" class="report_full" style="display:none"><tmpl_var report></div>
</div>
</tmpl_loop>

</body>
</html>
TMPL

1;    # End of CGI::Application::Plugin::DevPopup

__END__

=head1 NAME

CGI::Application::Plugin::DevPopup - Runtime cgiapp info in a popup window

=head1 VERSION

version 1.08

=head1 SYNOPSIS

=head2 End user information

This module provides a plugin framework for displaying runtime information
about your CGI::Application app in a popup window. A sample Timing plugin is
provided to show how it works:

    BEGIN { $ENV{'CAP_DEVPOPUP_EXEC'} = 1; } # turn it on for real
    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DevPopup::Timing;

    The rest of your application follows
    ...

Now whenever you access a runmode, a window pops up over your content, showing
information about how long the various stages have taken. Adding other
CAP::DevPopup plugins will get you more information. A HTML::Tidy plugin
showing you how your document conforms to W3C standards is available: see
L<CGI::Application::Plugin::HtmlTidy>.

The output consists of a Table of Contents, and a bunch of reports. A rough
translation into plain text could look like this:

    Devpopup report for My::App -> add_timing

    * Timings - Total runtime: 3.1178 sec.

    +-----------------------------------------------------------------------+
    | Timings                                                               |
    +-----------------------------------------------------------------------+
    | Application started at: Thu Sep 22 02:55:35 2005                      |
    | From                       To                         Time taken      |
    |-----------------------------------------------------------------------|
    | init                       prerun                     0.107513 sec.   |
    | prerun                     before expensive operation 0.000371 sec.   |
    | before expensive operation after expensive operation  3.006688 sec.   |
    | after expensive operation  load_tmpl(dp.html)         0.000379 sec.   |
    | load_tmpl(dp.html)         postrun                    0.002849 sec.   |
    +-----------------------------------------------------------------------+

The reports expand and collapse by clicking on the ToC entry or the report
header.

=head2 Developer information

Creating a new plugin for DevPopup is fairly simple. CAP::DevPopup registers a
new callback point (named C<devpopup_report>),  which it uses to collect output
from your plugin. You can add a callback to that point, and return your
formatted output from there. The callback has this signature:

    sub callback($cgiapp_class, $outputref)

You pass your output to the devpopup object by calling

    $cgiapp_class->devpopup->add_report(
                title   => $title,
                summary => $summary,
                report  => $body,
    );

You are receiving $outputref, because DevPopup wants to be the last one to be
called in the postrun callback. If you had wanted to act at postrun time, then
please do so with this variable, and not through a callback at postrun.

=head2 The C<on> switch

Since this is primarily a development plugin, and you wouldn't want it to run
in your production code, an environment variable named CAP_DEVPOPUP_EXEC has to
be set to 1 for this module to function, and it must be present at compile
time. This means you should place it in a BEGIN{} block, or use SetEnv or
PerlSetEnv (remember to set those before any PerlRequire or PerlModule lines).

Absence of the environment variable turns this module into a no-op: while the
plugin and its plugins are still loaded, they won't modify your output.

=head1 Available Plugins

=over 4

=item o L<CGI::Application::Plugin::DevPopup::Timing>,
L<CGI::Application::Plugin::DevPopup::Log> and
L<CGI::Application::Plugin::DevPopup::HTTPHeaders> are bundled with this
distribution.

=item o L<CGI::Application::Plugin::HtmlTidy> integrates with this module.

=item o L<CGI::Application::Plugin::TT> integrates with this module.

=back

=head1 EXPORTS

=over 4

=item * devpopup

This method is the only one exported into your module, and can be used to
access the underlying DevPopup object. See below for the methods that this
object exposes.

=back

=head1 METHODS

=over 4

=item * add_report( %fields )

Adds a new report about the current run of the application. The following
fields are supported:

=over 8

=item * title

A short title for your report

=item * summary

An optional one- or two-line summary of your findings

=item * report

Your full output

=item * severity

An optional value specifying the importance of your report. Accepted values
are qw/debug info warning error fatal/. This value is used to color-code the
report headers.

=item * script

If you have custom javascript, then please pass it in through this field.
Otherwise if it's embedded in your report, it will break the popup window. I
will take care of the surrounding C<<script>> tags, so just the code body is
needed.

=back

=back

=head1 INSTALLATION

INSTALLATION

To install this module, run:
    
    cpan CGI::Application::Plugin::DevPopup

To mnually install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 SEE ALSO

L<CGI::Application>. L<CGI::Application::Plugin::DevPopup::Timing>

=head1 AUTHOR

Rhesa Rozendaal, L<rhesa@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
L<bug-cgi-application-plugin-devpopup@rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-DevPopup>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=over

=item Mark Stosberg for the initial idea, and for pushing me to write it.

=item Sam Tregar for providing me with the skeleton cgiapp_postrun.

=item Joshua Miller for providing the ::Log plugin.

=item Everybody on the cgiapp mailinglist and on #cgiapp for cheering me on :-)

=back

=head1 COPYRIGHT & LICENSE

Copyright 2005-2007 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
