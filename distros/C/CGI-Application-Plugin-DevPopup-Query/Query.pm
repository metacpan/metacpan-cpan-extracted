package CGI::Application::Plugin::DevPopup::Query;

# $Id: Query.pm 30 2011-06-10 04:48:54Z stro $

use strict;
use warnings;
use English qw/-no_match_vars/;

use base qw/Exporter/;

our $VERSION = '1.03';

=head1 NAME

CGI::Application::Plugin::DevPopup::Query - show CGI query in DevPopup window

=head1 SYNOPSIS

    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DevPopup::Query;

    The rest of your application follows
    ...

=head1 DESCRIPTION

This module is a plugin for L<CGI::Application::Plugin::DevPopup|CGI::Application::Plugin::DevPopup>.
Whenever used, it creates two sections in the DevPopup output.
First section, "B<Current Run Mode>", shows name of run mode executed.
Second section, "B<CGI Query>", contains a list of CGI query parameters and
associated values passed to your CGI::Application.

See L<CGI::Application/query()> and L<CGI.pm|CGI.pm> for more information about query parameters.

=head1 VERSION

1.03

=head1 SUBROUTINES/METHODS

No public methods for this module exist.

=cut

sub import {
    my $c = scalar caller;
    $c->add_callback( 'devpopup_report', \&_runmode_report );
    $c->add_callback( 'devpopup_report', \&_query_report );
    goto &Exporter::import;
}

sub _runmode_report {
    my $self = shift;

    my $current_runmode = '<h3>' . ($self->get_current_runmode() || '<em>default</em>') . '</h3>';

    return $self->devpopup->add_report(
        'title'   => 'Current Run Mode',
        'summary' => $current_runmode,
        'report'  => $current_runmode,
    );
}

sub _query_report {
    my $self = shift;
    my $cgi = _cgi_report($self);

    my $current_runmode = $self->get_current_runmode() || 'default';

    return $self->devpopup->add_report(
        'title'   => 'CGI Query',
        'summary' => 'CGI request parameters',
        'report'  => qq!<style type="text/css">tr.even{background-color:#eee; } thead th h3 {margin: 0;}</style><table><thead><th colspan="2"><h3>CGI Query</h3></th></thead><tbody> $cgi </tbody></table>!,
    );
}

sub _cgi_report {
    my $self = shift;

    my $r = 0;
    my $q = $self->query;
    my $report = '<tr><th>param</th><th>value</th></tr>' .
            join ($INPUT_RECORD_SEPARATOR, map {
                    $r=1-$r;
                    qq!<tr class="@{[$r?'odd':'even']}"><td valign="top"> $_ </td><td> @{[$q->param($_)]} </td></tr>!
                  } sort $q->param());
    return $report;
}

1;

=head1 DEPENDENCIES

L<CGI::Application::Plugin::DevPopup|CGI::Application::Plugin::DevPopup>

=head1 CONFIGURATION AND ENVIRONMENT

N/A

=head1 DIAGNOSTICS

N/A

=head1 SEE ALSO

L<CGI::Application::Plugin::DevPopup|CGI::Application::Plugin::DevPopup>, L<CGI::Application|CGI::Application>

=head1 INCOMPATIBILITIES

Not known.

=head1 BUGS AND LIMITATIONS

Not known.

=head1 AUTHOR

Serguei Trouchelle, L<mailto:stro@cpan.org>

Most of code is based by CGI::Application::Plugin::DevPopup by Rhesa Rozendaal, L<mailto:rhesa@cpan.org>

=head1 LICENSE AND COPYRIGHT

This module is distributed under the same terms as Perl itself.

Copyright (c) 2009-2011 Serguei Trouchelle

=cut

