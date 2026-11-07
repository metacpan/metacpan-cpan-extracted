use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

use App::WebPerimeterScan::Checks;
use App::WebPerimeterScan::Findings;

sub response
{
	my (%args) = @_;

	return {
		status      => $args{status} // 200,
		headers     => $args{headers} // {},
		body        => $args{body} // '',
		set_cookie  => $args{set_cookie} // [],
		content_type => 'text/html',
	};
}

sub ids
{
	my ($findings) = @_;

	return map { $_->{id} => 1 } @{ $findings->all };
}

sub run_page
{
	my (%args) = @_;

	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_page(
		$findings,
		host => $args{host} // 'example.com',
		url  => $args{url}  // 'https://example.com/',
		res  => $args{res},
	);

	return $findings;
}

{
	my $findings = run_page(res => response());
	my %ids = ids($findings);

	ok($ids{'hsts-missing'}, 'missing HSTS reported');
	ok($ids{'csp-missing'}, 'missing CSP reported');
	ok($ids{'clickjacking'}, 'missing frame protection reported');
	ok($ids{'nosniff-missing'}, 'missing nosniff reported');
	ok($ids{'referrer-policy-missing'}, 'missing Referrer-Policy reported');
	ok($ids{'permissions-policy-missing'}, 'missing Permissions-Policy reported');
	is($findings->count, 6, 'six header findings on a bare HTTPS page');
}

{
	my $findings = run_page(res => response(
		headers => {
			'strict-transport-security' => ['max-age=31536000; includeSubDomains'],
			'content-security-policy'   => ["default-src 'self'; frame-ancestors 'none'"],
			'x-content-type-options'    => ['nosniff'],
			'referrer-policy'           => ['strict-origin-when-cross-origin'],
			'permissions-policy'        => ['camera=()'],
			'server'                    => ['nginx'],
		},
		body => '<html><head><title>ok</title></head><body>hello</body></html>',
	));

	is($findings->count, 0, 'hardened page produces no findings');
}

{
	my $findings = run_page(url => 'http://example.com/', res => response());
	my %ids = ids($findings);
	ok(!$ids{'hsts-missing'}, 'HSTS not required on a plain HTTP page');
	ok($ids{'csp-missing'}, 'CSP still checked on plain HTTP');
}

{
	my $findings = run_page(res => response(
		headers => { 'x-powered-by' => ['PHP/8.2.20'] },
	));
	my %ids = ids($findings);
	ok($ids{'php2shell'}, 'vulnerable PHP version flagged');
	my ($php) = grep { $_->{id} eq 'php2shell' } @{ $findings->all };
	is($php->{severity}, 'critical', 'PHP2Shell is critical');
	like($php->{detail}, qr/8\.2\.35/, 'detail names the fix level');
}

{
	my $findings = run_page(res => response(
		headers => { 'x-powered-by' => ['PHP/8.4.27'] },
	));
	my %ids = ids($findings);
	ok(!$ids{'php2shell'}, 'patched PHP version not flagged');
}

{
	my $findings = run_page(res => response(
		headers => { 'x-powered-by' => ['PHP/5.6.40'] },
	));
	my %ids = ids($findings);
	ok($ids{'php2shell'}, 'end-of-life PHP flagged');
}

{
	my $findings = run_page(res => response(
		set_cookie => ['PHPSESSID=abc123; path=/; HttpOnly'],
	));
	my ($cookie) = grep { $_->{id} eq 'cookie-flags' } @{ $findings->all };
	ok($cookie, 'cookie flags reported');
	like($cookie->{title}, qr/Secure/, 'missing Secure reported');
	is($cookie->{severity}, 'medium', 'missing Secure is medium');
}

{
	my $findings = run_page(res => response(
		set_cookie => ['pref=dark; Path=/; Secure; HttpOnly; SameSite=Lax'],
	));
	my %ids = ids($findings);
	ok(!$ids{'cookie-flags'}, 'fully flagged cookie not reported');
}

{
	my $findings = run_page(res => response(
		body => '<script src="http://cdn.example.net/app.js"></script>',
	));
	my %ids = ids($findings);
	ok($ids{'mixed-content-active'}, 'active mixed content reported');
}

{
	my $findings = run_page(res => response(
		body => '<img src="http://cdn.example.net/logo.png">',
	));
	my %ids = ids($findings);
	ok($ids{'mixed-content-passive'}, 'passive mixed content reported');
	ok(!$ids{'mixed-content-active'}, 'passive content is not called active');
}

