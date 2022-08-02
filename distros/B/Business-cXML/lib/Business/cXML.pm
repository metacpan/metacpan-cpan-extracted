=encoding utf-8

=head1 NAME

Business::cXML - Perl implementation of cXML messaging

=head1 SYNOPSIS

B<Respond to an incoming request:>

	use Business::cXML;

	$cxml = new Business::cXML (
		local    => 'https://example.com/our/cxml',
		handlers => {
			PunchOutSetup => {
				__handler        => sub { ... },
				operationAllowed => 'create',
			},
		},
	);
	# Calls $res->reply_to($req), so to/from/sender are probably OK.
	$output_xml_string = $cxml->process($input_xml_string);
	# Send output to requestor...

B<Send a request to a server:>

	use Business::cXML;

	$cxml = new Business::cXML (
		remote => 'https://example.com/rest/cxml',
		secret => 'somesecrettoken',
	);
	$req = $cxml->new_request('PunchOutSetup');
	$req->from(id => '123456', domain => 'DUNS');  # Also sets Sender by default
	$req->to(id => '654321', domain => 'NetworkId');
	# Populate request, see Business::cXML::Transmission documentation...
	$res = $cxml->send($req);
	# Do something with $res, the Business::cXML::Transmission response received...

B<Create a one-way message:>

	use Business::cXML;

	$cxml = new Business::cXML;
	$msg = $cxml->new_message('PunchOutOrder');
	$msg->from(id => '123456', domain => 'DUNS');  # Also sets Sender by default
	$msg->to(id => '654321', domain => 'NetworkId');
	# Populate message, see Business::cXML::Transmission documentation...
	print $cxml->stringify($msg, url => '...');  # Transmission in cXML-Base64 in an HTML FORM

=head1 DESCRIPTION

Dispatch incoming HTTP/HTTPS requests and respond to them.  Send outgoing
requests and parse responses.  Prepare and parse one-way messages.

As a convention, cXML refers to overall messages as "transmissions" to
distinguish from C<Message> type payloads.  This library includes native Perl
modules for the following transmission types:

=over

=item * L<Business::cXML::Request::PunchOutSetup> / L<Business::cXML::Response::PunchOutSetup>

=item * L<Business::cXML::Message::PunchOutOrder>

=item * Planned: Request::Order / Response::Order

=back

Specifically B<NOT> implemented are:

=over

=item * Attachments

=item * Cryptographic signatures

=item * Requesting the remote side's capabilities profile and restricting ourselves to it

=back

=head2 Motivation & Future Development

While the above may implement a relatively small portion of the whole cXML
specification, which is designed to describe every business-to-business
transaction imaginable world-wide, it does fully satisfy our need (see
L</ACKNOWLEDGEMENTS>) to act as a "punch-out" supplier to our
Ariba/PeopleSoft/SAP/etc corporate clients.

The design is completely modular (see L<Business::cXML::Object>) and uses
L<XML::LibXML> under the hood, to help simplify future efforts to cover more
of the standard.

=head1 METHODS

=over

=cut

use 5.014;
use strict;

package Business::cXML;
use base 'Exporter';

use Scalar::Util 'blessed';
use Business::cXML::Transmission;

BEGIN {
	our $VERSION = 'v0.6.9';
	our $CXML_VERSION = '1.2.036';
	our $USERAGENT = "Business::cXML.pm $VERSION";
}

our @EXPORT = qw(CXML_LOG_NOTHING CXML_LOG_ERR CXML_LOG_ERROR CXML_LOG_WARN CXML_LOG_WARNING CXML_LOG_INFO CXML_LOG_DEBUG, CXML_LOG_TRACE);

use constant {
	CXML_LOG_NOTHING => 0,
	CXML_LOG_ERR     => 1,
	CXML_LOG_ERROR   => 1,
	CXML_LOG_WARN    => 2,
	CXML_LOG_WARNING => 2,
	CXML_LOG_INFO    => 3,
	CXML_LOG_DEBUG   => 4,
	CXML_LOG_TRACE   => 5,
};

=item C<B<new>( I<%options> )>

Returns a fresh cXML handler.

Options useful to send requests and receive responses:

=over

=item C<B<remote>>

HTTP/HTTPS URL where to POST requests

=back

Options useful to process requests and emit responses:

=over

=item C<B<local>>

HTTP/HTTPS URL to publish where clients can reach this handler

=item C<B<secret>>

Secret keyword expected by remote server

=item C<B<sender_callback>>

Subroutine, passed to L</sender_callback()>.

=item B<log_level>

