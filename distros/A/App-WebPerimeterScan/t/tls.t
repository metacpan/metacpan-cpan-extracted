use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Spec;
use Test::More;

use Time::Local qw(timegm);

use App::WebPerimeterScan::TLS;

# White-box: the helpers under test are private.
$Sub::Private::BYPASS = 1;

# IO::Socket::SSL has returned certificate names both ways: as a single
# string, and as a hash of fields whose values are array references.  Reading
# either shape as an empty name made subject and issuer compare equal, so
# every certificate was reported as self-signed.
is(App::WebPerimeterScan::TLS::_name('/CN=example.com'), '/CN=example.com',
	'a name given as one string is kept as it is');
is(App::WebPerimeterScan::TLS::_name({ commonName => ['example.com'] }), 'example.com',
	'a name given as a hash of array references is joined');
is(App::WebPerimeterScan::TLS::_name({ commonName => 'example.com' }), 'example.com',
	'a plain scalar field is accepted too');
is(App::WebPerimeterScan::TLS::_name({}), 'unknown',
	'a name with no usable fields says so');
is(App::WebPerimeterScan::TLS::_name(undef), '',
	'a missing name is empty, not unknown');

my $subject = App::WebPerimeterScan::TLS::_name('/CN=example.com');
my $issuer  = App::WebPerimeterScan::TLS::_name('/C=US/O=SSL Corporation/CN=Cloudflare TLS Issuing ECC CA 3');
isnt($subject, $issuer, 'a certificate with a separate issuer does not look self-signed');

is(App::WebPerimeterScan::TLS::_parse_asn1_time('Dec 25 22:56:35 2026 GMT'),
	timegm(35, 56, 22, 25, 11, 2026), 'notAfter is parsed as UTC');
is(App::WebPerimeterScan::TLS::_parse_asn1_time('garbage'), undef,
	'unparsable dates are rejected');
is(App::WebPerimeterScan::TLS::_parse_asn1_time('Xyz  1 00:00:00 2027 GMT'), undef,
	'an unknown month is rejected');
is(App::WebPerimeterScan::TLS::_parse_asn1_time(' Dec 25 22:56:35 2026 GMT'),
	timegm(35, 56, 22, 25, 11, 2026), 'leading white space is tolerated');
is(App::WebPerimeterScan::TLS::_parse_asn1_time('2026-12-25T22:56:35Z'),
	timegm(35, 56, 22, 25, 11, 2026), 'the ISO 8601 form is parsed too');

# This machine's IO::Socket::SSL has no not_after field, and skipping the
# expiry checks there would have hidden an expired certificate.
{
	package Fake::TLS;

	sub new { bless {}, shift }
	sub peer_certificate { die "invalid argument for peer_certificate\n" }
	sub _get_ssl_object { undef }
}
{
	package Fake::TLS::Dated;

	our @ISA = ('Fake::TLS');
	sub peer_certificate { 'Dec 25 22:56:35 2026 GMT' }
}

is(App::WebPerimeterScan::TLS::_not_after(Fake::TLS->new()), undef,
	'an unreadable expiry stays unknown instead of being fatal');
is(App::WebPerimeterScan::TLS::_not_after(Fake::TLS::Dated->new()),
	'Dec 25 22:56:35 2026 GMT', 'a build that does offer not_after is used as it is');

is(App::WebPerimeterScan::TLS::_parse_asn1_time('Feb 31 00:00:00 2027 GMT'), undef,
	'an impossible date is rejected rather than fatal');
is(App::WebPerimeterScan::TLS::_parse_asn1_time(undef), undef, 'undef is not a date');

ok(!eval { App::WebPerimeterScan::TLS->inspect(port => 443); 1 }, 'inspect() needs a host');
ok(!eval { App::WebPerimeterScan::TLS->inspect(host => 'h', port => 0); 1 }, 'port 0 is refused');

# OpenSSL 3 will not offer TLS 1.0 at its default security level, so a probe
# without @SECLEVEL=0 fails locally and a server that accepts TLS 1.0 was
# never reported.  Prove the probe against a real TLS 1.0-only server.
SKIP: {
	skip 'needs a Unix-like system to run openssl s_server', 1 if $^O eq 'MSWin32';
	my $openssl = (grep { -x "$_/openssl" } split /:/, $ENV{PATH} // '')[0];
	skip 'openssl is not installed', 1 unless $openssl;

	require File::Temp;
	require IO::Socket::INET;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	# openssl req chatters on STDERR; silence it for the one call.
	open my $saved_stderr, '>&', \*STDERR or skip 'cannot save STDERR', 1;
	open STDERR, '>', File::Spec->devnull;
	my $status = system("$openssl/openssl", 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
		'-keyout', "$dir/k.pem", '-out', "$dir/c.pem", '-days', '1', '-subj', '/CN=localhost');
	open STDERR, '>&', $saved_stderr;
	skip 'cannot make a test certificate', 1 unless $status == 0;

	# A free port: bind, read it, release.
	my $probe = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1) or skip 'no port', 1;
	my $port = $probe->sockport;
	close $probe;

	my $pid = fork() // skip 'cannot fork', 1;
	if(!$pid) {
		open STDOUT, '>', File::Spec->devnull;
		open STDERR, '>', File::Spec->devnull;
		exec("$openssl/openssl", 's_server', '-accept', "127.0.0.1:$port", '-cert', "$dir/c.pem",
			'-key', "$dir/k.pem", '-tls1', '-cipher', 'DEFAULT:@SECLEVEL=0', '-www', '-quiet');
		exit 1;
	}

	# Wait for the server to listen.
	my $up;
	for (1 .. 50) {
		last if $up = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Timeout => 1);
		select(undef, undef, undef, 0.1);
	}
	if(!$up) {
		kill 'TERM', $pid;
		waitpid $pid, 0;
		skip 'openssl s_server did not start', 1;
	}
	close $up;

	my $tls = App::WebPerimeterScan::TLS->inspect(host => '127.0.0.1', port => $port, timeout => 3);
	kill 'TERM', $pid;
	waitpid $pid, 0;

	ok((grep { $_ eq 'TLSv1' } @{ $tls->{protocols} }), 'a server that accepts TLS 1.0 is detected')
		or diag explain $tls;
}

done_testing();