{
	my $findings = run_page(res => response(
		status => 500,
		body   => 'Warning: mysql_fetch_assoc() expects parameter 1 to be resource in /var/www/app.php on line 12',
	));
	my %ids = ids($findings);
	ok($ids{'error-disclosure'}, 'verbose error output reported');
}

{
	my $findings = run_page(res => response(
		body => '<title>Index of /backup</title>',
	));
	my %ids = ids($findings);
	ok($ids{'directory-listing'}, 'directory listing reported');
}

{
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_ports($findings,
		host => 'example.com',
		scan => {
			open => [
				{ port => 80,   banner => '' },
				{ port => 22,   banner => 'SSH-2.0-OpenSSH_7.4' },
				{ port => 3306, banner => '' },
			],
		},
	);
	my %ids = ids($findings);
	ok($ids{'port-open-3306'}, 'internet-facing database port reported');
	ok($ids{'port-open-22'}, 'SSH reported as low');
	ok($ids{'outdated-ssh-banner'}, 'old OpenSSH banner reported');
	ok(!$ids{'port-open-80'}, 'HTTP port not reported as a finding');
	ok(!$ids{'ports-other-open'}, 'no unexpected-port finding');

	my ($mysql) = grep { $_->{id} eq 'port-open-3306' } @{ $findings->all };
	is($mysql->{severity}, 'high', 'database port is high');
}

{
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_tls($findings,
		host => 'example.com',
		tls  => {
			ok        => 1,
			protocol  => 'TLSv1_2',
			cipher    => 'ECDHE-RSA-AES128-GCM-SHA256',
			protocols => ['TLSv1', 'TLSv1_2'],
			days_left => 10,
		},
	);
	my %ids = ids($findings);
	ok($ids{'tls-legacy-protocol'}, 'deprecated protocol reported');
	ok($ids{'tls-expiring'}, 'expiring certificate reported');

	my ($expiring) = grep { $_->{id} eq 'tls-expiring' } @{ $findings->all };
	is($expiring->{severity}, 'high', 'under 14 days is high');
}

{
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_tls($findings,
		host => 'example.com',
		tls  => { ok => 0, error => 'connect failed: timeout' },
	);
	my %ids = ids($findings);
	ok($ids{'tls-unavailable'}, 'failed handshake reported');
	ok(!$ids{'tls-legacy-protocol'}, 'no legacy finding without a legacy handshake');

	$findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_tls($findings,
		host => 'example.com',
		tls  => { ok => 0, error => 'protocol version', protocols => ['TLSv1'] },
	);
	%ids = ids($findings);
	ok($ids{'tls-unavailable'} && $ids{'tls-legacy-protocol'},
		'a server that only speaks TLS 1.0 is reported as such');
}

{
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_cors($findings,
		host => 'example.com',
		url  => 'https://example.com/',
		res  => {
			headers => {
				'access-control-allow-origin'      => ['*'],
				'access-control-allow-credentials' => ['true'],
			},
		},
	);
	my ($cors) = grep { $_->{id} eq 'cors-misconfiguration' } @{ $findings->all };
	ok($cors, 'permissive CORS reported');
	is($cors->{severity}, 'high', 'wildcard with credentials is high');
}

{
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_cors($findings,
		host => 'example.com',
		url  => 'https://example.com/',
		res  => { headers => { 'access-control-allow-origin' => ['https://other.example'] } },
	);
	is($findings->count, 0, 'a fixed allowlist origin is not reported');
}

{
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_methods($findings,
		host => 'example.com',
		url  => 'https://example.com/',
		res  => { headers => { allow => ['GET,HEAD,POST,TRACE'] } },
	);
	my %ids = ids($findings);
	ok($ids{'trace-enabled'}, 'TRACE reported');
}

{
	my $fingerprint = App::WebPerimeterScan::Checks::fingerprint(
		response(body => 'not found'),
	);
	is($fingerprint, App::WebPerimeterScan::Checks::fingerprint(response(body => 'not found')),
		'fingerprint is stable for identical responses');
	isnt($fingerprint, App::WebPerimeterScan::Checks::fingerprint(response(body => 'something else')),
		'fingerprint differs for different bodies');
}

# ---------------------------------------------------------------------------
# Regression tests for the rules rewritten in the refactor
# ---------------------------------------------------------------------------

sub csp_ids
{
	my ($policy) = @_;

	return { ids(run_page(res => response(headers => { 'content-security-policy' => [ $policy ] }))) };
}