One of: C<CXML_LOG_NOTHING> (default), C<CXML_LOG_ERR>, C<CXML_LOG_WARN>,
C<CXML_LOG_INFO>, C<CXML_LOG_DEBUG>, C<CXML_LOG_TRACE>.  Alternates
C<CXML_LOG_ERROR> and C<CXML_LOG_WARNING> are also available.

=item B<log_callback>

Subroutine, passed to L</log_callback()>.

=item B<handlers>

Hash of handlers, dereferenced and passed to L</on()>.

=back

=cut

sub new {
	my ($class, %options) = @_;

	my $self = {
		local           => ($options{local} || ''),
		remote          => ($options{remote} || undef),
		secret          => ($options{secret} || undef),
		sender_callback => undef,
		log_level       => ($options{log_level} || CXML_LOG_NOTHING),
		log_callback    => ($options{log_callback} || \&_log_default),
		routes => {
			Profile => {
				__handler => \&_handle_profile,
			},
		},
	};
	bless $self, $class;
	$self->sender_callback($options{sender_callback}) if exists $options{sender_callback};
	$self->on(%{ $options{handlers} }) if exists $options{handlers};
	return $self;
}

sub _handle_profile {
	my ($self, $req, $res) = @_;

	$res->status(200);

	my $data = $res->xml_payload;

	$data->attr(effectiveDate => $res->timestamp);
	# UNIMPLEMENTED: lastRefresh?

	# UNIMPLEMENTED: service-level (outside Transaction blocks) options: service, attachments, changes, requestNames
	# Possibly also: Locale (found in an example, but not in any documentation)
	# There was no documentation about these in the cXML 1.2.036 PDF manual nor in the DTD comments.
	foreach my $route (keys (%{ $self->{routes} })) {
		my $tx = $data->add('Transaction', undef, requestName => ($route . 'Request'));
		$tx->add(URL => $self->{local});
		foreach my $opt (grep { $_ ne '__handler' } keys (%{ $self->{routes}{$route} })) {
			$tx->add('Option', $self->{routes}{$route}{$opt}, name => $opt);
		};
	};
}


=item C<B<sender_callback>( I<$sub> )>

By default, a request's From/Sender credentials are only used to guess
response credentials.  If you specify a callback here, it will be invoked
immediately after XML parsing, before passing to transaction handlers, giving
you an opportunity to authenticate the caller.

Your subroutine will be passed 3 arguments:

=over

=item 1. The current L<Business::cXML> object

=item 2. The Sender L<Business::cXML::Credential> object

=item 3. The From L<Business::cXML::Credential> object

=back

If you return a false value, the request will be deemed unauthorized and no
handler will be invoked.

If you return anything else, it will be stored and available in the request
sender's C<_note> property.  (See L<Business::cXML::Credential> for details.)

Note that cXML From/Sender headers contain information about an entire company
you're doing business with.  The identity of the specific person triggering
the request, if applicable, will be somewhere in contact or extrinsic data in
the payload itself.

=cut

sub sender_callback {
	my ($self, $callback) = @_;
	$self->{sender_callback} = $callback if ref($callback) eq 'CODE';
}

=item C<B<log_callback>( I<$sub> )>

By default, basic details about log-worthy events are dumped to C<STDERR>
(filtered according to the current log level).  By specifying your own
handler, you can do anything else you'd like when informative events occur.

Your subroutine will be passed 5 arguments:

=over

=item 1. The current L<Business::cXML> object

=item 2. The level

=over

=item CXML_LOG_ERR = 1 = fatal error (on our side)

=item CXML_LOG_WARN = 2 = warning (errors on the other end, network issues, etc.)

=item CXML_LOG_INFO = 3 = normal operations like receiving or sending transmissions

=item CXML_LOG_DEBUG = 4 = additional debugging information about processing requests

=item CXML_LOG_TRACE = 5 = full trace logging in some areas

=back

=item 3. A possible long-form message describing the event

=item 4. A possible cXML transmission string (untouched if input)

=item 5. A possible L<Business::cXML::Transmission> object

=back

Successful parsing of a new transmission triggers a level 3 log, whereas
failure is a level 2.  Failure to produce valid XML from our internal data
(which should never occur) is a level 1.

NOTE: Logging is limited to this module.  Thus, be sure to use L<process()>,
L<send()> and L<stringify()> to trap interesting events in the handling of
C<Request>, C<Response> and C<Message> transmissions.

=cut

sub _log_default {
	my ($cxml, $level, $desc, $xml, $tx) = @_;
	return unless $level <= $cxml->{log_level};
	$level = ('error', 'warning', 'info', 'debug', 'trace')[$level-1];
	# use Data::Dumper;
	# print STDERR "cXML[$level]: ", $desc, " -- ", $xml, " -- ", Dumper($cxml), "\n";
	$xml =~ s/>\s+</> </g;
	print STDERR "cXML[$level]: ", $desc, " -- ", $xml, "\n";
}

