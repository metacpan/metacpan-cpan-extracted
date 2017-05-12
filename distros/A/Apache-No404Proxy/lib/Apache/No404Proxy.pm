package Apache::No404Proxy;

use strict;
use vars qw($VERSION);
$VERSION = 0.05;

use Apache::Constants qw(:response);
use LWP::UserAgent;
use URI;

sub handler($$) {
    my($class, $r) = @_;
    return DECLINED unless $r->proxyreq;
    $r->handler('perl-script');
    $r->set_handlers(PerlHandler => [ sub { $class->proxy_handler($r); } ]);
    return OK;
}

sub proxy_handler {
    my($class, $r) = @_;
    my $request = HTTP::Request->new($r->method, $r->uri);
    my %headers_in = $r->headers_in;

    while(my($key, $val) = each %headers_in) {
	$request->header($key, $val);
    }

    if ($r->method eq 'POST') {
	$request->content(scalar $r->content);
    }

    my $res = LWP::UserAgent->new->simple_request($request);
    $r->content_type($res->header('Content-type'));

    my $body;
    if ($res->code == 404 && ! $class->exclude($r->uri)) {
	$body = $class->fetch($r);
	unless ($body) {
	    require Apache::Log;
	    $r->log->error('Apache::No404Proxy: no cache found');
	    return NOT_FOUND;
	}
    } else {
	$body = $res->content;
    }

    $r->status($res->code);
    $r->status_line($res->status_line);
    my $table = $r->headers_out;
    $res->scan(sub { $table->add(@_); });
    $r->send_http_header();
    $r->print($body);

    return OK;
}

# default excludes image files
sub exclude {
    my($class, $uri) = @_;
    return $uri =~ /\.(?:gif|jpe?g|png)$/i;
}

sub fetch {
    my($class, $r) = @_;

    # Default to Google. Oddly enough delegating to my own child!
    require Apache::No404Proxy::Google;
    Apache::No404Proxy::Google->fetch($r);
}


1;
__END__

=head1 NAME

Apache::No404Proxy - 404 free Proxy

=head1 SYNOPSIS

  # in httpd.conf
  PerlTransHandler Apache::No404Proxy # default uses ::Google
  PerlSetVar GoogleLicenseKey **************

=head1 DESCRIPTION

Oops, 404 Not found. But wait..., there is a Google cache!

Apache::No404Proxy serves as a proxy server, which automaticaly
detects 404 responses and fetches Google cache via SOAP. You need your
Google account to use this module. See Google Web API terms for
details.

Set your browser's proxy setting to Apache::No404Proxy based server,
and it becomes 404 free now!

=head1 AUTHOR

Tastuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module comes B<WITHOUT ANY WARRANTY>.

=head1 SEE ALSO

L<Apache::ProxyPassThru>, http://www.google.com/apis/

=cut
