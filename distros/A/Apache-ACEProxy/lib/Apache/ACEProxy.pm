package Apache::ACEProxy;

use strict;
use vars qw($VERSION);
$VERSION = 0.04;

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

    # URI & Host: header conversion
    $class->prepare_ace($r, $request);

    my $res = LWP::UserAgent->new->simple_request($request);
    $r->content_type($res->header('Content-type'));

    $r->status($res->code);
    $r->status_line($res->status_line);
    my $table = $r->headers_out;
    $res->scan(sub { $table->add(@_); });
    $r->send_http_header();
    $r->print($res->content);

    return OK;
}

sub prepare_ace {
    my($class, $r, $request) = @_;

    # no ACE conversion
    return if $r->uri =~ /^[\x30-\x39\x41-\x5a\x61-\x7a\x2d\.]*$/;

    # Encode hostname to ACE
    my $uri = URI->new($r->uri);
    my $ace_host;
    eval {
        $ace_host = join '.', map {
	    # RFC 1035: letter, digit, hyphen
	    /^[\x30-\x39\x41-\x5a\x61-\x7a\x2d]*$/ ?
		$_ : $class->encode($_);
	} split /\./, $uri->host;
    };
    if ($@) {
	(my $exception = $@) =~ s/ at .*$//; chomp $exception;
	require Apache::Log;
	$r->log->error("Apache::ACEProxy: error happens while ACE conversion: $exception");
	return;
    }

    # set ACEd hostname in the request
    $uri->host($ace_host);
    $request->uri($uri);
    $request->header(Host => $ace_host);
}

sub encode {
    my($class, $domain) = @_;
    # Default to UTF8_RACE
    require Apache::ACEProxy::UTF8_RACE;
    Apache::ACEProxy::UTF8_RACE->encode($domain);
}

1;
__END__

=head1 NAME

Apache::ACEProxy - IDN compatible ACE proxy server

=head1 SYNOPSIS

  # in httpd.conf
  PerlTransHandler Apache::ACEProxy # default uses ::UTF8_RACE

=head1 DESCRIPTION

Apache::ACEProxy is a mod_perl based HTTP proxy server, which handles
internationalized domain names correctly. This module automaticaly
detects IDNs in HTTP requests and converts them in ACE encoding. Host:
headers in HTTP requests are also encoded in ACE.

Set your browser's proxy setting to Apache::ACEProxy based server, and
you can browse web-sites of multilingual domain names.

=head1 SUBCLASSING

Default ACE conversion is done from UTF8 to RACE. Here's how you
customize this.

=over 4

=item *

Declare your ACE encoder class (like DUDE, AMC-ACE-Z).

=item *

Inherit from Apache::ACEProxy.

=item *

Define C<encode()> class method.

=back

That's all. Here's an example of implementation, extracted from
Apache::ACEProxy::UTF8_RACE.

  package Apache::ACEProxy::UTF8_RACE;

  use base qw(Apache::ACEProxy);
  use Convert::RACE qw(to_race);
  use Unicode::String qw(utf8);

  sub encode {
      my($class, $domain) = @_;
      return to_race(utf8($domain)->utf16);
  }

Note that you should define C<encode()> method as a class
method. Argument $domain is a (maybe UTF8) string that your browser
sends to the proxy server.

At last, remember to add the following line to httpd.conf or so:

  PerlTransHandler Apache::ACEProxy::UTF8_RACE

=head1 CAVEATS

The default Apache::ACEProxy::UTF8_RACE assumes that input domain
names are encoded in UTF8. But currently it's known that:

=over 4

=item *

MSIE's "always send URL as UTF8" preference does B<NOT ALWAYS> send
correct UTF8 string.

=item *

Netscape 4.x does B<NOT> send URL as UTF8, but in local encodings.

=back

So, this proxy server doesn't always work well with all the domains
for all the browsers. If you figure out how your browser encodes
multilingual domain names, you can write your custom translator as in
L</"SUBCLASSING">. See also L<Apache::ACEProxy::SJIS_RACE> if your
mother language is Japanese.

Suggestions, patches and reports are welcome about this issue.

=head1 AUTHOR

Tastuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module comes with NO WARRANTY.

=head1 SEE ALSO

L<Apache::ProxyPassThru>, L<LWP::UserAgent>, L<Unicode::String>, L<Apache::ACEProxy::UTF8_RACE>, L<Apache::ACEProxy::SJIS_RACE>

=cut