sub log_callback {
	my ($self, $callback) = @_;
	$self->{log_callback} = $callback;
}

sub _error   { my $l = shift; $l->{log_callback}->($l, CXML_LOG_ERR,   @_); return undef; }
sub _warning { my $l = shift; $l->{log_callback}->($l, CXML_LOG_WARN,  @_); return undef; }
sub _notice  { my $l = shift; $l->{log_callback}->($l, CXML_LOG_INFO,  @_); return undef; }
sub _debug   { my $l = shift; $l->{log_callback}->($l, CXML_LOG_DEBUG, @_); return undef; }
sub _trace   { my $l = shift; $l->{log_callback}->($l, CXML_LOG_TRACE, @_); return undef; }

=item C<B<on>( I<%handlers> )>

Each key in I<C<%handlers>> is the bare name of a supported transaction type.
For example, if you want to support C<PunchOutSetupRequest>, the key is
C<PunchOutSetup>.  Each key should point to a hashref specifying any options
to declare in our C<Profile>.

Special key C<__handler> is mandatory and should point to a sub which will
be called if its type of request is received, valid and optionally
authenticated.  Your handler will be passed 3 arguments:

=over

=item 1. The current L<Business::cXML> object

=item 2. The L<Business::cXML::Transmission> request

=item 3. A ready-to-fill L<Business::cXML::Transmission> response

=back

Be sure to change the response's status, which is a 500 error by default.

The response's to/from/sender is initialized in reciprocity to the request's,
so your handler might not need to change much in those.

Keys represent the case-sensitive name of the cXML request without the
redundant suffix.  For example, a C<PunchOutSetupRequest> is our type
C<PunchOutSetup>.  Possible keys include: C<Order>, C<PunchOutSetup>,
C<StatusUpdate>, C<GetPending>, C<Confirmation>, C<ShipNotice>,
C<ProviderSetup>, C<PaymentRemittance>.

Pings and C<Profile> requests are built-in, although you can override the
handling of the latter with your own handler if you'd like.

=cut

sub on {
	my ($self, %routes) = @_;

	foreach (keys %routes) {
		$self->{routes}{$_} = $routes{$_};
	};
}

=item C<B<process>( [I<$input>] )>

Decodes the I<C<$input>> XML string which is expected to be a complete cXML
transmission.  May invoke one of your handlers declared with L<on()> if
appropriate.

Returns a string containing a valid cXML document at all times.  This document
includes any relevant status information determined during processing.

Note that an omitted or empty I<C<$input>> is actually valid and results in a
"pong" response.

=cut

sub process {
	my ($self, $input) = @_;
	my $err;
	my $str;
	my $res = new Business::cXML::Transmission;
	$res->is_response(1);

	unless ($input) {
		$self->_notice("process(10) ping-pong");
		$res->status(200, "Pong!");
		($err, $str) = $res->toString;
		$self->_error("process(12) $err", $str) if $err;
		$self->_trace("process(15) ping-pong returning", $str);
		return $str;
	};

	my $req = new Business::cXML::Transmission $input;

	unless (defined blessed($req)) {
		# We have an error status code
		my $desc = "XML validation failure:\n" . $req->[1];
		$self->_warning("process(21) $desc", $input);
		$res->status($req->[0], $desc);
		($err, $str) = $res->toString;
		$self->_error("process(22) $err", $str) if $err;
		$self->_trace("process(25) error returning", $str);
		return $str;
	};

	$res->status(500, "Handler did not set a response status.");
	$res->reply_to($req);
	$res->payload;  # Trigger creation of payload now that it has a class/type.

	if (defined $self->{sender_callback}) {
		$self->_trace("process(30) sender_callback...");
		my $note;
		eval {
			$note = $self->{sender_callback}->($self, $req->sender, $req->from);
		};
		if ($@) {
			$self->_error("process(31) sender_callback crashed!!!", $@);
			$res->status(500, "Sender validation encountered an irrecoverable error.");
			($err, $str) = $res->toString;
			$self->_error("process(32) $err", $str) if $err;
			return $str;
		};
		if ($note) {
			$self->_debug("process(33) sender_callback successful");
			$req->sender->_note($note);
		} else {
			$self->_warning("process(34) sender validation failed", $input, $req);
			$res->status(401, "Invalid sender.");
			($err, $str) = $res->toString;
			$self->_error("process(35) $err", $str) if $err;
			return $str;
		};
	};

	unless (exists $self->{routes}{$req->type}) {
		my $desc = "Type '" . $req->type . "' is not implemented.";
		$self->_warning("process(41) $desc", $input, $req);
		$res->status(450, $desc);
		($err, $str) = $res->toString;
		$self->_error("process(45) $err", $str) if $err;
		return $str;
	};
	$self->_notice("process() received request", $input, $req);
	eval {
		$self->{routes}{$req->type}{__handler}->($self, $req, $res);
	};
	if ($@) {
		$self->_error("process(50) handler for type '" . $req->type . "' crashed!!!", $@);
		$res->status(500, "Processing for type '" . $req->type . "' encountered an irrecoverable error.");
	};

	($err, $str) = $res->toString;
	$self->_error("process(51): $err", $str, $res) if $err;

	if ($res->status >= 500) {
		$self->_error("process(55) responding with 5xx", $str, $res);
	} elsif ($res->status >= 400) {
		$self->_warning("process(54) responding with 4xx", $str, $res);
	} else {
		$self->_notice("process(52) responding with 2xx", $str, $res);
	};

	$self->_debug("process(60) returning", $str);
	return $str;
}

