use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use File::Temp qw(tempdir tempfile);
use Test::More;

use App::WebPerimeterScan;
use App::WebPerimeterScan::Scope;

# White-box: the runner's private helpers are tested directly below.
$Sub::Private::BYPASS = 1;

subtest 'root candidates and the TLS port' => sub {
	my $scanner = App::WebPerimeterScan->new;

	is_deeply($scanner->_root_candidates({ host => 'h' }), [ 'https://h/', 'http://h/' ], 'HTTPS first, then HTTP');
	is_deeply($scanner->_root_candidates({ host => 'h', port => 8443 }), [ 'https://h:8443/' ], '8443 implies HTTPS');
	is_deeply($scanner->_root_candidates({ host => 'h', port => 8080 }), [ 'http://h:8080/' ], 'another port implies HTTP');
	is_deeply($scanner->_root_candidates({ host => 'h', scheme => 'http' }), [ 'http://h/' ], 'the scheme is honoured');

	my $scan = sub { return { open => [ map { { port => $_ } } @_ ] } };
	is($scanner->_tls_port('http://h/', $scan->(80, 8443)), 8443,
		'only 8443 open: inspect 8443, not the closed 443');
	is($scanner->_tls_port('http://h/', $scan->(443, 8443)), 443, '443 preferred when both are open');
	is($scanner->_tls_port('http://h/', $scan->(80)), undef, 'no TLS port, no inspection');
	is($scanner->_tls_port('https://h:9443/', $scan->()), 9443, 'an HTTPS base is inspected on its own port');
};

subtest 'redirect classification' => sub {
	my $redirect = sub {
		my ($status, $location) = @_;
		return App::WebPerimeterScan::_redirects_to_https({ status => $status, headers => { location => [ $location ] } });
	};
	ok($redirect->(307, 'https://h/'), '307 to HTTPS is a redirect (it used to be reported as none)');
	ok($redirect->(308, 'https://h/'), '308 too');
	ok(!$redirect->(200, 'https://h/'), 'a 200 is not');
	ok(!$redirect->(301, 'http://h/'), 'a redirect to HTTP is not');
};

subtest 'link extraction' => sub {
	my $scanner = App::WebPerimeterScan->new;
	my $links = $scanner->_links(
		'<a href="/a#frag">a</a><a href="/a">again</a><img src="/logo.png"><a href="mailto:x@y">m</a><a href="https://other.example/">o</a>',
		'http://h/',
	);
	is_deeply($links, [ 'http://h/a', 'https://other.example/' ], 'fragments dropped, assets and mailto skipped, duplicates removed');
	is_deeply($scanner->_links(undef, 'http://h/'), [], 'no body, no links');
};

subtest 'constructor validation' => sub {
	ok(!eval { App::WebPerimeterScan->new(bogus => 1); 1 }, 'an unknown argument is refused');
	ok(!eval { App::WebPerimeterScan->new(max_urls => 0); 1 }, 'max_urls must be at least 1');
	ok(!eval { App::WebPerimeterScan->new(ports => ['http']); 1 }, 'ports must be numbers');
	ok(!eval { App::WebPerimeterScan->new->run; 1 }, 'run() without a scope is refused');
	like($@, qr/No scope was given/, '... with the catalogued message');
};

# plan skip_all is only valid before the first test, and the subtests above
# have run, so stop here with done_testing instead.
if($^O eq 'MSWin32') {
	note('skipping the loopback server tests: the test server needs fork');
	done_testing();
	exit 0;
}
require TestServer;

my $page = <<'HTML';
<html><head><title>Home</title><meta name="generator" content="TestCMS 1.0"></head>
<body>
<a href="/about">About</a>
<a href="/logo.png">Logo</a>
<a href="http://evil.example/">Elsewhere</a>
<a href="http://localhost/">Same machine, different name</a>
</body></html>
HTML

my $server = TestServer->start(
	'/' => sub {
		my ($request) = @_;
		# Reflect the query raw, as a vulnerable page would.
		(my $query = $request->{query}) =~ s/%([0-9A-F]{2})/chr hex $1/ge;
		return [ 200, [ 'Content-Type: text/html', 'Set-Cookie: session=abc; Path=/', 'Server: Apache/2.4.1' ], $page . $query ];
	},
	'/about'       => [ 200, [ 'Content-Type: text/html' ], '<html><title>About</title></html>' ],
	'/.git/config' => [ 200, [], "[core]\n\trepositoryformatversion = 0\n" ],
	'/robots.txt'  => [ 200, [], "User-agent: *\nDisallow: /admin\n" ],
);
unless($server) {
	note('skipping the loopback server tests: cannot start the test server');
	done_testing();
	exit 0;
}

my $port = $server->port;