subtest 'CSP: only the script sources are judged' => sub {
	my $ids = csp_ids("script-src https://*.example.com; style-src 'self'");
	ok(!$ids->{'csp-wildcard'}, 'a host wildcard is not "any origin"');

	$ids = csp_ids("default-src 'self'; script-src 'self' 'nonce-abc'; style-src 'self' 'unsafe-inline'");
	ok(!$ids->{'csp-unsafe'}, "style-src 'unsafe-inline' is not a script gap");
	ok(!$ids->{'csp-wildcard'}, 'no wildcard in script-src');

	$ids = csp_ids("script-src 'self' 'unsafe-inline' 'nonce-abc'");
	ok(!$ids->{'csp-unsafe'}, "a nonce makes browsers ignore 'unsafe-inline'");

	$ids = csp_ids("script-src 'self' 'unsafe-inline'");
	ok($ids->{'csp-unsafe'}, "'unsafe-inline' without a nonce is reported");

	$ids = csp_ids("script-src 'self' 'nonce-abc' 'unsafe-eval'");
	ok($ids->{'csp-unsafe'}, "'unsafe-eval' is reported even with a nonce");

	$ids = csp_ids("default-src *");
	ok($ids->{'csp-wildcard'}, 'default-src * applies when script-src is absent');

	$ids = csp_ids("script-src https:");
	ok($ids->{'csp-wildcard'}, 'a scheme-only source allows any origin');

	$ids = csp_ids("script-src 'nonce-abc' 'strict-dynamic' https:");
	ok(!$ids->{'csp-wildcard'}, "'strict-dynamic' makes browsers ignore scheme sources");

	$ids = csp_ids("default-src 'self'; script-src 'self'; style-src *");
	ok(!$ids->{'csp-wildcard'}, 'script-src overrides a wildcard elsewhere');

	$ids = csp_ids("frame-ancestors 'none'");
	ok(!$ids->{clickjacking}, 'frame-ancestors counts as framing protection');
};

subtest 'mixed content: classified by what the browser loads' => sub {
	my %ids = ids(run_page(res => response(body => '<link rel="canonical" href="http://example.com/x">')));
	ok(!$ids{'mixed-content-passive'} && !$ids{'mixed-content-active'}, 'a canonical link loads nothing');

	%ids = ids(run_page(res => response(body => '<link href="http://cdn.example.net/a.css" rel="stylesheet">')));
	ok($ids{'mixed-content-active'}, 'a stylesheet is active mixed content, whatever the attribute order');

	%ids = ids(run_page(res => response(body => '<object data="http://cdn.example.net/x.swf"></object>')));
	ok($ids{'mixed-content-active'}, 'object data is active mixed content');

	%ids = ids(run_page(res => response(body => '<link rel="shortcut icon" href="http://cdn.example.net/i.ico">')));
	ok($ids{'mixed-content-passive'}, 'an icon is passive mixed content');

	%ids = ids(run_page(url => 'http://example.com/', res => response(body => '<script src="http://cdn.example.net/a.js"></script>')));
	ok(!$ids{'mixed-content-active'}, 'a plain HTTP page has no mixed content');
};

subtest 'HTML parsing for disclosure rules' => sub {
	my $findings = run_page(res => response(body => q{<meta content="WordPress 6.4" name='generator'>}));
	my ($generator) = grep { $_->{id} eq 'generator-disclosed' } @{ $findings->all };
	ok($generator, 'generator found with content before name');
	like($generator->{title}, qr/WordPress 6\.4/, 'the generator is named');

	my %ids = ids(run_page(res => response(body => '<p>Index of /backup</p>')));
	ok(!$ids{'directory-listing'}, 'the phrase outside <title> is not a listing');
};

subtest 'versions compare as dotted decimals' => sub {
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_ports($findings, host => 'h', scan => { open => [
		{ port => 22,   banner => 'SSH-2.0-OpenSSH_8.9p1' },
		{ port => 2222, banner => 'SSH-2.0-OpenSSH_9.10' },
	] });
	my ($ssh) = grep { $_->{id} eq 'outdated-ssh-banner' } @{ $findings->all };
	ok($ssh, 'OpenSSH 8.9 is older than 9.0');
	unlike($ssh->{evidence}, qr/9\.10/, 'OpenSSH 9.10 is not older than 9.0');

	my %ids = ids(run_page(res => response(headers => { 'x-powered-by' => ['PHP/8.2.35'] })));
	ok(!$ids{php2shell}, 'exactly the fix level is fixed');

	%ids = ids(run_page(res => response(headers => { 'x-powered-by' => ['PHP/8.1.99'] })));
	ok($ids{php2shell}, 'a branch older than every fix is vulnerable');

	%ids = ids(run_page(res => response(headers => { 'x-powered-by' => ['PHP/8.6.0'] })));
	ok(!$ids{php2shell}, 'a branch newer than the table is assumed fixed');

	my ($php) = grep { $_->{id} eq 'php2shell' } @{ run_page(res => response(headers => { 'x-powered-by' => ['PHP/8.3.1'] }))->all };
	unlike($php->{fix}, qr/in this repository/, 'the fix no longer points at a directory that does not exist');
	like($php->{fix}, qr{8\.5\.12 / 8\.4\.27 / 8\.3\.36 / 8\.2\.35}, 'fix levels newest first');
};