=item C<B<new_request>( [I<$type>] )>

Returns a fresh L<Business::cXML::Transmission> ready to be used as a request.
Optional I<C<$type>> is a convenience shortcut to
L<Business::cXML::Transmission::type()|cXML::Transmission/type>.  The
request's sender secret will be pre-filled.

=cut

sub new_request {
	my ($self, $type) = @_;
	my $req = new Business::cXML::Transmission;
	$req->is_request(1);
	$req->type($type) if defined $type;
	$req->sender->secret($self->{secret}) if defined $self->{secret};
	return $req;
}

=item C<B<send>( I<$request> )>

Freeze I<C<$request>>, a L<Business::cXML::Transmission>, and attempt sending
it to the configured remote server.  Returns the received response
L<Business::cXML::Transmission> on success, C<undef> on failure.  Note that as
per L<Business::cXML::Transmission::new()|Business::cXML::Transmission/new>,
it is also possible that an error arrayref be returned instead of a
transmission if parsing failed.

In case of failure, you may want to wait a certain amount of time and try
again.  To give you more options to that effect, I<C<$request>> can be either
a L<Business::cXML::Transmission> or a string.

=cut

use LWP::UserAgent;
sub send {
	my ($self, $req) = @_;
	my $err;
	my $obj;

	if (ref($req)) {
		$obj = $req;
		($err, $req) = $req->freeze();
		return $self->_error("send(11): $err", $req, $obj) if defined $err;
	};
	$self->_notice("send() making HTTP request", $req, $obj);

	my $ua = new LWP::UserAgent;
	$ua->agent($Business::cXML::USERAGENT);
	$ua->timeout(30);
	my $res = $ua->post(
		$self->{remote},
		'Content-Type' => 'text/xml; charset="UTF-8"',
		'Content' => $req,
	);
	if ($res->is_success) {
		$res = $res->decoded_content;
		my $msg = new Business::cXML::Transmission $res;
		unless (defined blessed($msg)) {
			# We have an error status code
			return $self->_warning('send(21) ' . ($msg->[0] == 406 ? 'response XML validation' : 'response cXML traversal') . ' failure', $res);
		};
		$self->_notice("send() received HTTP response", $res, $msg);
		return $msg;
	} else {
		return $self->_warning("send(22) had network failure", $req, $obj);
	};
}

=item C<B<new_message>( [I<$type>] )>

Returns a fresh L<Business::cXML::Transmission> ready to be used as a
stand-alone message.  Optional I<C<$type>> is passed on to
L<Business::cXML::Transmission::type()|Business::cXML::Transmission/type>.

=cut

sub new_message {
	my ($self, $type) = @_;
	my $msg = new Business::cXML::Transmission;
	$msg->is_message(1);
	$msg->type($type) if defined $type;
	return $msg;
}

=item C<B<stringify>( I<$message>, I<%args> )>

Convenience wrapper around
L<Business::cXML::Transmission::toForm()|Business::cXML::Transmission/toForm>
which allows you to trap logging events.

=cut

sub stringify {
	my ($self, $msg, %args) = @_;
	my ($err, $str) = $msg->toForm(%args);
	$self->_error("stringify(): $err", $str, $msg) if defined $err;
	return $str;
}

=back

=head1 VERSION

0.6.9 based on cXML DTD 1.2.036

=head1 AUTHOR

Stéphane Lavergne L<https://github.com/vphantom>

=head1 ACKNOWLEDGEMENTS

Graph X Design Inc. L<https://www.gxd.ca/> sponsored this project.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2017-2018 Stéphane Lavergne L<https://github.com/vphantom>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=cut

1;
