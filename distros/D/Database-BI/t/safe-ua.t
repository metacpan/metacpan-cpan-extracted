#!/usr/bin/env perl

# Database::BI::SafeUA: the fetcher for url: sources and /import.  A URL must
# not lead the server to this machine or a private network, whatever its text
# says, and wherever a redirect points.  Nothing here touches the network: the
# resolver is injected, and LWP::UserAgent::send_request (what SafeUA calls
# once a request passes) is replaced, so a request that is let through is
# recorded instead of sent.
#
#   prove -l t/safe-ua.t

use strict;
use warnings;

use Test::Most;
use Test::Mojo;

use File::Temp qw(tempdir);
use HTTP::Request;
use HTTP::Response;
use Mojo::Util qw(url_escape);

use Database::BI::SafeUA;

my %DNS = (
	'example.com'           => ['93.184.215.14'],
	'localtest.me'          => ['127.0.0.1'],
	'127.0.0.1.nip.io'      => ['127.0.0.1'],
	'metadata.example'      => ['169.254.169.254'],
	'v6local.example'       => ['::1'],
	'mapped.example'        => ['::ffff:10.0.0.1'],
	'both.example'          => ['93.184.215.14', '10.0.0.5'],
	'intranet.corp.example' => ['10.1.2.3'],
	'deep.corp.example'     => ['10.1.2.4'],
	'public6.example'       => ['2606:2800:21f:cb07::1'],
);
my @resolved;
sub fake_resolve {
	my ($host) = @_;
	push @resolved, $host;
	return @{ $DNS{$host} // [] };
}

# What reached LWP, and what it answers: a 200, or the next redirect.
my (@sent, %redirect);
no warnings 'redefine';
local *LWP::UserAgent::send_request = sub {
	my ($self, $request) = @_;
	push @sent, $request->clone;
	my $to = $redirect{ $request->header('Host') };
	my $res = $to ? HTTP::Response->new(302, 'Found', [ Location => $to ]) : HTTP::Response->new(200, 'OK', [], 'fetched');
	$res->request($request);
	return $res;
};
use warnings 'redefine';

sub ua { Database::BI::SafeUA->new(resolve => \&fake_resolve, @_) }

sub fetch {
	my ($url, @args) = @_;
	@sent = ();
	return ua(@args)->get($url);
}

subtest 'blocked_address' => sub {
	my %want = (
		'127.0.0.1'           => qr/this machine/,
		'127.255.255.254'     => qr/this machine/,
		'10.9.8.7'            => qr/private/,
		'172.16.0.1'          => qr/private/,
		'172.31.255.255'      => qr/private/,
		'192.168.1.1'         => qr/private/,
		'169.254.169.254'     => qr/metadata/,
		'100.64.0.1'          => qr/shared/,
		'0.0.0.0'             => qr/not an address/,
		'224.0.0.1'           => qr/multicast/,
		'255.255.255.255'     => qr/reserved/,
		'::1'                 => qr/this machine/,
		'[::1]'               => qr/this machine/,
		'::'                  => qr/not an address/,
		'fe80::1%eth0'        => qr/link-local/,
		'fd00::1'             => qr/private/,
		'::ffff:127.0.0.1'    => qr/this machine/,
		'::ffff:169.254.169.254' => qr/metadata/,
		'64:ff9b::a00:1'      => qr/private/,
		'2002:7f00:1::'       => qr/this machine/,
		'::10.0.0.1'          => qr/private/,
		'not an ip'           => qr/not an address/,
		''                    => qr/not an address/,
	);
	for my $ip (sort keys %want) {
		like Database::BI::SafeUA::blocked_address($ip) // '', $want{$ip}, "'$ip' is refused";
	}
	for my $ip ('93.184.215.14', '8.8.8.8', '172.32.0.1', '172.15.255.255', '11.0.0.1', '2606:4700::1111', '::ffff:8.8.8.8') {
		is Database::BI::SafeUA::blocked_address($ip), undef, "'$ip' is public";
	}
};

subtest 'numeric_host: what the resolver reads as an address' => sub {
	my %want = (
		'127.0.0.1'   => '127.0.0.1',
		'127.1'       => '127.0.0.1',
		'10.1'        => '10.0.0.1',
		'2130706433'  => '127.0.0.1',
		'0x7f000001'  => '127.0.0.1',
		'0177.0.0.1'  => '127.0.0.1',
		'127.0.0.1.'  => '127.0.0.1',
		'[::1]'       => '::1',
		'::1'         => '::1',
	);
	is Database::BI::SafeUA::numeric_host($_), $want{$_}, "'$_'" for sort keys %want;
	is Database::BI::SafeUA::numeric_host($_), undef, "'$_' is a name"
		for 'example.com', 'localtest.me', '127.0.0.1.nip.io', '1e3.example', '0x.example';
};

subtest 'numeric_host: read the same way on every platform' => sub {
	# macOS does not read 0177.0.0.1 as 127.0.0.1, so it passed as public
	# there.  numeric_host reads these itself, as glibc and the BSDs do.
	# A stand-in that reads each part as decimal, so the old reliance on it fails
	# here too.
	no warnings qw(redefine once);
	local *Database::BI::SafeUA::inet_aton = sub {
		my @p = split /\./, shift;
		return undef unless @p == 4 && !grep { !/\A[0-9]+\z/ || $_ > 255 } @p;
		return pack 'C4', map { $_ + 0 } @p;
	};
	my %want = (
		'0177.0.0.1'         => '127.0.0.1',
		'017700000001'       => '127.0.0.1',
		'0x7f.1'             => '127.0.0.1',
		'127.0.1'            => '127.0.0.1',
		'10.0x0.0.010'       => '10.0.0.8',
		'0x000000007f000001' => '127.0.0.1',
		'1.2.65535'          => '1.2.255.255',
		'4294967295'         => '255.255.255.255',
		'0'                  => '0.0.0.0',
	);
	is Database::BI::SafeUA::numeric_host($_), $want{$_}, "'$_'" for sort keys %want;
	is Database::BI::SafeUA::numeric_host($_), undef, "'$_' is not an address"
		for '08.0.0.1', '256.1.1.1', '1.2.3.256', '1.2.65536', '4294967296', '0x100000000', '0x', '00x1',
			'99999999999', '1.2.3.4.5';
};

subtest 'names that resolve to this machine or a private network are refused' => sub {
	for my $url ('http://localtest.me/', 'http://127.0.0.1.nip.io/', 'https://metadata.example/latest/meta-data/',
		'http://v6local.example/', 'http://mapped.example/', 'http://both.example/', 'http://LocalTest.ME./') {
		my $res = fetch($url);
		is $res->code, 403, "$url";
		is $res->header('Client-Warning'), 'Internal response', '... as LWP reports its own failures';
		ok !@sent, '... and nothing is sent';
	}
	like fetch('http://localtest.me/')->message, qr/localtest\.me is 127\.0\.0\.1, which is this machine/, 'the reason says why';
	like fetch('http://both.example/')->message, qr/10\.0\.0\.5/, 'one private address among public ones is enough';
	like fetch('http://nowhere.example/')->message, qr/was not found/, 'a name that does not resolve';
	ok !@sent, '... is not sent either';
};

subtest 'addresses written in any form are refused, without a lookup' => sub {
	@resolved = ();
	for my $url ('http://127.0.0.1/', 'http://2130706433/', 'http://0x7f000001/', 'http://0177.0.0.1/', 'http://127.1/',
		'http://[::1]/', 'http://[::ffff:127.0.0.1]/', 'http://169.254.169.254/', 'http://user@127.0.0.1/',
		'http://example.com@127.0.0.1/', 'http://127.0.0.1:8080/') {
		is fetch($url)->code, 403, $url;
	}
	ok !@sent, 'nothing sent';
	is_deeply \@resolved, [], 'and nothing looked up';
	like fetch('http://127.0.0.1/')->message, qr/127\.0\.0\.1 is this machine/, 'the reason does not say the address twice';
};

subtest 'only http and https' => sub {
	for my $url ('file:///etc/passwd', 'ftp://example.com/x', 'gopher://example.com/') {
		my $res = fetch($url);
		isnt $res->code, 200, "$url is not fetched";
	}
	ok !@sent, 'nothing sent';
};

subtest 'a public name is sent to the address checked, with its name kept' => sub {
	my $res = fetch('http://example.com:8080/a/table.html?x=1');
	is $res->code, 200, 'fetched';
	is scalar(@sent), 1, 'once';
	is $sent[0]->uri, 'http://93.184.215.14:8080/a/table.html?x=1', 'to the address that was checked';
	is $sent[0]->header('Host'), 'example.com:8080', 'the Host header names the site';
	is $res->request->uri, 'http://example.com:8080/a/table.html?x=1', 'the reply is for the URL asked for';

	fetch('http://reader:pw@example.com/');
	is $sent[0]->header('Host'), 'example.com', 'no user name in the Host header';

	fetch('http://public6.example/');
	is $sent[0]->uri->host, '2606:2800:21f:cb07::1', 'an IPv6 address';
	like $sent[0]->uri, qr{\Ahttp://\[2606:2800:21f:cb07::1\]/}, '... in brackets';
};

subtest 'https keeps the name for SNI and the certificate check' => sub {
	my $ua = ua(ssl_opts => { verify_hostname => 1 });
	my $seen;
	no warnings 'redefine';
	local *LWP::UserAgent::send_request = sub {
		my ($self, $request) = @_;
		$seen = { %{ $self->{ssl_opts} }, uri => $request->uri . '' };
		return HTTP::Response->new(200, 'OK');
	};
	use warnings 'redefine';
	$ua->get('https://example.com/x');
	is $seen->{uri}, 'https://93.184.215.14/x', 'connects to the address';
	is $seen->{SSL_hostname}, 'example.com', 'the TLS server name is the site';
	is $seen->{SSL_verifycn_name}, 'example.com', 'and so is the name the certificate must carry';
	is $seen->{verify_hostname}, 1, 'the caller\'s options are kept';
	ok !exists $ua->{ssl_opts}{SSL_hostname}, 'and the pin lasts only for that request';
};

subtest 'a redirect is checked as the first request was' => sub {
	%redirect = ('example.com' => 'http://localtest.me/admin');
	my $res = fetch('http://example.com/');
	is $res->code, 403, 'a public site that redirects to this machine';
	is scalar(@sent), 1, 'only the first request was sent';
	%redirect = ('example.com' => 'http://169.254.169.254/latest/meta-data/');
	is fetch('http://example.com/')->code, 403, 'or to the metadata service, by address';
	%redirect = ('example.com' => 'https://public6.example/');
	is fetch('http://example.com/')->code, 200, 'a redirect to a public site is followed';
	is scalar(@sent), 2, '... both requests sent';
	%redirect = ('example.com' => 'http://example.com/');
	fetch('http://example.com/');
	is scalar(@sent), 6, 'at most 5 redirects';
	%redirect = ();
};

subtest 'private_hosts: an intranet that may be read' => sub {
	my @allow = (private_hosts => [ 'Intranet.Corp.Example', '*.corp.example' ]);
	is fetch('http://intranet.corp.example/', @allow)->code, 200, 'a name listed';
	is fetch('http://deep.corp.example/', @allow)->code, 200, 'a subdomain of *.corp.example';
	is fetch('http://intranet.corp.example/')->code, 403, 'unlisted, the same name is refused';
	is fetch('http://localtest.me/', @allow)->code, 403, 'other names are still checked';
	is fetch('http://10.1.2.3/', private_hosts => ['10.1.2.3'])->code, 403, 'an address is never one of them';
	ok !ua(@allow)->private_host_allowed('corp.example'), '*.corp.example is not corp.example itself';
	ok !ua(@allow)->private_host_allowed('evilcorp.example'), 'nor a name that only ends the same way';
};

subtest 'the default resolver' => sub {
	my @ips = Database::BI::SafeUA::resolve_host('localhost');
	ok @ips, 'localhost resolves' or diag 'no localhost here';
	ok !(grep { !Database::BI::SafeUA::blocked_address($_) } @ips), 'and every address it gives is refused';
	is_deeply [ Database::BI::SafeUA::resolve_host('no-such-host.invalid') ], [], '.invalid never resolves';
};

subtest 'the application' => sub {
	my %config = (model_dir => tempdir(CLEANUP => 1));
	my $t = Test::Mojo->new('Database::BI', \%config);
	for my $url ('http://2130706433/', 'http://0x7f000001/', 'http://user@127.0.0.1/', 'http://::1/', 'http://localhost./') {
		$t->get_ok('/import?url=' . url_escape($url))->status_is(200)
			->content_like(qr/private or reserved address and cannot be fetched/, "/import refuses $url before fetching");
	}
	for my $bad ('corp.example', [undef], ['*'], ['*.'], ['http://x.example'], ['x'], [[]]) {
		throws_ok { Test::Mojo->new('Database::BI', { %config, url_private_hosts => $bad }) }
			qr/url_private_hosts/, 'url_private_hosts ' . Mojo::JSON::encode_json($bad) . ' stops the start';
	}
	lives_ok { Test::Mojo->new('Database::BI', { %config, url_private_hosts => [ 'reports.corp.example', '*.corp.example' ] }) }
		'names and *.suffix are accepted';

	# A url: source on a page goes through SafeUA, so a name that resolves to
	# this machine is refused when it is fetched.
	no warnings 'redefine';
	local *Database::BI::SafeUA::resolve_host = sub { $_[0] eq 'sneaky.example' ? ('127.0.0.1') : () };
	use warnings 'redefine';
	@sent = ();
	$t->get_ok('/import?url=' . url_escape('http://sneaky.example/t.html'))
		->content_like(qr/sneaky\.example is 127\.0\.0\.1, which is this machine/, '/import: a name that resolves to this machine');
	$t->get_ok('/bar?l=' . url_escape('url:http://sneaky.example/t.csv') . '&cat=a&val=b');
	ok !@sent, 'neither it nor a url: source is fetched';
};

done_testing();