subtest 'severity edges' => sub {
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_tls($findings, host => 'h', tls => {
		ok => 1, protocols => ['TLSv1_1'], days_left => 20, cipher => 'ECDHE-RSA-DES-CBC3-SHA',
	});
	my %by_id = map { $_->{id} => $_ } @{ $findings->all };
	is($by_id{'tls-legacy-protocol'}{severity}, 'medium', 'TLS 1.1 alone is medium');
	is($by_id{'tls-expiring'}{severity}, 'medium', '14 to 29 days is medium');
	ok($by_id{'tls-weak-cipher'}, '3DES is a weak cipher');

	$findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_tls($findings, host => 'h', tls => { ok => 1, days_left => -1, not_after => 'X' });
	my ($expired) = @{ $findings->all };
	is($expired->{title}, 'TLS certificate expired 1 day ago', 'singular day');

	$findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_cors($findings, host => 'h', url => 'u', res => { headers => {
		'access-control-allow-origin' => [ App::WebPerimeterScan::Checks::probe_origin() ],
	} });
	is($findings->all->[0]{severity}, 'medium', 'a reflected origin without credentials is medium');
	like($findings->all->[0]{detail}, qr/echoes back/, 'the detail matches the case');
};

subtest 'check_* return the collector and validate it' => sub {
	my $findings = App::WebPerimeterScan::Findings->new;
	is(App::WebPerimeterScan::Checks::check_methods($findings, res => undef), $findings,
		'returns the collector for chaining');
	ok(!eval { App::WebPerimeterScan::Checks::check_page({}, res => response()); 1 },
		'a non-collector is refused');
	like($@, qr/findings/, 'the error names the parameter');
};

subtest 'probe table is shared and read-only' => sub {
	my $probes = App::WebPerimeterScan::Checks::sensitive_probes();
	is(ref $probes, 'ARRAY', 'an array reference');
	ok((grep { $_->{path} eq '/.env' } @{$probes}), 'the .env probe is listed');
	ok(!eval { $probes->[0]{severity} = 'info'; 1 }, 'entries cannot be changed by the caller');
};

subtest 'path probes against a fake client' => sub {
	{
		package Fake::HTTP;
		sub new { my ($class, %pages) = @_; return bless { pages => \%pages, seen => [] }, $class }
		sub fetch {
			my ($self, $url) = @_;
			push @{ $self->{seen} }, $url;
			my ($path) = $url =~ m{\Ahttps?://[^/]+(/.*)\z};
			my $body = $self->{pages}{$path // ''};
			return defined $body ? { status => 200, body => $body } : { status => 404, body => 'nope' };
		}
	}

	my $http = Fake::HTTP->new(
		'/.git/config'              => "[core]\n\trepositoryformatversion = 0\n",
		'/.env'                     => '<html>catch-all</html>',
		'/robots.txt'               => "User-agent: *\nDisallow: /admin\nDisallow: /secret\n",
		'/.well-known/security.txt' => "Contact: mailto:security\@example.com\n",
	);
	my $findings = App::WebPerimeterScan::Findings->new;
	App::WebPerimeterScan::Checks::check_paths($findings,
		http => $http, host => 'example.com', base => 'https://example.com/', baseline => '');
	my %ids = ids($findings);

	ok($ids{'git-exposed'}, 'a real .git/config is reported');
	ok(!$ids{'env-exposed'}, 'a 200 that does not look like the file is not');
	ok($ids{'robots-disclosure'}, 'robots.txt paths are reported');
	ok($ids{'security-txt-present'}, 'security.txt is noted');
	my ($robots) = grep { $_->{id} eq 'robots-disclosure' } @{ $findings->all };
	is($robots->{title}, 'robots.txt names 2 paths', 'plural title') or diag explain $robots;
	ok(!(grep { m{//\.git} } @{ $http->{seen} }), 'no double slash after the base URL');
};

done_testing();
