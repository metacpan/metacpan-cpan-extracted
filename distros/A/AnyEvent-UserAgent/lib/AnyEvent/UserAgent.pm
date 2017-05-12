package AnyEvent::UserAgent;

# This module based on original AnyEvent::HTTP::Simple module by punytan
# (punytan@gmail.com): http://github.com/punytan/AnyEvent-HTTP-Simple

use Moo;

use AnyEvent::HTTP ();
use HTTP::Cookies ();
use HTTP::Request ();
use HTTP::Request::Common ();
use HTTP::Response ();

use namespace::clean;

our $VERSION = '0.07';


has agent              => (is => 'rw', default => sub { $AnyEvent::HTTP::USERAGENT . ' AnyEvent-UserAgent/' . $VERSION });

has cookie_jar         => (is => 'rw', default => sub { HTTP::Cookies->new });

has max_redirects      => (is => 'rw', default => sub { 5 });

has inactivity_timeout => (is => 'rw', default => sub { 20 });

has request_timeout    => (is => 'rw', default => sub { 0 });

sub request {
	my $cb = pop();
	my ($self, $req, %opts) = @_;

	$self->_request($req, \%opts, sub {
		$self->_response($req, @_, $cb);
	});
}

sub get    { _make_request(GET    => @_) }
sub head   { _make_request(HEAD   => @_) }
sub put    { _make_request(PUT    => @_) }
sub delete { _make_request(DELETE => @_) }
sub post   { _make_request(POST   => @_) }

sub _make_request {
	my $cb   = pop();
	my $meth = shift();
	my $self = shift();

	no strict 'refs';
	$self->request(&{'HTTP::Request::Common::' . $meth}(@_), $cb);
}

sub _request {
	my ($self, $req, $opts, $cb) = @_;

	my $uri  = $req->uri;
	my $hdrs = $req->headers;

	unless ($hdrs->user_agent) {
		$hdrs->user_agent($self->agent);
	}

	if ($uri->can('userinfo') && $uri->userinfo && !$hdrs->authorization) {
		$hdrs->authorization_basic(split(':', $uri->userinfo, 2));
	}
	if ($uri->scheme) {
		$self->cookie_jar->add_cookie_header($req);
	}

	for (qw(max_redirects inactivity_timeout request_timeout)) {
		$opts->{$_} = $self->$_() unless exists($opts->{$_});
	}

	my ($grd, $tmr);

	if ($opts->{request_timeout}) {
		$tmr = AE::timer $opts->{request_timeout}, 0, sub {
			undef($grd);
			$cb->($opts, undef, {Status => 597, Reason => 'Request timeout'});
		};
	}
	$grd = AnyEvent::HTTP::http_request(
		$req->method,
		$req->uri,
		headers => {map { $_ => $hdrs->header($_) } $hdrs->header_field_names},
		body    => $req->content,
		recurse => 0,
		timeout => $opts->{inactivity_timeout},
		(map { $_ => $opts->{$_} } grep { exists($opts->{$_}) }
			qw(proxy tls_ctx session timeout on_prepare tcp_connect on_header
			   on_body want_body_handle persistent keepalive handle_params)),
		sub {
			undef($grd);
			undef($tmr);
			$cb->($opts, @_);
		}
	);
}

