package App::WebPerimeterScan::TLS;

use strict;
use warnings;
use autodie qw(:all);

# A failed TLS close is not worth an exception: the inspection is done.
no autodie qw(close);

use IO::Socket::SSL;
use Net::SSLeay ();
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Sub::Private { mode => 'enforce' };
use Time::HiRes qw(time);
use Time::Local qw(timegm);

use App::WebPerimeterScan::I18N ();
use parent -norequire, 'App::WebPerimeterScan::I18N';

our $VERSION = '0.001.0';

# Defaults for inspect(); a plain hash so Object::Configure or a caller can
# change them.
our %config = (
	port    => 443,
	timeout => 10,
);

# Which protocol versions the server will still negotiate.  Anything below
# TLS 1.2 is deprecated by RFC 8996.
Readonly::Array my @PROBE_VERSIONS => qw(TLSv1 TLSv1_1 TLSv1_2 TLSv1_3);

# OpenSSL 3 refuses to offer TLS 1.0 or 1.1 at its default security level,
# so a probe for them fails locally before a byte reaches the server and an
# old protocol is never detected.  Level 0 lets the client offer them; it
# only applies to these probes, never to the request that reads the site.
Readonly::Hash my %PROBE_CIPHERS => (
	TLSv1   => 'DEFAULT:@SECLEVEL=0',
	TLSv1_1 => 'DEFAULT:@SECLEVEL=0',
);

# The certificate name fields shown in reports, most specific first.
Readonly::Array my @NAME_FIELDS => qw(commonName organizationName organizationalUnitName countryName);

Readonly::Scalar my $SECONDS_PER_DAY => 86_400;

Readonly::Hash my %MONTH => (
	Jan => 0, Feb => 1, Mar => 2,  Apr => 3,  May => 4,  Jun => 5,
	Jul => 6, Aug => 7, Sep => 8,  Oct => 9,  Nov => 10, Dec => 11,
);

# "Jun  1 12:00:00 2027 GMT" and "2026-12-25T22:56:35Z".  ASN.1 times are
# always UTC.
Readonly::Scalar my $ASN1_TEXT => qr/\A\s*([A-Z][a-z]{2})\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+(\d{4})/;
Readonly::Scalar my $ASN1_ISO  => qr/\A\s*(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})/;

=encoding utf8

=head1 NAME

App::WebPerimeterScan::TLS - certificate and protocol inspection

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

Check when the certificate expires:

	use App::WebPerimeterScan::TLS;

	my $tls = App::WebPerimeterScan::TLS->inspect(host => 'example.com');
	if($tls->{ok} && defined $tls->{days_left}) {
		printf "expires in %d days\n", $tls->{days_left};
	}

Check that a browser would trust the certificate:

	if(!$tls->{ok}) {
		print "no TLS handshake: $tls->{error}\n";
	} elsif(defined $tls->{verify_error}) {
		print "not trusted: $tls->{verify_error}\n";
	} else {
		print "trusted; $tls->{protocol} with $tls->{cipher}\n";
	}

Find old protocol versions that the server still accepts, on a port that
is not 443:

	my $mail = App::WebPerimeterScan::TLS->inspect(host => 'mail.example.com', port => 993);
	my @old = grep { $_ eq 'TLSv1' || $_ eq 'TLSv1_1' } @{ $mail->{protocols} };
	print "old protocols: @old\n" if @old;

=head1 DESCRIPTION

This module connects to a TLS service (for example HTTPS on port 443) and
describes it.  It answers four questions:

=over 4

=item 1. Which certificate does the server send?  The subject, issuer,
fingerprint and expiry date are read, without checking if the certificate
is trusted.

=item 2. Would a browser trust it?  A second handshake checks the
certificate chain and the host name.  Any problem is put in
C<verify_error>.

=item 3. Which protocol and cipher does the server choose by default?

=item 4. Which protocol versions does the server accept?  One handshake is
tried for each of TLS 1.0, 1.1, 1.2 and 1.3.  The names in C<protocols>
are C<TLSv1>, C<TLSv1_1>, C<TLSv1_2> and C<TLSv1_3>.

=back

That is up to six handshakes for each call.  The host name is sent in
every handshake (as SNI), so a server that hosts many sites sends the
certificate for this one.

=head1 REQUIREMENTS

