package Apache::ProxyPassThru;
use strict;
use LWP::UserAgent ();
use Apache::Constants ':common';

my $VERSION = "0.11";

sub handler {
    my($r) = @_;
    return DECLINED unless $r->proxyreq;
    $r->handler("perl-script"); #ok, let's do it
    $r->push_handlers(PerlHandler => \&proxy_handler);
    return OK;
}

sub proxy_handler {
    my($r) = @_;
    my($key,$val);

    my $request = new HTTP::Request $r->method, $r->uri;

    my(%headers_in) = $r->headers_in;
    while(($key,$val) = each %headers_in) {
	$request->header($key,$val);
    }

    if ($r->method eq 'POST') {
       $request->content(scalar $r->content);
    }

    my $res = (new LWP::UserAgent)->simple_request($request);
    $r->content_type($res->header('Content-type'));
    #feed reponse back into our request_rec*
    $r->status($res->code);
    $r->status_line($res->status_line);
    my $table = $r->headers_out;
    $res->scan(sub {
        $table->add(@_);
    });

    $r->send_http_header();
    $r->print($res->content);

    $r->notes("DumpHeaders", "proxypassthru")
      if $r->dir_config("ProxyPassThru_DumpHeaders");

    return OK;
}

1;

__END__

=head1 NAME

Apache::ProxyPassThru - Skeleton for vanilla proxy

=head1 SYNOPSIS

 #httpd.conf or some such
 PerlTransHandler  Apache::ProxyPassThru
 PerlSetVar        ProxyPassThru_DumpHeaders 1

=head1 DESCRIPTION

This module uses libwww-perl as it's web client, feeding the response
back into the Apache API request_rec structure.
`PerlHandler' will only be invoked if the request is a proxy request,
otherwise, your normal server configuration will handle the request.

If used with the Apache::DumpHeaders module it lets you view the
headers from another site you are accessing.

=head1 PARAMETERS

This module is configured with PerlSetVar's.

=head2 ProxyPassThru_DumpHeaders

If this is set to a true value we'll set r->notes("DumpHeaders") to
"proxypassthru" to get the request logged in the log. This is usually
what you want.

Makes it easy to have Apache::DumpHeaders only dump headers from your
proxied requests.

=head1 SUPPORT

The latest version of this module can be found at CPAN and at
L<http://develooper.com/code/Apache::DumpHeaders/>. Send questions and
suggestions to the modperl mailinglist (see L<http://perl.apache.org/>
for information) or directly to the author (see below).

=head1 SEE ALSO

mod_perl(3), Apache(3), LWP::UserAgent(3)

=head1 AUTHOR

Ask Bjoern Hansen <ask@develooper.com>. 

Originally by Doug MacEachern.