# A docroot holding the served .git/config and an unserved .env, and a
# source tree with one linked route and one that nothing links to.
my $docroot = tempdir(CLEANUP => 1);
mkdir "$docroot/.git";
for my $file ([ '.git/config', "[core]\n" ], [ '.env', "SECRET=1\n" ]) {
	open my $fh, '>', "$docroot/$file->[0]" or die $!;
	print {$fh} $file->[1];
	close $fh;
}
my $srcdir = tempdir(CLEANUP => 1);
open my $src, '>', "$srcdir/App.pm" or die $!;
print {$src} "\$r->get('/about');\n\$r->get('/hidden/:id');\n";
close $src;

my ($scope_fh, $scope_file) = tempfile(UNLINK => 1);
print {$scope_fh} "127.0.0.1:$port\n";
close $scope_fh;

my $scanner = App::WebPerimeterScan->new(
	scope       => App::WebPerimeterScan::Scope->new(allow_private => 1)->load_file($scope_file),
	ports       => [ $port ],
	delay       => 0,
	timeout     => 5,
	reflection  => 1,
	docroots    => [ $docroot ],
	source_dirs => [ $srcdir ],
);
my $findings = $scanner->run;
my %by_id = map { $_->{id} => $_ } @{ $findings->all };

my ($host) = @{ $scanner->host_reports };
is($host->{base}, "http://127.0.0.1:$port/", 'the root answered over HTTP');
is_deeply($host->{urls}, [ "http://127.0.0.1:$port/", "http://127.0.0.1:$port/about" ],
	'the crawl followed the in-scope link only: no asset, no other host, no other name');
is_deeply([ map { $_->{port} } @{ $host->{open_ports} } ], [ $port ], 'the port scan found the server');
ok(!$host->{tls}, 'no TLS inspection without a TLS port');
is($host->{response}{status}, 200, 'the main response is recorded');
is(scalar @{ $host->{responses} }, 2, 'the CORS and OPTIONS probes are recorded');

ok(!$by_id{'scan-error'}, 'the scan completed') or diag explain $by_id{'scan-error'};
ok($by_id{'csp-missing'}, 'header rules ran');
ok(!$by_id{'hsts-missing'}, 'no HSTS rule on plain HTTP');
ok($by_id{'cookie-flags'}, 'cookie rule ran');
ok($by_id{'server-version-disclosed'}, 'disclosure rule ran');
ok($by_id{'generator-disclosed'}, 'the generator meta tag was parsed');
ok($by_id{'git-exposed'}, 'the served .git/config was found');
# realpath, so compare the tail: on macOS the temporary directory is behind
# a /var -> /private/var symlink.
like($by_id{'git-exposed'}{file}, qr{\.git/config\z}, '... and resolved to the file on disk')
	or diag explain $by_id{'git-exposed'};
ok(-f $by_id{'git-exposed'}{file}, '... which exists');
ok($by_id{'robots-disclosure'}, 'robots.txt was read');
ok($by_id{'reflected-input'}, 'the reflection probe saw its marker come back');
ok(!$by_id{'catch-all-200'}, 'a 404 for unknown paths is not a catch-all');

my ($on_disk) = grep { $_->{id} eq 'source-file-in-docroot' } @{ $findings->all };
ok($on_disk, 'the unserved .env on disk is reported');
like($on_disk->{title}, qr/\.env/, '... by name');
ok(!(grep { $_->{id} eq 'source-file-in-docroot' && $_->{title} =~ /\.git/ } @{ $findings->all }),
	'the served file is not reported twice');

my $unvisited = $by_id{'source-routes-unvisited'};
ok($unvisited, 'the route nothing links to is reported');
like($unvisited->{title}, qr/\A1 endpoint defined in source was not scanned\z/, 'singular title for one route');
like($unvisited->{evidence}, qr{/hidden/:id}, 'the unvisited route is named');
unlike($unvisited->{evidence}, qr{/about}, 'the crawled route is not');
is($by_id{'csp-missing'}{source}, '', 'a host-level finding has no source line');

cmp_ok($scanner->http->requests, '>', 20, 'the request counter covers probes as well as pages');

# The same scope without --allow-private: refused, and loudly.
my $refused = App::WebPerimeterScan->new(
	scope => App::WebPerimeterScan::Scope->new->load_file($scope_file),
	ports => [ $port ],
	delay => 0,
)->run;
my ($error) = @{ $refused->all };
is($error->{id}, 'scan-error', 'a private target without allow_private is a scan error');
is($error->{severity}, 'high', '... at high severity, so --fail-on high exits 1');
like($error->{evidence}, qr/\ARefusing to scan '127\.0\.0\.1': it resolves into private address space/,
	'... with the reason, and no "at FILE line N"');
unlike($error->{evidence}, qr/ line \d+/, 'the location suffix is removed');

$server->stop;

done_testing();
