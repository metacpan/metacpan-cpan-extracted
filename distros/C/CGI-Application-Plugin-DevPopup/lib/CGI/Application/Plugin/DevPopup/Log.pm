package CGI::Application::Plugin::DevPopup::Log;
{
  $CGI::Application::Plugin::DevPopup::Log::VERSION = '1.08';
}

use strict;
use IO::Scalar;
use base qw/Exporter/;
use vars qw($VERSION @EXPORT);

@EXPORT = qw(devpopup_log_handle);

sub import
{
    my $c = scalar caller;
    $c->add_callback( 'devpopup_report', \&_header_report );
    goto &Exporter::import;
}

sub _header_report
{
    my $self = shift;

    my $log = _log_report($self);

    $self->devpopup->add_report(
        title => 'Logs',
        summary => '',
        report => qq(
        <style type="text/css">
        tr.even{background-color:#eee}
        </style>
        <table><thead><th colspan="1">Logs</th></thead><tbody> $log </tbody></table>
        )
    );
}

sub _log_report
{
    my $self = shift;
    my $data = $self->{__DEVPOPUP_LOGDATA};
    return '' unless (ref $data eq 'SCALAR');
    my $r=0;
    my $report = join $/, map {
                    $r=1-$r;
                    qq{<tr class="@{[$r?'odd':'even']}"><td style="white-space: pre;"> $_ </td></tr>}
                }
                split /\n/, $$data;

    return $report;
}

sub devpopup_log_handle
{
    my $this = shift;

    unless (ref $this->{__DEVPOPUP_LOGFH})
    {
        my $data = '';
        $this->{__DEVPOPUP_LOGDATA} = \$data;
        my $fh = new IO::Scalar \$data;
        $this->{__DEVPOPUP_LOGFH} = $fh;
    }

    return $this->{__DEVPOPUP_LOGFH};
}

1;    # End of CGI::Application::Plugin::DevPopup::Log

__END__

=head1 NAME

CGI::Application::Plugin::DevPopup::Log - show all data written to an IO::Scalar handle.

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DevPopup::Log;

    sub cgiapp_init {
        # example using LogDispatch
        my $log_fh = $this->devpopup_log_handle;
        $this->log_config(
            APPEND_NEWLINE => 1,
            LOG_DISPATCH_MODULES => [
                    {   module      => 'Log::Dispatch::Handle',
                        name        => 'popup',
                        min_level   => $ENV{CAP_DEVPOPUP_LOGDISPATCH_LEVEL} || 'debug',
                        handle      => $log_fh,
                    },
                ]
            );
        $this->log->debug("log something");
    }
    The rest of your application follows
    ...

=head1 DESCRIPTION

CGI::Application::Plugin::DevPopup::Log will create a "Log" section in the DevPopup output. All data written to the filehandle returned by C<$this-E<gt>devpopup_log_handle> will be output.

L<CGI::Application::Plugin::LogDispatch> is very handy for this, but you can write to that filehandle anyway you'd like.

=head1 METHODS

=over

=item devpopup_log_handle

Generates a (fake) filehandle you can pass on to a logging plugin. See the Synopsis for usage.

=back

=head1 SEE ALSO

    L<CGI::Application::Plugin::DevPopup>
    L<CGI::Application>
    L<CGI::Application::Plugin::LogDispatch>

=head1 AUTHOR

Joshua I Miller, L<unrtst@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
L<bug-cgi-application-plugin-devpopup@rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-DevPopup>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Joshua Miller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
