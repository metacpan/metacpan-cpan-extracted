package Curl::Impersonate;
use v5.10; use strict; use warnings;
use Carp ();
our $VERSION = '0.03';
require XSLoader;
XSLoader::load('Curl::Impersonate', $VERSION);

sub new {
    my ($class, %opt) = @_;
    my $self = _new($class);
    $self->_setopt_defaults(\%opt);
    if (defined $opt{impersonate}) {
        my $rc = $self->impersonate($opt{impersonate}, $opt{default_headers} // 1);
        Carp::croak("Curl::Impersonate: unknown impersonate target '$opt{impersonate}' (rc=$rc)")
            if $rc != 0;
    }
    return $self;
}

sub get { my ($s, $url) = @_; $s->request(method => 'GET', url => $url) }

sub request {
    my ($s, %a) = @_;
    Carp::croak('request: url is required') unless defined $a{url};
    return $s->_request($a{method} // 'GET', $a{url}, $a{headers} // {}, $a{body});
}

# Async: a curl_multi-backed handle. Drive it with perform_blocking (simple
# cases) or wire socket_action/timeout_ms into an event loop (see POD).
sub multi { Curl::Impersonate::Multi->_new }

package Curl::Impersonate::Multi;
# _new/DESTROY/add/perform_blocking/socket_action/timeout_ms/still_running/
# set_socket_callback/set_timer_callback are provided by the XS above.

1;

__END__

=head1 NAME

Curl::Impersonate - HTTP client that impersonates a browser's TLS/HTTP2 fingerprint

=head1 SYNOPSIS

    use Curl::Impersonate;

    # synchronous
    my $c   = Curl::Impersonate->new(impersonate => 'chrome131', timeout => 20);
    my $res = $c->get('https://example.com/');
    #   $res = { status => 200, headers => { 'content-type' => '...' }, body => '...' }

    my $post = $c->request(
        method  => 'POST',
        url     => 'https://example.com/api',
        headers => { 'content-type' => 'application/json' },
        body    => '{"hello":"world"}',
    );

    # which browsers can I be?
    my @targets = Curl::Impersonate->targets;

    # asynchronous (concurrent upstreams)
    my $m = Curl::Impersonate->multi;
    for my $url (@urls) {
        my $h = Curl::Impersonate->new(impersonate => 'chrome131');
        $m->add($h, { url => $url }, sub {
            my ($res, $err) = @_;
            $err ? warn($err) : print $res->{status}, "\n";
        });
    }
    $m->perform_blocking;

=head1 DESCRIPTION

Wraps C<libcurl-impersonate> (a patched libcurl built against BoringSSL, via
L<Alien::curlimpersonate>) so a request carries a chosen real browser's TLS
(JA3/JA4) and HTTP/2 (Akamai) connection fingerprint. Origin certificate
verification stays on by default; impersonation changes the handshake shape,
not whether the peer is verified.

This is an HTTP client, not a full browser. It reproduces the B<connection>
fingerprint (TLS + HTTP/2); it does not run JavaScript, and HTTP/3 and
WebSockets are out of scope in this release.

=head1 REQUIREMENTS

Requires L<Alien::curlimpersonate> 0.02 or newer, which builds
C<libcurl-impersonate> (a patched curl plus BoringSSL) from source at install
time. That build needs a C/C++ toolchain, cmake, ninja, go and patch -- see
that module for the details. No system C<libcurl-impersonate> is used.

=head1 METHODS

=head2 new

    my $c = Curl::Impersonate->new(%opt);

Creates a client (one reusable connection handle). Options:

=over 4

=item impersonate => $target

A browser profile name (see L</targets>), e.g. C<'chrome131'>. Applies that
browser's TLS/HTTP2 fingerprint and, unless C<default_headers> is false, its
default header set. An unknown target croaks.

=item default_headers => $bool

Whether to also install the target's default request headers. Default true.

=item timeout => $seconds

Whole-request timeout. There is no default: libcurl waits indefinitely, so a
blackholed address or a server that accepts and never answers will hang the
caller. Set one for anything talking to the open internet.

=item verify => $bool

TLS peer/host verification. Default true. Set false only for testing against
self-signed endpoints.

=item follow_redirects => $bool

Follow C<3xx> redirects. Default false. libcurl bounds the chain itself, so a
redirect loop ends with C<Number of redirects hit maximum amount> rather than
spinning.

=item decode => $bool

Decompress the response body. libcurl decodes whatever it was built with --
here gzip, deflate, br and zstd -- and C<< $res->{body} >> is the decoded
bytes. Off by default, so the body arrives exactly as the origin sent it.

This does not change the request on the wire. The C<Accept-Encoding> the
impersonate target installs is a custom header, and libcurl lets a custom
header replace the one it would generate itself, so the fingerprint is
untouched; only the response side differs.

C<< $res->{headers} >> still reports the origin's C<Content-Encoding> and
C<Content-Length>, which now describe the bytes before decoding. Anything
forwarding this response onward must drop both.

=item proxy => $url

Route requests through a proxy, e.g. C<'http://127.0.0.1:8080'> or
C<'socks5h://host:1080'>. Credentials go in the URL. Note that a proxy which
terminates TLS presents its own fingerprint, not the impersonated one; to keep
the fingerprint intact the proxy must tunnel with C<CONNECT>.

=back

=head2 get

    my $res = $c->get($url);

Convenience for a GET C<request>.

=head2 request

    my $res = $c->request(
        method  => 'GET',      # default GET
        url     => $url,       # required
        headers => \%headers,  # optional; values are strings
        body    => $bytes,     # optional request body
    );

A header name or value containing CR, LF or NUL croaks: libcurl would pass such
a line through verbatim and the origin would read it as extra headers. An undef
value removes a header the impersonation profile would otherwise send.

Performs the request and returns a hashref. On success:

    { status => $int, headers => \%response_headers, body => $bytes,
      url => $effective_url }

C<url> is where the request actually ended up, which differs from the one asked
for when C<follow_redirects> sent it elsewhere.

Response header names are lower-cased; a header that appears more than once
(e.g. C<set-cookie>) is kept as an arrayref of its values. On a transport-level
failure (DNS, TLS, timeout) it returns instead:

    { error => $string, code => $curl_errno }

=head2 targets

    my @names = Curl::Impersonate->targets;

A sorted list of impersonation profiles verified against the built library. The
underlying library may accept additional names; any string it recognises works
when passed to C<new>.

=head1 ASYNCHRONOUS INTERFACE

The methods below belong to C<Curl::Impersonate::Multi>, which has no
constructor of its own -- it is documented here because C<multi> is the only
way to get one.

=head2 multi

    my $m = Curl::Impersonate->multi;

Returns a C<Curl::Impersonate::Multi>, a C<curl_multi>-backed handle for running
several requests concurrently.

=head2 add

    $m->add($handle, \%request, sub { my ($res, $err) = @_; ... });

Queues C<$request> (same keys as L</request>) on C<$handle> (a
C<Curl::Impersonate> object). The callback fires exactly once on completion with
either C<($res, undef)> or C<(undef, $error_string)>. C<$handle> is kept alive
until then; use one handle per in-flight request.

If the callback closes over C<$m> itself, that forms a reference cycle (C<$m> ->
queued request -> callback -> C<$m>) which is broken only when the request
completes or is L</remove>d. Dropping C<$m> while such a request is still in
flight leaks the cycle -- and the underlying curl handles -- until process exit.
Drive every request to completion, C<remove> it, or C<Scalar::Util::weaken> the
captured C<$m>.

=head2 perform_blocking

    $m->perform_blocking;

Runs an internal poll loop until every queued request has completed and its
callback has fired. Convenient for scripts and tests.

It cannot drive paused transfers: if an L</add_streaming> C<on_body> returns a
true value (pause), C<perform_blocking> has no way to resume it and will spin.
Use the L</Event-loop integration> surface for streaming/backpressure.

=head2 add_streaming

    $m->add_streaming($handle, \%request, {
        on_headers => sub { my ($status, $headers) = @_; ... },
        on_body    => sub { my ($chunk) = @_; ...; return $pause },
        on_done    => sub { my ($err) = @_; ... },
    });

Like C<add>, but delivers the response incrementally instead of buffering it.
C<on_headers> fires once when the upstream status and headers are known;
C<on_body> fires per body chunk. Returning a true value from C<on_body> pauses
the upstream transfer (C<CURLPAUSE_RECV>) -- use this to apply backpressure when
your downstream consumer is full; return the value C<2> to abort the transfer
(its C<on_done> then fires with an error). C<on_headers> also fires for a
bodyless response. C<on_done> fires once at the end with an error string or
C<undef>. Do not call L</resume>/L</remove> from inside these callbacks. Resume a
paused transfer with L</resume>.

An exception in C<on_headers> or C<on_body> warns and aborts the transfer;
C<on_done> receives an error.

B<Pausing and the chunk contract:> libcurl treats a pause as "this chunk was not
consumed" and re-delivers it to C<on_body> when you L</resume>. So decide whether
to pause B<before> consuming C<$chunk>: if you return a pause value you must NOT
have already consumed C<$chunk> -- take it on the re-delivery instead. Consuming a
chunk and then returning a pause value on the B<same> call delivers it twice. The
correct idiom is C<< if ($full) { ...arrange resume...; return 1 } consume($chunk); return 0 >>
(this is exactly what L<Proxy::Impersonate> does for its HIWAT backpressure).

=head2 resume

    $m->resume($handle);

Unpause a transfer paused by an C<on_body> that returned true, and nudge the
loop so delivery continues.

=head2 remove

    $m->remove($handle);

Cancel an in-flight request and free its state without firing C<on_done> -- for
tearing down a request whose consumer has gone away.

=head2 Event-loop integration

For an external event loop (e.g. L<EV>), drive the handle through the
C<curl_multi> socket-action surface instead of C<perform_blocking>:

=over 4

=item set_socket_callback(sub { my ($fd, $what) = @_; ... })

Registered with curl. C<$what> is curl's C<CURL_POLL_*>: C<1>=want-read,
C<2>=want-write, C<3>=both, C<4>=stop watching C<$fd>. Arm/disarm an I/O watcher
on C<$fd> accordingly.

=item set_timer_callback(sub { my ($timeout_ms) = @_; ... })

Registered with curl. Arm a one-shot timer for C<$timeout_ms> (or disarm on
C<-1>).

=item socket_action($fd, $ev)

Call when a watched socket is ready: C<$ev> bit C<1>=readable, bit C<2>=writable.
Call with C<$fd = -1> (and C<$ev = 0>) when the timer fires. Completed requests'
callbacks are dispatched from within this call.

=item timeout_ms

The current recommended timeout in milliseconds (C<-1> for none).

=back

=head1 SEE ALSO

L<Alien::curlimpersonate>, L<https://github.com/lexiforest/curl-impersonate>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