sub _response {
	my $cb = pop();
	my ($self, $req, $opts, $body, $hdrs, $prev, $count) = @_;

	my $res = HTTP::Response->new(delete($hdrs->{Status}), delete($hdrs->{Reason}));

	$res->request($req);
	$res->previous($prev) if $prev;

	delete($hdrs->{URL});
	if (defined($hdrs->{HTTPVersion})) {
		$res->protocol('HTTP/' . delete($hdrs->{HTTPVersion}));
	}
	if (my $hdr = $hdrs->{'set-cookie'}) {
		# Split comma-concatenated "Set-Cookie" values.
		# Based on RFC 6265, section 4.1.1.
		local @_ = split(/,([\w.!"'%\$&*+-^`]+=)/, ',' . $hdr);
		shift();
		my @val;
		push(@val, join('', shift(), shift())) while @_;
		$hdrs->{'set-cookie'} = \@val;
	}
	if (keys(%$hdrs)) {
		$res->header(%$hdrs);
	}
	if ($res->code >= 590 && $res->code <= 599 && $res->message) {
		if ($res->message eq 'Connection timed out') {
			$res->message('Inactivity timeout');
		}
		unless ($res->header('client-warning')) {
			$res->header('client-warning' => $res->message);
		}
	}
	if (defined($body)) {
		$res->content_ref(\$body);
	}
	$self->cookie_jar->extract_cookies($res);

	my $code = $res->code;

	if ($code == 301 || $code == 302 || $code == 303 || $code == 307 || $code == 308) {
		$self->_redirect($req, $opts, $code, $res, $count, $cb);
	}
	else {
		$cb->($res);
	}
}

sub _redirect {
	my ($self, $req, $opts, $code, $prev, $count, $cb) = @_;

	unless (defined($count) ? $count : ($count = $opts->{max_redirects})) {
		$prev->header('client-warning' => 'Redirect loop detected (max_redirects = ' . $opts->{max_redirects} . ')');
		$cb->($prev);
		return;
	}

	my $meth  = $req->method;
	my $proto = $req->uri->scheme;
	my $uri   = $prev->header('location');

	$req = $req->clone();
	$req->remove_header('cookie');
	if (($code == 302 || $code == 303) && !($meth eq 'GET' || $meth eq 'HEAD')) {
		$req->method('GET');
		$req->content('');
		$req->remove_content_headers();
	}
	{
		# Support for relative URL for redirect.
		# Not correspond to RFC.
		local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
		my $base = $prev->base;
		$uri = $HTTP::URI_CLASS->new(defined($uri) ? $uri : '', $base)->abs($base);
	}
	$req->uri($uri);
	if ($proto eq 'https' && $uri->scheme eq 'http') {
		# Suppress 'Referer' header for HTTPS to HTTP redirect.
		# RFC 2616, section 15.1.3.
		$req->remove_header('referer');
	}

	$self->_request($req, $opts, sub {
		$self->_response($req, @_, $prev, $count - 1, sub { return $cb->(@_); });
	});
}


1;


__END__

=head1 NAME

AnyEvent::UserAgent - AnyEvent::HTTP OO-wrapper

=head1 SYNOPSIS

    use AnyEvent::UserAgent;
    use Data::Dumper;

    my $ua = AnyEvent::UserAgent->new;
    my $cv = AE::cv;

    $ua->get('http://example.com/', sub {
        my ($res) = @_;
        print(Dumper($res, $ua->cookie_jar));
        $cv->send();
    });
    $cv->recv();

=head1 DESCRIPTION

AnyEvent::UserAgent is a OO-wrapper around L<AnyEvent::HTTP> with cookies
support by L<HTTP::Cookies>. Also request callback receives response as
L<HTTP::Response> object.

=head1 ATTRIBUTES

=head2 agent

The product token that is used to identify the user agent on the network. The
agent value is sent as the C<User-Agent> header in the requests.

=head2 cookie_jar

The cookie jar object to use. The only requirement is that the cookie jar object
must implement the C<extract_cookies($req)> and C<add_cookie_header($res)>
methods. These methods will then be invoked by the user agent as requests are
sent and responses are received. Normally this will be a L<HTTP::Cookies> object
or some subclass. Default cookie jar is the L<HTTP::Cookies> object.

=head2 inactivity_timeout

Maximum time in seconds in which connection can be inactive before getting
closed. Default timeout value is C<20>. Setting the value to C<0> will allow
connections to be inactive indefinitely.

=head2 max_redirects

Maximum number of redirects the user agent will follow before it gives up.
The default value is C<5>.

=head2 request_timeout

Maximum time in seconds to establish a connection, send the request and receive
a response. The request will be canceled when that time expires. Default timeout
value is C<0>. Setting the value to C<0> will allow the user agent to wait
indefinitely. The timeout will reset for every followed redirect.

=head1 METHODS

=head2 new

    my $ua = AnyEvent::UserAgent->new;
    my $ua = AnyEvent::UserAgent->new(request_timeout => 60);

Constructor for the user agent. You can pass it either a hash or a hash
reference with attribute values.

=head2 request

    $ua->request(GET 'http://example.com/', sub { print($_[0]->code) });

This method will dispatch the given request object. Normally this will be an
instance of the L<HTTP::Request> class, but any object with a similar interface
will do. The last argument must be a callback that will be called with a
response object as first argument. Response will be an instance of the
L<HTTP::Response> class.

This method is a wrapper for the L<C<AnyEvent::HTTP::http_request()>|AnyEvent::HTTP>
method. So you also can pass parameters for it, e.g.:

    $ua->request(GET 'http://example.com/', want_body_handle => 0, sub { print($_[0]->code) });

Full parameter list see at the L<AnyEvent::HTTP> documentation.

=head2 get

    $ua->get('http://example.com/', sub { print($_[0]->code) });

This method is a wrapper for the L<C<request()>|/request> method and the
L<C<HTTP::Request::Common::GET()>|HTTP::Request::Common/GET $url> function.
The last argument must be a callback.

=head2 head

This method is a wrapper for the L<C<request()>|/request> method and the
L<C<HTTP::Request::Common::HEAD()>|HTTP::Request::Common/HEAD $url> function.
See L<C<get()>|/get>.

=head2 put

This method is a wrapper for the L<C<request()>|/request> method and the
L<C<HTTP::Request::Common::PUT()>|HTTP::Request::Common/PUT $url> function.
See L<C<get()>|/get>.

=head2 delete

This method is a wrapper for the L<C<request()>|/request> method and the
L<C<HTTP::Request::Common::DELETE()>|HTTP::Request::Common/DELETE $url>
function. See L<C<get()>|/get>.

=head2 post

    $ua->post('http://example.com/', [key => 'value'], sub { print($_[0]->code) });

This method is a wrapper for the L<C<request()>|/request> method and the
L<C<HTTP::Request::Common::POST()>|HTTP::Request::Common/POST $url> function.
The last argument must be a callback.

=head1 SEE ALSO

L<AnyEvent::HTTP>, L<HTTP::Cookies>, L<HTTP::Request::Common>, L<HTTP::Request>,
L<HTTP::Response>.

=head1 SUPPORT

=over 4

=item * Repository

L<http://github.com/AdCampRu/anyevent-useragent>

=item * Bug tracker

L<http://github.com/AdCampRu/anyevent-useragent/issues>

=back

=head1 AUTHOR

Denis Ibaev C<dionys@cpan.org> for AdCamp.ru.

=head1 CONTRIBUTORS

Andrey Khozov C<avkhozov@cpan.org>.

This module based on original L<AnyEvent::HTTP::Simple|http://github.com/punytan/AnyEvent-HTTP-Simple>
module by punytan C<punytan@gmail.com>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut
