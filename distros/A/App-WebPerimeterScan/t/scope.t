use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Temp qw(tempfile);
use Socket ();
use Test::More;
use Test::Fatal;

use App::WebPerimeterScan::Scope;

my ($fh, $filename) = tempfile(UNLINK => 1);
print $fh <<'SCOPE';
# a comment
example.com
www.example.com:8443
https://shop.example.com/
*.wild.example
this is not a host!!
SCOPE
close $fh;

my $scope = App::WebPerimeterScan::Scope->new;

{
	local $SIG{__WARN__} = sub { };
	$scope->load_file($filename);
}

ok($scope->covers('example.com'), 'exact host is covered');
ok($scope->covers('EXAMPLE.COM.'), 'case and trailing dot are normalised');
ok($scope->covers('sub.wild.example'), 'wildcard covers a sub-domain');
ok($scope->covers('wild.example'), 'wildcard covers the domain itself');
ok(!$scope->covers('evil.com'), 'unrelated host is not covered');
ok(!$scope->covers('notexample.com'), 'suffix match is on label boundary');

my @hosts = @{ $scope->hosts };
is(scalar @hosts, 3, 'wildcard is not a concrete scan target');
is_deeply([ sort map { $_->{host} } @hosts ],
	[qw(example.com shop.example.com www.example.com)], 'concrete hosts parsed');

my $port_entry = (grep { $_->{host} eq 'www.example.com' } @hosts)[0];
is($port_entry->{port}, 8443, 'explicit port kept');

my $https_entry = (grep { $_->{host} eq 'shop.example.com' } @hosts)[0];
is($https_entry->{scheme}, 'https', 'scheme kept from URL form');

like(exception { $scope->assert_target_allowed('evil.com') },
	qr/not listed in/, 'out-of-scope host is refused');

{
	# No real DNS in the tests: the name resolves to a public address.
	no warnings 'redefine';
	local *App::WebPerimeterScan::Scope::getaddrinfo = sub {
		return ('', { addr => Socket::pack_sockaddr_in(0, Socket::inet_aton('93.184.215.14')) });
	};
	is($scope->assert_target_allowed('example.com'), $scope, 'in-scope host is allowed, and the scope returned');
}

ok($scope->is_private_target('127.0.0.1'), 'loopback detected');
ok($scope->is_private_target('10.1.2.3'), 'RFC1918 10/8 detected');
ok($scope->is_private_target('192.168.0.5'), 'RFC1918 192.168/16 detected');
ok(!$scope->is_private_target('8.8.8.8'), 'public address not treated as private');

my $private_scope = App::WebPerimeterScan::Scope->new;
my ($pfh, $pfile) = tempfile(UNLINK => 1);
print $pfh "127.0.0.1\n";
close $pfh;
$private_scope->load_file($pfile);

like(exception { $private_scope->assert_target_allowed('127.0.0.1') },
	qr/private address space/, 'private target refused by default');

my $permitted = App::WebPerimeterScan::Scope->new(allow_private => 1);
$permitted->load_file($pfile);
is($permitted->assert_target_allowed('127.0.0.1'), $permitted, 'private target allowed with allow_private');

is($https_entry->{port}, undef, 'a URL without a port records no port, so the HTTP-to-HTTPS check runs');

subtest 'URL entries and ports' => sub {
	my ($fh, $file) = tempfile(UNLINK => 1);
	print $fh "https://a.example:8443/\nhttp://b.example/\nc.example:0\nd.example:70000\n";
	close $fh;

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $s = App::WebPerimeterScan::Scope->new->load_file($file);
	my %by_host = map { $_->{host} => $_ } @{ $s->hosts };

	is($by_host{'a.example'}{port}, 8443, 'an explicit port in a URL is kept');
	is($by_host{'b.example'}{scheme}, 'http', 'the scheme is kept');
	ok(!$by_host{'c.example'} && !$by_host{'d.example'}, 'ports outside 1-65535 are rejected');
	is(scalar @warnings, 2, 'one warning per rejected line');
};

subtest 'private address space' => sub {
	# Literal addresses only, so no test depends on DNS.
	ok(!$scope->is_private_target('192.30.252.1'), '192.30/16 is public (the old mask covered 192/8)');
	ok(!$scope->is_private_target('223.5.5.5'), '223/8 is public unicast, not multicast');
	ok($scope->is_private_target('224.0.0.1'), 'multicast is not a public target');
	ok($scope->is_private_target('192.0.2.7'), 'TEST-NET-1 is refused');
	ok($scope->is_private_target('198.51.100.7'), 'TEST-NET-2 is refused');
	ok($scope->is_private_target('203.0.113.7'), 'TEST-NET-3 is refused');
	ok($scope->is_private_target('198.18.0.1'), 'the benchmarking range is refused');
	ok($scope->is_private_target('100.64.0.1'), 'CGNAT is refused');
	ok($scope->is_private_target('::1'), 'IPv6 loopback is refused');
	ok($scope->is_private_target('fd00::1'), 'IPv6 unique-local is refused');
	ok($scope->is_private_target('fe80::1'), 'IPv6 link-local is refused');
	ok(!$scope->is_private_target('2606:4700::1'), 'a public IPv6 address is allowed');
	{
		# No real DNS in the tests: the lookup fails, as for an unknown name.
		no warnings 'redefine';
		local *App::WebPerimeterScan::Scope::getaddrinfo = sub { return ('Name or service not known') };
		ok(!$scope->is_private_target('name.invalid'), 'a name that does not resolve is not private');
	}
};

subtest 'address literals do not depend on the resolver' => sub {
	# Older Windows Perls fail getaddrinfo on IPv6 literals, which used to
	# let ::1 through as "not private".  Make every lookup fail to prove a
	# literal is classified without one.
	no warnings 'redefine';
	local *App::WebPerimeterScan::Scope::getaddrinfo = sub { return ('lookup disabled by the test') };

	ok($scope->is_private_target('::1'), 'IPv6 loopback');
	ok($scope->is_private_target('[fe80::1]'), 'bracketed IPv6 link-local');
	ok($scope->is_private_target('fe80::1%eth0'), 'IPv6 with a zone index');
	ok($scope->is_private_target('127.0.0.1'), 'IPv4 loopback');
	ok(!$scope->is_private_target('2606:4700::1'), 'a public IPv6 literal is still public');
	ok(!$scope->is_private_target('localhost'), 'a name now resolves to nothing, as on the failing platform');
};

subtest 'international (non-ASCII) host names' => sub {
	# The file holds UTF-8 bytes, as an editor saves it.  A URL line used to
	# be converted from those bytes to the wrong Punycode
	# (xn--bcher-lka2c.example), and a bare name was refused.
	my ($idn_fh, $idn_file) = tempfile(UNLINK => 1);
	binmode $idn_fh;
	print {$idn_fh} join "\n",
		"b\xc3\xbccher.example",			# bucher, u with umlaut
		"https://\xc3\xa9t\xc3\xa9.example:8443/",	# ete, e with acute
		"*.m\xc3\xbcnchen.example",
		"b\xc3\xbccher.example:99999",			# bad port: still refused
		'';
	close $idn_fh;

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $idn = App::WebPerimeterScan::Scope->new->load_file($idn_file);

	is_deeply(
		[ map { [ $_->{host}, $_->{port}, $_->{wildcard} ] } @{ $idn->entries } ],
		[
			[ 'xn--bcher-kva.example',  undef, undef ],
			[ 'xn--t-9fab.example',     8443,  undef ],
			[ 'xn--mnchen-3ya.example', undef, 1 ],
		],
		'bare, URL and wildcard lines get the correct Punycode name, port and wildcard kept',
	);
	is(scalar @warnings, 1, 'only the bad-port line is reported');
	like($warnings[0] // '', qr/b\xc3\xbccher\.example:99999/, '... as it was written in the file');

	ok($idn->covers('xn--bcher-kva.example'), 'covers the Punycode form');
	ok($idn->covers("b\xc3\xbccher.example"), 'covers the name given as UTF-8 bytes');
	ok($idn->covers("B\x{fc}CHER.Example"), 'covers the name given as characters, in any case');
	ok($idn->covers('www.xn--mnchen-3ya.example'), 'the wildcard covers a sub-domain');
	ok(!$idn->covers('xn--bcher-lka2c.example'), 'the old, wrong Punycode is not in scope');
	ok(!$idn->covers("b\xc3\xbccher.example.evil"), 'a longer name is not covered');

	# Name lookups use the ASCII form too.
	my @looked_up;
	no warnings 'redefine';
	local *App::WebPerimeterScan::Scope::getaddrinfo = sub { push @looked_up, $_[0]; return ('not found') };
	$idn->is_private_target("b\xc3\xbccher.example");
	is_deeply(\@looked_up, [ 'xn--bcher-kva.example' ], 'the DNS lookup is for the Punycode name');
};

subtest 'allows' => sub {
	my $wild = App::WebPerimeterScan::Scope->new;
	my ($fh, $file) = tempfile(UNLINK => 1);
	print $fh "127.0.0.1\n8.8.8.8\n";
	close $fh;
	$wild->load_file($file);

	ok(!$wild->allows('127.0.0.1'), 'covered but private is not allowed');
	ok($wild->allows('8.8.8.8'), 'covered and public is allowed');
	ok(!$wild->allows('9.9.9.9'), 'public but not covered is not allowed');
	ok(!$wild->allows(undef), 'undef is not allowed');
};

subtest 'errors' => sub {
	my $missing = '/nonexistent-' . $$ . '/scope.txt';
	my $error = exception { App::WebPerimeterScan::Scope->new->load_file($missing) };
	like($error, qr/Cannot read scope file '\Q$missing\E'/, 'an unreadable file is reported by name');
	like($error, qr/ at \S*scope\.t line/, "the error is reported from the caller's line");

	my ($fh, $empty) = tempfile(UNLINK => 1);
	print $fh "# nothing\n\n";
	close $fh;
	like(exception { App::WebPerimeterScan::Scope->new->load_file($empty) }, qr/no usable hosts/, 'an empty scope is refused');
	ok(!eval { App::WebPerimeterScan::Scope->new(bogus => 1); 1 }, 'an unknown argument is refused');
	is(App::WebPerimeterScan::Scope->new->source, '(none)', 'a new scope has no source');
};

done_testing();