C<IO::Socket::SSL> 2.000 and C<Net::SSLeay> 1.92, the first release with
OpenSSL 3 support.  The expiry date is read through Net::SSLeay when
IO::Socket::SSL does not offer it, so the build must provide
C<X509_get_notAfter> and C<P_ASN1_TIME_put2string>.

=head1 SUBROUTINES/METHODS

=head2 inspect

Purpose: describe the TLS service on a host and port.

Args: named C<host> (required), C<port> (default 443) and C<timeout>
(seconds per handshake, default 10).  A class method.

Returns: a hash reference.  Always: C<host>, C<port>, C<protocols> (array
reference of the versions a version-pinned handshake completed with; this is
filled in even when the default handshake fails).  When the default
handshake fails: C<error>.  Otherwise C<ok> (1), C<protocol>, C<cipher>, C<self_signed>,
C<subject>, C<issuer>, C<fingerprint>, C<verify_error> (C<undef> when the
chain verifies) and, when the expiry could be read, C<not_after>,
C<expires_at> (epoch) and C<days_left> (negative once expired).

Side Effects: up to six TLS handshakes with the host (five when the
default handshake fails, as verification is then skipped).

Usage: C<< my $tls = App::WebPerimeterScan::TLS->inspect(host => $host); >>

=head3 EXAMPLE

	my $tls = App::WebPerimeterScan::TLS->inspect(host => 'example.com', timeout => 5);
	if(!$tls->{ok}) {
		print "no TLS: $tls->{error}\n";
	} elsif($tls->{verify_error}) {
		print "untrusted: $tls->{verify_error}\n";
	} else {
		print "accepts: @{ $tls->{protocols} }\n";
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		host    => { type => 'string', min => 1 },
		port    => { type => 'integer', min => 1, max => 65535, optional => 1 },
		timeout => { type => 'number', min => 0, optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			host      => { type => 'string' },
			port      => { type => 'integer' },
			protocols => { type => 'arrayref' },
			ok        => { type => 'boolean', optional => 1 },
			error     => { type => 'string', optional => 1 },
		},
	}

=head3 MESSAGES

Returned in C<error> or C<verify_error>, not thrown:

	Message                            Meaning / resolution
	---------------------------------  ----------------------------------
	(OpenSSL or socket text)           The handshake failed; the text is
	                                   IO::Socket::SSL's reason.
	certificate verification failed    Verification failed and OpenSSL
	                                   gave no more specific reason.

=head3 PSEUDOCODE

	handshake without verification
	if it worked
		record protocol, cipher, subject, issuer, fingerprint, self-signed
		read the expiry, from IO::Socket::SSL or else Net::SSLeay
		handshake again with verification; record any error
	otherwise record the error
	handshake once per protocol version; record those that succeed

=cut

sub inspect
{
	my $class = shift;

	my $args = validate_strict(
		schema => {
			host    => { type => 'string', min => 1 },
			port    => { type => 'integer', min => 1, max => 65_535, optional => 1 },
			timeout => { type => 'number', min => 0, optional => 1 },
		},
		input => get_params(undef, \@_) // {},
	);

	my $host    = $args->{host};
	my $port    = $args->{port} || $config{port};
	my $timeout = $args->{timeout} || $config{timeout};

	my $result = { host => $host, port => $port, protocols => [] };

	my $sock = _connect($host, $port, $timeout);
	if($sock) {
		_describe($sock, $result);
		close $sock;

		# Verification is a separate handshake: the inspection socket
		# above deliberately does not verify, so a broken chain cannot
		# hide a site.
		$result->{verify_error} = $class->_verify($host, $port, $timeout);
	} else {
		$result->{error} = _ssl_error() // $class->i18n('tls.unknown_error');
	}

	# The version probes run even when the default handshake failed: a
	# server that only speaks TLS 1.0 fails it, and that is exactly the
	# server whose protocol list matters most.
	for my $version (@PROBE_VERSIONS) {
		my $probe = _connect($host, $port, $timeout, $version) or next;
		push @{ $result->{protocols} }, $version;
		close $probe;
	}

	return $result;
}

