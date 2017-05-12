package CGI::Application::Plugin::DevPopup::HTTPHeaders;
{
  $CGI::Application::Plugin::DevPopup::HTTPHeaders::VERSION = '1.08';
}

use strict;
use warnings;
no warnings 'uninitialized'; # don't care about empty strings
use base qw/Exporter/;

sub import
{
    my $c = scalar caller;
    $c->add_callback( 'devpopup_report', \&_header_report );
    goto &Exporter::import;
}

sub _header_report
{
    my $self = shift;
    my $env = _env_report($self);
    my $cgi = _cgi_report($self);
    my $out = $self->query->header($self->header_props);
    $out =~ s/\r//g;
    
    $self->devpopup->add_report(
        title => 'HTTP Headers',
        summary => 'Incoming and outgoing HTTP headers',
        report => qq(
        <style type="text/css">
        tr.even{background-color:#eee}
        </style>
        <table><thead><th colspan="2">Incoming HTTP Headers</th></thead><tbody> $cgi </tbody></table>
        <table><thead><th colspan="2">Outgoing HTTP Headers</th></thead><tbody><tr><td style="white-space:pre">$out</td></tr></tbody></table>
        <table><thead><th colspan="2">Environment Dump</th></thead><tbody><tr><td> $env </td></tr></tbody></table>
        )
    );
}

sub _env_report
{
    my $self = shift;
    my $r=0;
    my $report = join $/, map {
                    $r=1-$r;
                    qq{<tr class="@{[$r?'odd':'even']}"><td valign="top"> $_ </td><td> $ENV{$_} </td></tr>}
                }
                sort keys %ENV;

    return $report;
}

sub _cgi_report
{
    my $self = shift;

    my $r=0;
    my $q = $self->query;
    my $report = '';
    
    eval {
        $report = '<tr><th colspan="2">http</th></tr>' . 
            join $/, map {
                    $r=1-$r;
                    qq{<tr class="@{[$r?'odd':'even']}"><td valign="top"> $_ </td><td> @{[$q->http($_)]} </td></tr>}
                }
                sort $q->http;
    };

    return "<tr><td>Your query object doesn't have a http() method</td></tr>" if $@;

    eval {
        $report .= '<tr><th colspan="2">https</th></tr>' . 
            join $/, , map {
                    $r=1-$r;
                    qq{<tr class="@{[$r?'odd':'even']}"><td valign="top"> $_ </td><td> @{[$q->https($_)]} </td></tr>}
                }
                sort $q->https if $q->https;
    };
    
    return $report;
}

1;    # End of CGI::Application::Plugin::DevPopup::HTTPHeaders

__END__

=head1 NAME

CGI::Application::Plugin::DevPopup::HTTPHeaders - show incoming and outgoing HTTP headers

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DevPopup::HTTPHeaders;

    The rest of your application follows
    ...

Output looks roughly like this:

    Incoming HTTP Headers
    -----------------------------------
    http
    -----------------------------------
    HTTP_ACCEPT         text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    HTTP_ACCEPT_CHARSET UTF-8,*;q=0.5
    HTTP_HOST           www.example.com
    
    Outgoing HTTP Headers
    -----------------------------------
    Content-Type: text/html; charset=utf8
    
    Environment Dump
    -----------------------------------
    CAP_DEVPOPUP_EXEC   1
    DOCUMENT_ROOT       /var/www/html
    GATEWAY_INTERFACE   CGI/1.1
    QUERY_STRING
    REMOTE_ADDR         127.0.0.1

=head1 LIMITATIONS

For obvious reasons, the outgoing headers only display what CGI::Application will generate.

=head1 SEE ALSO

L<CGI::Application::Plugin::DevPopup>, L<CGI::Application>

=head1 AUTHOR

Rhesa Rozendaal, L<rhesa@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
L<bug-cgi-application-plugin-devpopup@rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-DevPopup>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