# _describe
# Purpose:     record what the first handshake learned.
# Entry:       $sock is a connected IO::Socket::SSL; $result a hashref.
# Exit:        $result, filled in.
# Side effects: modifies $result.
sub _describe :Private
{
	my ($sock, $result) = @_;

	$result->{ok}          = 1;
	$result->{protocol}    = $sock->get_sslversion // '';
	$result->{cipher}      = $sock->get_cipher // '';
	$result->{self_signed} = _self_signed($sock);

	# Each field is optional: some builds do not offer every one.
	for my $field (qw(subject issuer fingerprint)) {
		my $value = eval { $sock->peer_certificate($field) } or next;
		$result->{$field} = $field eq 'fingerprint' ? $value : _name($value);
	}

	if(defined(my $not_after = _not_after($sock))) {
		$result->{not_after} = $not_after;
		if(defined(my $epoch = _parse_asn1_time($not_after))) {
			$result->{expires_at} = $epoch;
			$result->{days_left}  = int(($epoch - time) / $SECONDS_PER_DAY);
		}
	}

	return $result;
}

# _connect
# Purpose:     one unverified handshake, optionally pinned to a version.
# Entry:       $version, if given, is one of @PROBE_VERSIONS.
# Exit:        the socket, or undef (SSL_ERROR / $! set).
# Side effects: a TLS handshake.
sub _connect :Private
{
	my ($host, $port, $timeout, $version) = @_;

	my %args = (
		PeerHost        => $host,
		PeerPort        => $port,
		Timeout         => $timeout,
		SSL_hostname    => $host,
		SSL_verify_mode => SSL_VERIFY_NONE,
	);
	$args{SSL_version}     = $version if $version;
	$args{SSL_cipher_list} = $PROBE_CIPHERS{$version} if $version && $PROBE_CIPHERS{$version};

	return IO::Socket::SSL->new(%args);
}

# _verify
# Purpose:     would a browser trust this chain for this name?
# Entry:       as _connect.
# Exit:        undef if it verifies, else the reason.
# Side effects: a TLS handshake.
sub _verify :Private
{
	my ($class, $host, $port, $timeout) = @_;

	my $sock = IO::Socket::SSL->new(
		PeerHost            => $host,
		PeerPort            => $port,
		Timeout             => $timeout,
		SSL_hostname        => $host,
		SSL_verify_mode     => SSL_VERIFY_PEER,
		SSL_verifycn_name   => $host,
		SSL_verifycn_scheme => 'http',
	);
	close $sock if $sock;

	return $sock ? undef : (_ssl_error() // $class->i18n('tls.verify_failed'));
}

# _ssl_error
# Purpose:     IO::Socket::SSL's last error, or $! when it has none.
# Entry:       straight after a failed IO::Socket::SSL->new.
# Exit:        a non-empty string, or undef if neither says anything.
# Side effects: none.
sub _ssl_error :Private
{
	my $error = $IO::Socket::SSL::SSL_ERROR;
	$error = "$!" unless defined $error && length $error;

	return length $error ? $error : undef;
}

# _self_signed
# Purpose:     are the certificate's subject and issuer the same name?
# Entry:       $sock is a connected IO::Socket::SSL.
# Exit:        1 or 0; 0 when either name cannot be read.
# Side effects: none.
sub _self_signed :Private
{
	my ($sock) = @_;

	my $subject = eval { $sock->peer_certificate('subject') };
	my $issuer  = eval { $sock->peer_certificate('issuer') };

	return ($subject && $issuer && _name($subject) eq _name($issuer)) ? 1 : 0;
}

# _name
# Purpose:     a certificate name as one string.
# Entry:       $name is a string, a hash of fields, or undef.
# Exit:        the name; '' for undef; 'unknown' for a hash with no fields
#              we know.
# Side effects: none.
#
# Some IO::Socket::SSL builds return the whole name as one string, others as
# a hash of fields whose values are array references.  Both shapes are
# accepted: reporting an empty name for one of them made subject and issuer
# compare equal, which turned every certificate into a self-signed one.
sub _name :Private
{
	my ($name) = @_;

	return '' unless defined $name;
	return $name unless ref $name;
	return '' unless ref $name eq 'HASH';

	my @parts = grep { defined && !ref && length }
		map { ref eq 'ARRAY' ? $_->[0] : $_ }
		grep { defined } @{$name}{@NAME_FIELDS};

	return join(', ', @parts) || __PACKAGE__->i18n('tls.unknown_name');
}

# _not_after
# Purpose:     the certificate's notAfter date as a string.
# Entry:       $sock is a connected IO::Socket::SSL (or a test double).
# Exit:        a date _parse_asn1_time understands, or undef.
# Side effects: none (the X509 copy is freed).
#
# peer_certificate() exposes only a handful of fields, and where not_after is
# not one of them the expiry checks used to be skipped; the certificate itself
# is still reachable through Net::SSLeay.
sub _not_after :Private
{
	my ($sock) = @_;

	my $not_after = eval { $sock->peer_certificate('not_after') };
	return $not_after if defined $not_after && !ref $not_after && length $not_after;

	my $ssl  = eval { $sock->_get_ssl_object } or return undef;
	my $x509 = eval { Net::SSLeay::get_peer_certificate($ssl) } or return undef;
	my $asn1 = eval { Net::SSLeay::X509_get_notAfter($x509) };

	# Prefer the text form; fall back to ISO 8601 if this build's text
	# form does not parse.
	my $string;
	if(defined $asn1) {
		$string = eval { Net::SSLeay::P_ASN1_TIME_put2string($asn1) };
		$string = eval { Net::SSLeay::P_ASN1_TIME_get_isotime($asn1) }
			unless defined _parse_asn1_time($string);
	}
	eval { Net::SSLeay::X509_free($x509) };

	return defined _parse_asn1_time($string) ? $string =~ s/\A\s+//r : undef;
}

# _parse_asn1_time
# Purpose:     an ASN.1 time string to an epoch.
# Entry:       $string in either text or ISO 8601 form, or undef.
# Exit:        seconds since the epoch (UTC), or undef if it does not parse.
# Side effects: none.
#
# Time::Piece->strptime was tried and rejected: it prints to STDERR when a
# month name does not parse, which would leak into a report.
sub _parse_asn1_time :Private
{
	my ($string) = @_;

	my ($sec, $min, $hour, $day, $month, $year);
	if(!defined $string) {
		return undef;
	} elsif($string =~ $ASN1_ISO) {
		($year, $month, $day, $hour, $min, $sec) = ($1, $2 - 1, $3, $4, $5, $6);
	} elsif($string =~ $ASN1_TEXT && exists $MONTH{$1}) {
		($month, $day, $hour, $min, $sec, $year) = ($MONTH{$1}, $2, $3, $4, $5, $6);
	} else {
		return undef;
	}

	# timegm croaks on an impossible date such as Feb 31.
	return eval { timegm($sec, $min, $hour, $day, $month, $year) };
}

1;

__END__

=head1 COMMON PITFALLS

=over 4

=item * B<C<ok> does not mean "trusted".>  C<ok> is 1 when a handshake
worked, even with an expired or self-signed certificate.  The certificate
is trusted only when C<ok> is 1 I<and> C<verify_error> is C<undef>.

=item * B<C<verify_error> is also C<undef> when C<ok> is not set.>  When
the first handshake fails, no verification is tried.  Always test C<ok>
first.

=item * B<C<days_left> may be missing.>  When the expiry date cannot be
read, C<days_left>, C<expires_at> and C<not_after> are not set.  Test with
C<defined>.  C<days_left> is negative after the certificate has expired.

=item * B<C<protocols> is filled in even when C<ok> is not set.>  A server
that speaks only TLS 1.0 fails the default handshake (modern OpenSSL will
not choose TLS 1.0) but still shows C<TLSv1> in C<protocols>.

=item * B<A missing version is not proof.>  If the local OpenSSL was built
without TLS 1.0, a server that accepts TLS 1.0 is not detected.  See
L</LIMITATIONS>.

=item * B<The scope is not checked here.>  Check it before you call
C<inspect>, as the main scanner does.

=item * B<It is a class method.>  Call it as
C<< App::WebPerimeterScan::TLS->inspect(...) >>.

=back

=head1 ENCODING

=over 4

=item * C<host> must be an ASCII host name or an IP address.  Write an
international name in its Punycode form; the same form is sent as SNI and
used for the name check.

=item * C<subject> and C<issuer> are the names from the certificate, as
OpenSSL prints them (for example C</CN=example.com/O=Example Ltd>).  A
name with non-ASCII characters is returned in OpenSSL's escaped form, not
as UTF-8.

=item * C<fingerprint>, C<protocol>, C<cipher> and the C<protocols> names
are always ASCII.

=item * C<error> and C<verify_error> are messages for people.  They may
contain OpenSSL's English text.  Do not compare them with a fixed string.

=back

=head1 LIMITATIONS

=over 4

=item * Self-signed detection compares the subject and issuer names.  A
certificate issued by a private CA whose name happens to match is reported
as self-signed, and a self-signed certificate whose names differ is not.
Comparing the issuer's key identifier with the subject's would be exact.

=item * Only the leaf certificate is inspected.  An intermediate that is
about to expire is not reported until verification starts to fail.

=item * The protocol probes depend on the local OpenSSL: a build compiled
without TLS 1.0 support cannot offer it at any security level, and the
server's acceptance then cannot be detected.

=item * Cipher strength is judged from the one suite negotiated by default,
not by enumerating every suite the server accepts.

=back

=head1 FORMAL SPECIFICATION

This section states exactly what each method does, in the Z notation.  You
do not need it to use the module: the method descriptions above say the same
thing in words.  It is here for reviewers and for anyone who writes tests.

How to read a schema box:

=over 4

=item * The part above the middle line declares names.  A name that ends in
C<?> is an input.  A name that ends in C<!> is an output.

=item * The part below the middle line lists facts that are true after the
call.

=item * A name with a dash after it, such as C<items'>, is the value after
the call.  The same name without the dash is the value before the call.

=item * C<Delta X> (written with the Greek capital delta) means the call
may change the state C<X>.  C<Xi X> (the Greek capital xi) means the call
does not change it.

=back

The symbols used are:

	Δ   may change            Ξ   does not change      •   such that
	∀   for all               ∃   there is             ¬   not
	∧   and                   ∨   or                   ⇒   implies
	⇔   if and only if        ≠   not equal            ≤ ≥ at most, at least
	∈   is in                 ∉   is not in            ⊆   is a subset of
	∪   union                 ∩   intersection         ∅   the empty set
	ℙ X sets of X             ⊥   undefined (undef)    …   and so on
	⟨⟩  the empty sequence    ⁀   join sequences       ⇸   partial mapping
	↦   maps to               ⊕   override a mapping   ↾   keep only these keys
	∘   compose               →   function             × ÷ − times, divide, minus
	ℕ   0, 1, 2, ...          ℕ₁  1, 2, 3, ...         ℝ   real numbers
	𝔹   true or false         ⌊x⌋ x rounded down
	dom M  the keys of M      ran M  the values of M   #S  the size of S


=head2 inspect

	┌─ Inspect ───────────────────────────────────────────
	│ host? : HOST; port? : PORT; result! : TLSRESULT
	├─────────────────────────────────────────────────────
	│ ran result!.protocols = { v : VERSIONS | handshake_v(host?, port?, v) }
	│ ¬ handshake(host?, port?) ⇒ result!.error ≠ ⊥ ∧ result!.ok = ⊥
	│ handshake(host?, port?) ⇒
	│     result!.ok = 1
	│   ∧ (result!.verify_error = ⊥ ⇔ chain_valid(host?, port?))
	│   ∧ (expiry known ⇒ result!.days_left = ⌊(not_after − now) ÷ 86400⌋)
	└─────────────────────────────────────────────────────

=head1 STATE DIAGRAM

The module keeps no state between calls.  One call to C<inspect> goes
through these steps.  Every step makes its own connection.

	  inspect(host, port, timeout)
	        |
	        v
	  +---------------+
	  |   VALIDATE    |--- unknown argument, or no host
	  +---------------+       -> croak
	        |
	        v
	  +---------------+
	  |   HANDSHAKE   |  default settings; certificate not checked
	  +---------------+
	     |          |
	     | failed   | worked
	     |          v
	     |    +---------------+
	     |    |   DESCRIBE    |  ok = 1; protocol, cipher, subject,
	     |    +---------------+  issuer, fingerprint, self_signed;
	     |          |            expiry when it can be read
	     |          v
	     |    +---------------+
	     |    |    VERIFY     |  second handshake that checks the chain
	     |    +---------------+  and the name; verify_error = undef if
	     |          |            trusted, else the reason
	     |          |
	     | error =  |
	     | reason   |
	     v          v
	  +---------------------+
	  |   PROBE VERSIONS    |  one handshake each for TLSv1, TLSv1_1,
	  +---------------------+  TLSv1_2 and TLSv1_3; each that works is
	        |                  added to protocols
	        v
	  result { host, port, protocols, ok or error, ... }

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
