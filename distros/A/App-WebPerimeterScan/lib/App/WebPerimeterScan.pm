package App::WebPerimeterScan;

use strict;
use warnings;
use autodie qw(:all);

use HTML::SimpleLinkExtor;
use Object::Configure;
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Sub::Private { mode => 'enforce' };
use URI;

use App::WebPerimeterScan::I18N ();
use App::WebPerimeterScan::Checks;
use App::WebPerimeterScan::Findings;
use App::WebPerimeterScan::HTTP;
use App::WebPerimeterScan::Ports;
use App::WebPerimeterScan::Source;
use App::WebPerimeterScan::TLS;
use parent -norequire, 'App::WebPerimeterScan::I18N';

use version; our $VERSION = version->declare('0.001.0');

# Defaults for new().  A plain hash, keyed like the constructor's
# arguments, so Object::Configure or a caller can change them for a run.
our %config = (
	timeout                  => 10,		# seconds per HTTP request
	connect_timeout          => 3,		# seconds for the port and TLS handshakes
	delay                    => 0.5,	# seconds between requests to one host
	depth                    => 1,		# link-following depth from the root
	max_urls                 => 40,		# pages crawled per host
	max_size                 => 2_000_000,	# bytes of each body kept
	path_probes              => 1,		# request the well-known sensitive paths
	reflection               => 0,		# send the reflected-input marker
	max_links_per_page       => 60,		# links taken from one page
	unvisited_evidence_limit => 10,		# routes listed in source-routes-unvisited
	token_length             => 10,		# characters in a random probe token
);

# Crawling is for finding pages that share the site's header policy, not for
# mirroring the site.  These are skipped so a scan does not waste requests on
# assets.
Readonly::Hash my %SKIP_EXTENSION => map { $_ => 1 } qw(
	jpg jpeg png gif svg webp ico bmp tif tiff css js mjs json map
	pdf zip gz tgz bz2 xz rar 7z tar mp3 mp4 m4a avi mov wmv wav
	woff woff2 ttf eot otf exe dmg iso apk jar deb rpm
);

# Only pages of these types are parsed for links.
Readonly::Scalar my $HTML_TYPE => qr{text/html|application/xhtml}i;

# Ports where TLS is expected, in the order they are tried.
Readonly::Array my @TLS_PORTS => (443, 8443);
Readonly::Hash my %TLS_PORT => map { $_ => 1 } @TLS_PORTS;

# Every redirect status that keeps the visitor's request working.  307 was
# missing from the earlier list, so a 307 to HTTPS was reported as no redirect.
Readonly::Hash my %REDIRECT => map { $_ => 1 } (301, 302, 303, 307, 308);
Readonly::Scalar my $HTTP_OK => 200;

Readonly::Scalar my $HTTPS_URL => qr{\Ahttps://}i;
Readonly::Hash my %WEB_SCHEME => (http => 1, https => 1);

# A sensitive file on disk but not served is a hazard waiting for one
# configuration change, so it ranks below the same file being served.
Readonly::Hash my %DOCROOT_SEVERITY => (critical => 'medium', high => 'low');

# The reflected-input marker: a parameter name, and a closing tag that is
# only returned as-is if the page does not encode its output.
Readonly::Scalar my $REFLECTION_PARAMETER => 'wsprobe';
Readonly::Scalar my $REFLECTION_RAW       => '</x>';
Readonly::Scalar my $REFLECTION_ENCODED   => '%3C%2Fx%3E';

# Probe-path token alphabet.
Readonly::Array my @TOKEN_CHARS => ('a' .. 'z', 0 .. 9);

# The runner's own rules: default severity and reference.  Text is in the
# message catalogue under the same ids.
Readonly::Hash my %RULE => (
	'scan-error'              => { severity => 'high' },
	'host-unreachable'        => { severity => 'high' },
	'no-https-redirect'       => { severity => 'medium', reference => 'https://developer.mozilla.org/en-US/docs/Web/HTTP/Redirections' },
	'catch-all-200'           => { severity => 'info' },
	'reflected-input'         => { severity => 'medium', reference => 'https://cwe.mitre.org/data/definitions/79.html' },
	'source-file-in-docroot'  => { severity => 'medium' },
	'source-routes-unvisited' => { severity => 'info' },
);

=head1 NAME

App::WebPerimeterScan - check your own web perimeter the way an outsider sees it

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

From the command line, scan the hosts listed in F<scope.txt>:

	webperimeter --scope scope.txt --authorized

From Perl, scan and print the findings, worst first:

	use App::WebPerimeterScan;
	use App::WebPerimeterScan::Scope;

	my $scope    = App::WebPerimeterScan::Scope->new->load_file('scope.txt');
	my $scanner  = App::WebPerimeterScan->new(scope => $scope);
	my $findings = $scanner->run;

	print "$_->{severity} $_->{title}\n" for @{ $findings->sorted };

Stop a deployment when the scan finds anything high or critical:

	my $serious = App::WebPerimeterScan->new(scope => $scope)->run->at_or_above('high');
	die scalar(@{$serious}) . " serious finding(s)\n" if @{$serious};

A fast scan of only the web ports, without the sensitive-path probes:

	my $quick = App::WebPerimeterScan->new(
		scope       => $scope,
		ports       => [ 80, 443 ],
		max_urls    => 1,
		path_probes => 0,
	);

Scan your own site and point each finding at the file and the code behind
it.  Run this on the machine that serves the site:

	my $full = App::WebPerimeterScan->new(
		scope       => $scope,
		docroots    => [ '/srv/www/example' ],
		source_dirs => [ '/home/me/src/example/lib' ],
	);
	for my $finding (@{ $full->run->sorted }) {
		print "$finding->{title}\n";
		print "  file:   $finding->{file}\n"   if length $finding->{file};
		print "  source: $finding->{source}\n" if length $finding->{source};
	}

Write an HTML report:

	use App::WebPerimeterScan::Report;

	open my $out, '>', 'report.html';
	print $out App::WebPerimeterScan::Report::as_html($scanner->findings,
		version => $App::WebPerimeterScan::VERSION,
		hosts   => $scanner->host_reports,
	);
	close $out;

=head1 DESCRIPTION

This tool looks at your own web servers from the outside, the way a
stranger on the internet sees them.  It does not log in.  It answers these
questions for each host:

=over 4

=item * Which TCP ports can be reached?

=item * Is the TLS certificate valid, and are old protocol versions still
accepted?

=item * Which security headers are missing, and are the session cookies
protected?

=item * Has a sensitive file, such as F<.git/config> or F<.env>, been left
where the web server will send it?

=back

The tool does not attack the site.  It does not inject code, does not guess
passwords, and does not change any data: it sends only C<GET> requests,
plus one C<OPTIONS> request for each host.  So it is safe to run against a
production site.  (C<--reflection-probe> adds one more C<GET> with a
harmless marker in the query string.)

F<README.md> is generated from this POD by F<pod2github>: change the POD and
regenerate, rather than editing the README by hand.

The scope file is the authorisation boundary: a host that does not appear in
it is never contacted, including hosts discovered by following links, and a
host that resolves into private address space is refused unless
C<--allow-private> is given.

Every message the tool prints comes from a catalogue
(L<App::WebPerimeterScan::Messages>), so the text can be translated without
touching the code; see L<App::WebPerimeterScan::I18N>.

=head1 REQUIREMENTS

Perl 5.26.0 or later, with the modules listed in F<Makefile.PL>.  The floor
is set by L<Params::Validate::Strict>, which needs 5.26; the code in this
distribution would run on 5.14.  C<cpan> installs anything that is missing, so these
floors matter mainly on a machine that already has older copies of them:

=over 4

=item * C<Socket> 2.020

The port scan reads C<SO_ERROR> from it to tell a refused connection from an
open one, and the private-address check uses its C<getaddrinfo>.

=item * C<Net::SSLeay> 1.92

The first release with OpenSSL 3 support.  Earlier releases are not
supported: 1.46 does not compile against OpenSSL 3 at all.

=item * C<IO::Socket::SSL> 2.000

=item * C<IO::Select> 1.17 and C<IO::Socket::INET> 1.31

They are stated because the port scan relies on how they behave, not only
on what they provide.

=item * C<Sub::Private> 0.09 and C<Sub::Protected> 0.03

Every internal routine is wrapped so that a call from outside its package
croaks.  Tests run under C<prove> are exempt (C<HARNESS_ACTIVE>).

=item * C<Params::Get> 0.17 and C<Params::Validate::Strict> 0.41

Every public routine validates its arguments against the schema in its
documentation.

=item * C<Data::Validate::IP> 0.31

Classifies resolved addresses against the IANA special-purpose registries.

=back

Both SSL modules need the OpenSSL headers at install time, which the
installer cannot supply for you; install your distribution's C<openssl>
development package first if the build fails.

The remaining prerequisites are C<autodie> with C<IPC::System::Simple>,
C<Getopt::Long> 2.50, C<HTML::Parser> 3.71, C<HTML::SimpleLinkExtor> 1.20,
C<JSON::PP> 4.00, C<Readonly> 2.05, C<Time::HiRes> 1.97 and C<URI> 1.70, plus
C<Test::More> 1.302 for the test suite.

=head1 USAGE

	bin/webperimeter --scope scope.txt --authorized

The scope file lists the hosts you are allowed to test, one per line.  Without
C<--authorized> the tool refuses to send any traffic.  Add C<--docroot DIR> and
C<--source DIR> to resolve findings back to the file on disk and the code that
serves them.

=head1 QUICK TEST

To check the tool works where you installed it, scan example.com.  RFC 2606
reserves the name for documentation and it is always available, so it makes a
stable target.  It is not a licence to scan other people's hosts: the scope
file is still the boundary.

	$ printf 'example.com\n' > scope.txt
	$ bin/webperimeter --scope scope.txt --authorized --ports 80,443 \
	    --max-urls 1 --no-path-probes --no-color

	webperimeter 0.001.0  2026-11-06T01:05:02Z
	Scope: scope.txt
	Requests: 4

	============================================================
	example.com
	------------------------------------------------------------
	  TLS: TLSv1_3, TLS_AES_256_GCM_SHA384, expires Dec 25 22:56:35 2026 GMT (49 days)
	  Certificate: /CN=example.com issued by /C=US/O=SSL Corporation/CN=Cloudflare TLS Issuing ECC CA 3
	  Open ports: 80, 443
	  URLs scanned: 1


	MEDIUM (4)
	----------
	[csp-missing] Content-Security-Policy is missing
	  Evidence: No Content-Security-Policy header on https://example.com/

	[...]

	Summary: 0 critical, 0 high, 4 medium, 2 low, 1 info

C<--max-urls 1> holds the crawl to the front page and C<--no-path-probes>
skips the sensitive path checks, so the run costs four requests.  Leave the
probes on when the target is a deployment of your own.

The findings are the point of the exercise.  example.com is a good smoke test
because it is not hardened: a run reporting missing CSP, HSTS and nosniff
shows the checks are wired up, and a run that reports nothing - or a critical
finding - means the scan is broken, not the site.

=head1 EXAMPLE

A run against a local application, with its source tree supplied so the
report can name the endpoints it never reached.  The output is trimmed in the
middle for length.

	$ echo localhost:3000 > scope.txt
	$ bin/webperimeter --scope scope.txt --authorized --allow-private --ports 3000 \
	    --source ~/src/njh/Database-BI --no-path-probes --max-urls 6 --delay 0.2 --no-color

	webperimeter 0.001.0  2026-11-06T01:05:47Z
	Scope: scope.txt
	Requests: 8

	============================================================
	localhost
	------------------------------------------------------------
	  Open ports: 3000
	  URLs scanned: 6


	LOW (1)
	-------
	[port-open-3000] Port 3000 accepts connections from outside the host
	  Evidence: TCP connect succeeded, no banner


	INFO (1)
	--------
	[source-routes-unvisited] 71 endpoints defined in source were not scanned
	  Evidence: ~/src/njh/Database-BI/lib/Database/BI.pm:2713 GET /login; ~/src/njh/Database-BI/lib/Database/BI.pm:2714 POST /login; ~/src/njh/Database-BI/lib/Database/BI.pm:2715 POST /logout; [...]
	  Fix: Name them explicitly, raise --max-urls, or review them by hand.

	Summary: 0 critical, 0 high, 0 medium, 1 low, 1 info

That application sends C<style-src 'self' 'unsafe-inline'> with a
nonce-based C<script-src>.  Only the script sources are judged, so the
inline-style allowance is not reported as a cross-site scripting gap.

C<--allow-private> is required for a loopback or private target; without it
the host is refused before any traffic is sent, and the refusal is reported
as a high-severity C<scan-error> so the exit status shows that nothing was
scanned.  The exit status is 0 here because C<--fail-on> defaults to
C<high> and nothing reached it.

C<--no-path-probes> skips the well-known sensitive path checks, which ask
whether a deployed document root exposes files such as C</.git/config>.  The
target here is local, so those paths can be inspected directly on disk - with
C<--docroot>, or by reading the tree - and the probes would only add requests.
Against a real deployment, leave them on.

C<source-routes-unvisited> is the reason to pass C<--source>: 71 routes exist in
the code that no crawled page linked to, so none of the checks above saw how
they behave.  That is exactly the surface a link-following scan cannot reach.
Raise C<--max-urls>, or review them by hand.

Findings also carry C<File:> and C<In source:> lines when C<--docroot> or
C<--source> lets the scan resolve them.

=head1 REPORT FORMAT

C<--format json> records the response header block behind each header finding,
so a report can be audited later without repeating the requests.  Abridged to
one header:

	"response": {
	   "headers" : {
	      "content-security-policy" : [ "default-src 'self'; script-src 'self' 'nonce-...' https://cdnjs.cloudflare.com https://unpkg.com; ..." ]
	   },
	   "http_version" : "HTTP/1.1",
	   "method" : "GET",
	   "note" : "main page",
	   "raw" : "HTTP/1.1 200 OK\r\nServer: ...",
	   "reason" : "OK",
	   "status" : 200,
	   "url" : "http://localhost:3000/"
	},
	"responses" : [ ... ]

A header appears once per value, so a second C<Content-Security-Policy> or
C<Set-Cookie> is not lost.  C<raw> is the block exactly as it arrived.
C<responses> holds the same structure for the CORS and C<OPTIONS> probes, which
is where the CORS and method findings come from.

=head1 SUBROUTINES/METHODS

=head2 new

Purpose: configure a scan.

Args: named, all optional except that C<run> needs C<scope>:

	scope            an App::WebPerimeterScan::Scope (or anything with
	                 hosts, covers, allows and assert_target_allowed)
	timeout          seconds per HTTP request (10)
	connect_timeout  seconds for port and TLS handshakes (3)
	delay            seconds between requests to one host (0.5)
	depth            link-following depth from each root URL (1)
	max_urls         pages crawled per host (40)
	max_size         bytes of each response body kept (2000000)
	path_probes      request the well-known sensitive paths (1)
	reflection       send the reflected-input marker (0)
	verbose          progress on STDERR (0)
	ports            array reference of TCP ports (the Ports default list)
	docroots         array reference of document roots on this machine
	source_dirs      array reference of source trees on this machine

Defaults come from C<%App::WebPerimeterScan::config>.

Returns: the new object.

Side Effects: none; no traffic is sent until C<run>.

Usage: C<< my $scanner = App::WebPerimeterScan->new(scope => $scope); >>

=head3 EXAMPLE

	my $scanner = App::WebPerimeterScan->new(
		scope       => $scope,
		ports       => [ 80, 443 ],
		max_urls    => 1,
		path_probes => 0,
		source_dirs => [ "$ENV{HOME}/src/my-app" ],
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		scope           => { type => 'object', can => [qw(hosts covers allows assert_target_allowed)], optional => 1 },
		timeout         => { type => 'number', min => 0, optional => 1 },
		connect_timeout => { type => 'number', min => 0, optional => 1 },
		delay           => { type => 'number', min => 0, optional => 1 },
		depth           => { type => 'integer', min => 0, optional => 1 },
		max_urls        => { type => 'integer', min => 1, optional => 1 },
		max_size        => { type => 'integer', min => 1, optional => 1 },
		path_probes     => { type => 'boolean', optional => 1 },
		reflection      => { type => 'boolean', optional => 1 },
		verbose         => { type => 'boolean', optional => 1 },
		ports           => { type => 'arrayref', element_type => 'integer', optional => 1 },
		docroots        => { type => 'arrayref', optional => 1 },
		source_dirs     => { type => 'arrayref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan' }

=head3 MESSAGES

	Message                                   Meaning / resolution
	----------------------------------------  ------------------------------
	Unknown parameter 'X' (fatal)             A misspelt argument name.
	Parameter 'X' ... must be ... (fatal)     A value of the wrong type or
	                                          out of range, e.g. depth => -1.
	Parameter 'scope' must be an object that  Pass an App::WebPerimeterScan::
	understands the ... method (fatal)        Scope.

=head3 PSEUDOCODE

	validate the arguments
	overlay them on %config
	create the findings collector and the HTTP client
	create the source index if any docroot or source tree was given

=cut

sub new
{
	my $class = shift;

	my $args = validate_strict(
		schema => {
			scope           => { type => 'object', can => [qw(hosts covers allows assert_target_allowed)], optional => 1 },
			timeout         => { type => 'number', min => 0, optional => 1 },
			connect_timeout => { type => 'number', min => 0, optional => 1 },
			delay           => { type => 'number', min => 0, optional => 1 },
			depth           => { type => 'integer', min => 0, optional => 1 },
			max_urls        => { type => 'integer', min => 1, optional => 1 },
			max_size        => { type => 'integer', min => 1, optional => 1 },
			path_probes     => { type => 'boolean', optional => 1 },
			reflection      => { type => 'boolean', optional => 1 },
			verbose         => { type => 'boolean', optional => 1 },
			ports           => { type => 'arrayref', element_type => 'integer', optional => 1 },
			docroots        => { type => 'arrayref', optional => 1 },
			source_dirs     => { type => 'arrayref', optional => 1 },
		},
		input => get_params(undef, \@_) // {},
	);

	$ args = Object::Configure::configure($class, $args);

	# Explicit arguments win; anything not given comes from %config.
	my $self = bless {
		%config,
		(map { $_ => $args->{$_} } grep { defined $args->{$_} } keys %{$args}),
		hosts    => {},
		findings => App::WebPerimeterScan::Findings->new,
	}, $class;

	$self->{ports}       //= [ @App::WebPerimeterScan::Ports::DEFAULT_PORTS ];
	$self->{docroots}    //= [];
	$self->{source_dirs} //= [];

	$self->{http} = App::WebPerimeterScan::HTTP->new(
		map { $_ => $self->{$_} } qw(timeout delay max_size)
	);

	# The source-aware pass only runs when there is something to map to.
	$self->{source} = App::WebPerimeterScan::Source->new(
		docroots    => $self->{docroots},
		source_dirs => $self->{source_dirs},
	) if @{ $self->{docroots} } || @{ $self->{source_dirs} };

	return $self;
}

=head2 findings

Purpose: the findings collector the scan writes to.

Args: none.

Returns: an L<App::WebPerimeterScan::Findings>.

Side Effects: none.

Usage: C<< my $count = $scanner->findings->count; >>

=head3 EXAMPLE

	$scanner->run;
	printf "%d finding(s)\n", $scanner->findings->count;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan::Findings' }

=head3 MESSAGES

None.

=cut

sub findings
{
	my ($self) = @_;

	return $self->{findings};
}

=head2 http

Purpose: the HTTP client, for its request count or to make further
requests under the same throttle.

Args: none.

Returns: an L<App::WebPerimeterScan::HTTP>.

Side Effects: none.

Usage: C<< printf "Requests: %d\n", $scanner->http->requests; >>

=head3 EXAMPLE

	$scanner->run;
	print $scanner->http->requests, " requests sent\n";

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan::HTTP' }

=head3 MESSAGES

None.

=cut

sub http
{
	my ($self) = @_;

	return $self->{http};
}

=head2 host_reports

Purpose: what the scan learned about each host, for the report formats.

Args: none.

Returns: an array reference, sorted by host, of hash references with
C<host>, C<entry> (the scope entry), C<urls> (pages crawled),
C<open_ports>, C<base> (the root URL that answered), C<tls> (the
L<App::WebPerimeterScan::TLS/inspect> result, when TLS was inspected),
C<response> (the main page's header block) and C<responses> (the probes'
header blocks).  See L</REPORT FORMAT>.

Side Effects: none.

Usage: C<< my $hosts = $scanner->host_reports; >>

=head3 EXAMPLE

	for my $host (@{ $scanner->host_reports }) {
		printf "%s: %d page(s)\n", $host->{host}, scalar @{ $host->{urls} };
	}

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref', element_type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub host_reports
{
	my ($self) = @_;

	return [ map { $self->{hosts}{$_} } sort keys %{ $self->{hosts} } ];
}

=head2 run

Purpose: scan every concrete host in the scope.

Args: none.

Returns: the L<App::WebPerimeterScan::Findings> collector.

Side Effects: network traffic to the hosts in scope, and only to them.  A
host that cannot be scanned (refused by the scope, or an unexpected error)
becomes a high-severity C<scan-error> finding rather than stopping the run,
so the other hosts are still scanned and the exit status shows the gap.

Usage: C<< my $findings = $scanner->run; >>

=head3 EXAMPLE

	my $findings = App::WebPerimeterScan->new(scope => $scope)->run;
	exit(@{ $findings->at_or_above('high') } ? 1 : 0);

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan::Findings' }

=head3 MESSAGES

	Message                                     Meaning / resolution
	------------------------------------------  ------------------------------
	No scope was given; a scan needs one        Pass scope => ... to new().
	before it can send any traffic (fatal)
	No concrete hosts in scope (only            The scope file lists only
	wildcards?) (fatal)                         *.domain lines; add a host.

=head3 PSEUDOCODE

	croak without a scope or without concrete hosts
	for each host in scope
		refuse it if it is out of scope or private (and not allowed)
		port scan; fetch the root over HTTPS then HTTP
		inspect TLS where it is served
		send the CORS, OPTIONS and plaintext-redirect probes
		crawl same-scope links breadth-first within depth and budget
		probe the well-known sensitive paths against a not-found baseline
		optionally send the reflection marker
		list source routes the crawl never reached
		on any error, record a scan-error finding and go on
	map findings to files and source lines; report sensitive files on disk

=cut

sub run
{
	my ($self) = @_;

	my $scope = $self->{scope};
	$self->_throw('scan.no_scope') unless $scope;

	my $hosts = $scope->hosts;
	$self->_throw('scan.no_hosts') unless @{$hosts};

	# One host failing must not stop the others; the failure is a finding.
	for my $entry (@{$hosts}) {
		next if eval { $self->_scan_host($entry); 1 };
		$self->_report('scan-error',
			host     => $entry->{host},
			evidence => App::WebPerimeterScan::I18N::clean_error($@),
			vars     => { host => $entry->{host} },
		);
	}

	$self->_source_pass;

	return $self->{findings};
}

# _report
# Purpose:     record one of the runner's own findings, with the rule
#              table's defaults.
# Entry:       $id is a key of %RULE with catalogue text.
# Exit:        what Findings::report returns.
# Side effects: adds a finding.
sub _report :Private
{
	my ($self, $id, %args) = @_;

	return $self->{findings}->report($id, rule => $RULE{$id}, %args);
}

# _record_response
# Purpose:     the parsed headers of a response plus the raw block exactly as
#              it arrived, so a finding can be checked after the fact - by
#              another person, or on a machine that cannot reach the host.
# Entry:       $res is a fetch() result.
# Exit:        a hashref, or undef for a failed request.
# Side effects: none.  Duplicate headers are preserved: a second CSP or
#              Set-Cookie header is part of the evidence.
sub _record_response :Private
{
	my ($self, $url, $method, $res, $note) = @_;

	return undef unless $res && !$res->{error};

	my %record = (
		url          => $url,
		method       => $method || 'GET',
		status       => $res->{status},
		http_version => $res->{http_version},
		reason       => $res->{reason},
		# A copy, so later changes to the response cannot alter the record.
		headers      => { map { $_ => [ @{ $res->{headers}{$_} } ] } keys %{ $res->{headers} || {} } },
		raw          => $res->{raw_headers},
	);
	$record{note} = $note if defined $note && length $note;

	return \%record;
}

# _keep_response
# Purpose:     record a probe's response in the host report.
# Entry:       $report is a host report.
# Exit:        $self.
# Side effects: appends to $report->{responses} for a successful request.
sub _keep_response :Private
{
	my ($self, $report, $url, $method, $res, $note) = @_;

	my $record = $self->_record_response($url, $method, $res, $note);
	push @{ $report->{responses} }, $record if $record;

	return $self;
}

# _say
# Purpose:     progress output in verbose mode.
# Entry:       $key is a catalogue key; $args its placeholders.
# Exit:        $self.
# Side effects: prints one line to STDERR when verbose.
sub _say :Private
{
	my ($self, $key, $args) = @_;

	print STDERR $self->i18n('scan.progress', { message => $self->i18n($key, $args) }), "\n"
		if $self->{verbose};

	return $self;
}

# _scan_host
# Purpose:     every check against one scope entry.
# Entry:       $entry is a concrete scope entry.
# Exit:        $self.
# Side effects: network traffic; adds findings; records the host report.
#              Croaks if the scope refuses the host.
sub _scan_host :Private
{
	my ($self, $entry) = @_;

	my $host = $entry->{host};
	$self->{scope}->assert_target_allowed($host);
	$self->_say('scan.progress.host', { host => $host });

	my $report = { host => $host, urls => [], responses => [], entry => $entry };
	$self->{hosts}{$host} = $report;

	my $port_scan = $self->_scan_ports($report);

	my ($base, $root) = @{ $self->_fetch_root($entry) || [] };
	unless($base) {
		$self->_report('host-unreachable', host => $host,
			vars => { tried => join(', ', @{ $self->_root_candidates($entry) }) });
		return $self;
	}

	$report->{base} = $base;
	$self->_say('scan.progress.base', { base => $base });

	# The exact block the header checks were run against, so the report can
	# be audited later without sending the request again.
	$report->{response} = $self->_record_response($base, 'GET', $root, $self->i18n('scan.note.main'));

	$self->_inspect_tls($report, $port_scan);
	$self->_probe_same_origin($report);
	$self->_check_plaintext_hop($report) if $base =~ $HTTPS_URL && !$entry->{port};
	$self->_crawl($report, $root);
	$self->_path_probes($report) if $self->{path_probes};
	$self->_reflection_probe($report) if $self->{reflection};
	$self->_unvisited_routes($report) if $self->{source};

	return $self;
}

# _scan_ports
# Purpose:     the port scan and its findings.
# Entry:       $report is the host report.
# Exit:        the scan result.
# Side effects: TCP connections; adds findings; sets open_ports.
sub _scan_ports :Private
{
	my ($self, $report) = @_;

	my $scan = App::WebPerimeterScan::Ports->scan(
		host    => $report->{host},
		ports   => $self->{ports},
		timeout => $self->{connect_timeout},
	);
	$report->{open_ports} = $scan->{open};
	App::WebPerimeterScan::Checks::check_ports($self->{findings}, host => $report->{host}, scan => $scan);

	return $scan;
}

# _tls_port
# Purpose:     which port to inspect TLS on, if any.
# Entry:       $base is the URL that answered; $scan the port scan.
# Exit:        the base URL's port when it is HTTPS; otherwise the first
#              open TLS port (443, then 8443); otherwise undef.
# Side effects: none.
#
# Inspecting a port that answered the scan, rather than always 443, is the
# fix for a host with only 8443 open being reported as tls-unavailable.  A
# failed handshake on an open TLS port is still inspected: it is a finding.
sub _tls_port :Private
{
	my ($self, $base, $scan) = @_;

	my %open = map { $_->{port} => 1 } @{ $scan->{open} || [] };
	my ($open_tls) = grep { $open{$_} } @TLS_PORTS;

	return $base =~ $HTTPS_URL ? URI->new($base)->port : $open_tls;
}

# _inspect_tls
# Purpose:     TLS inspection and its findings.
# Entry:       $report has a base URL.
# Exit:        $self.
# Side effects: TLS handshakes; adds findings; sets $report->{tls}.
sub _inspect_tls :Private
{
	my ($self, $report, $port_scan) = @_;

	my $port = $self->_tls_port($report->{base}, $port_scan);
	return $self unless $port;

	my $tls = App::WebPerimeterScan::TLS->inspect(
		host => $report->{host}, port => $port, timeout => $self->{connect_timeout},
	);
	$report->{tls} = $tls;
	App::WebPerimeterScan::Checks::check_tls($self->{findings}, host => $report->{host}, tls => $tls);

	return $self;
}

# _probe_same_origin
# Purpose:     the CORS probe (a foreign Origin) and the OPTIONS probe.
# Entry:       $report has a base URL.
# Exit:        $self.
# Side effects: two requests; adds findings; records both responses.
sub _probe_same_origin :Private
{
	my ($self, $report) = @_;

	my ($host, $base) = @{$report}{qw(host base)};
	my $origin = App::WebPerimeterScan::Checks::probe_origin();

	my $cors = $self->{http}->fetch($base, headers => [ "Origin: $origin" ]);
	App::WebPerimeterScan::Checks::check_cors($self->{findings}, host => $host, url => $base, res => $cors);
	$self->_keep_response($report, $base, 'GET', $cors, $self->i18n('scan.note.origin', { origin => $origin }));

	my $options = $self->{http}->fetch($base, method => 'OPTIONS');
	App::WebPerimeterScan::Checks::check_methods($self->{findings}, host => $host, url => $base, res => $options);
	$self->_keep_response($report, $base, 'OPTIONS', $options);

	return $self;
}

# _check_plaintext_hop
# Purpose:     does plain HTTP redirect to HTTPS?  The first request a
#              visitor makes is plaintext, and HSTS cannot protect it.
# Entry:       $report's base is HTTPS on the default port.
# Exit:        $self.
# Side effects: one request; may add no-https-redirect.
sub _check_plaintext_hop :Private
{
	my ($self, $report) = @_;

	my $url = "http://$report->{host}/";
	my $plain = $self->{http}->fetch($url);
	$self->_keep_response($report, $url, 'GET', $plain, $self->i18n('scan.note.plaintext'));

	# Port 80 closed is fine: there is no plaintext hop to protect.
	return $self if $plain->{error} || _redirects_to_https($plain);

	my $location = $self->{http}->header($plain, 'location') // '';
	$self->_report('no-https-redirect', host => $report->{host}, vars => {
		url      => $url,
		status   => $plain->{status} // 0,
		location => $location,
		redirect => length $location ? 'elsewhere' : 'none',
	});

	return $self;
}

# _redirects_to_https
# Purpose:     is this response a redirect to an https:// URL?
# Entry:       $res is a successful fetch() result.
# Exit:        1 or 0.
# Side effects: none.
sub _redirects_to_https :Private
{
	my ($res) = @_;

	my $locations = $res->{headers}{location} || [];
	my $location = @{$locations} ? $locations->[-1] : '';

	return ($REDIRECT{ $res->{status} // 0 } && $location =~ $HTTPS_URL) ? 1 : 0;
}

# _crawl
# Purpose:     check the site's own pages, breadth-first from the root,
#              within depth and page budget.
# Entry:       $root is the response already fetched for the base URL.
# Exit:        $self.
# Side effects: requests; adds findings; fills $report->{urls}.
sub _crawl :Private
{
	my ($self, $report, $root) = @_;

	my $base = $report->{base};
	my @queue = ([ $base, 0 ]);
	my %seen = ($base => 1);
	my %allowed;	# host => 1/0, so each host is resolved once
	my $fetched = 0;

	while(@queue && $fetched < $self->{max_urls}) {
		my ($url, $depth) = @{ shift @queue };

		my $res = $url eq $base ? $root : $self->{http}->fetch($url);
		next if $res->{error};

		$fetched++;
		push @{ $report->{urls} }, $url;
		App::WebPerimeterScan::Checks::check_page($self->{findings}, host => $report->{host}, url => $url, res => $res);

		next if $depth >= $self->{depth} || ($res->{content_type} // '') !~ $HTML_TYPE;

		# allows(), not just covers(): a wildcard entry covers names nobody
		# listed, and one resolving to an internal address must be refused.
		for my $link (@{ $self->_links($res->{body}, $url) }) {
			my $host = URI->new($link)->host;
			next if $seen{$link}++ || !($allowed{$host} //= $self->{scope}->allows($host));
			push @queue, [ $link, $depth + 1 ];
		}
	}

	$self->_say('scan.progress.urls', { count => $fetched, host => $report->{host} });

	return $self;
}

# _path_probes
# Purpose:     the sensitive-path probes, against a not-found baseline.
# Entry:       $report has a base URL.
# Exit:        $self.
# Side effects: requests; adds findings.
sub _path_probes :Private
{
	my ($self, $report) = @_;

	my ($host, $base) = @{$report}{qw(host base)};

	# A path that certainly does not exist.  Its fingerprint tells us whether
	# this application answers 200 for everything, in which case a 200 on
	# /.git/config proves nothing.
	my $path = '/ws-baseline-' . _random_token() . '.html';
	my $miss = $self->{http}->fetch(($base =~ s{/+\z}{}r) . $path);

	$self->_report('catch-all-200', host => $host, vars => { path => $path })
		if !$miss->{error} && ($miss->{status} // 0) == $HTTP_OK;

	App::WebPerimeterScan::Checks::check_paths($self->{findings},
		http     => $self->{http},
		host     => $host,
		base     => $base,
		baseline => App::WebPerimeterScan::Checks::fingerprint($miss),
	);

	return $self;
}

# _reflection_probe
# Purpose:     opt-in: send one harmless marker in a query parameter and see
#              whether it comes back unencoded.  A hint for a human, not a
#              proof of cross-site scripting.
# Entry:       $report has a base URL.
# Exit:        $self.
# Side effects: one request; may add reflected-input.
sub _reflection_probe :Private
{
	my ($self, $report) = @_;

	my $marker = 'wsp' . _random_token();
	my $sent = "$REFLECTION_PARAMETER=$marker$REFLECTION_ENCODED";

	my $uri = URI->new($report->{base});
	$uri->query(join '&', grep { defined && length } $uri->query, $sent);

	my $res = $self->{http}->fetch($uri->as_string);
	my $reflected = !$res->{error} && index($res->{body} // '', $marker . $REFLECTION_RAW) >= 0;

	$self->_report('reflected-input',
		host => $report->{host}, url => $uri->as_string, vars => { parameter => $sent },
	) if $reflected;

	return $self;
}

# _source_pass
# Purpose:     the source-aware pass.  A black-box scan can only say that a
#              URL answered; given a docroot and a source tree it can also
#              say which file is served and which line defines the endpoint.
# Entry:       the scan has finished.
# Exit:        $self.
# Side effects: annotates findings; may add source-file-in-docroot.
sub _source_pass :Private
{
	my ($self) = @_;

	my $source = $self->{source};
	return $self unless $source;

	for my $finding (@{ $self->{findings}->all }) {
		my $path = _url_path($finding->{url}) // next;
		my $file  = $source->file_for($path);
		my $route = $source->route_for($path);

		$self->{findings}->annotate($finding,
			($file  ? (file   => $file->{path}) : ()),
			($route ? (source => "$route->{file}:$route->{line}") : ()),
		);
	}

	return $self->_docroot_files($source);
}

# _docroot_files
# Purpose:     sensitive files present under a docroot but not served.
# Entry:       $source has docroots.
# Exit:        $self.
# Side effects: may add source-file-in-docroot, keyed on the file so
#              several probes cannot repeat it.
sub _docroot_files :Private
{
	my ($self, $source) = @_;

	# Only the serious probes, and only those the wire did not already find.
	my %served = map { $_->{id} => 1 } @{ $self->{findings}->all };
	my @wanted = grep { $DOCROOT_SEVERITY{ $_->{severity} } && !$served{ $_->{id} } }
		@{ App::WebPerimeterScan::Checks::sensitive_probes() };

	for my $hit (@{ $source->sensitive_on_disk(\@wanted) }) {
		$self->_report('source-file-in-docroot',
			key      => $hit->{path},
			severity => $DOCROOT_SEVERITY{ $hit->{probe}{severity} },
			evidence => $hit->{path},
			vars     => { file => $hit->{relative} },
		);
	}

	return $self;
}

# _unvisited_routes
# Purpose:     the routes in the source that the scan never requested: the
#              coverage gap a link-following scan cannot see.
# Entry:       $self->{source} is set; the crawl and probes are done.
# Exit:        $self.
# Side effects: may add source-routes-unvisited.
sub _unvisited_routes :Private
{
	my ($self, $report) = @_;

	my $visited = $self->_visited_paths($report);
	my @unvisited = grep {
		my $re = $_->{re};
		!grep { $_ =~ $re } @{$visited};
	} @{ $self->{source}->routes };
	return $self unless @unvisited;

	# The first few as evidence.  The slice stops at the end of the list: a
	# slice past the end, aliased by map or grep, would extend the array.
	my $limit = $self->{unvisited_evidence_limit};
	my @shown = @unvisited > $limit ? @unvisited[0 .. $limit - 1] : @unvisited;

	$self->_report('source-routes-unvisited',
		host     => $report->{host},
		evidence => join('; ', map { "$_->{file}:$_->{line} $_->{method} $_->{pattern}" } @shown),
		vars     => { count => scalar @unvisited },
	);

	return $self;
}

# _visited_paths
# Purpose:     every URL path the scan is known to have requested.
# Entry:       $report is the host report.
# Exit:        arrayref of distinct paths.
# Side effects: none.
#
# Path probes are not part of the crawl, but a finding that names a URL
# proves that URL was requested, so a route serving it is not a gap.
sub _visited_paths :Private
{
	my ($self, $report) = @_;

	my %visited = map { $_ => 1 } grep { defined }
		map { _url_path($_) } @{ $report->{urls} }, map { $_->{url} } @{ $self->{findings}->all };

	return [ keys %visited ];
}

# _url_path
# Purpose:     the path of a URL.
# Entry:       $url may be undef or empty.
# Exit:        a non-empty path, or undef.
# Side effects: none.
sub _url_path :Private
{
	my ($url) = @_;

	my $uri = (defined $url && length $url) ? eval { URI->new($url) } : undef;
	my $path = ($uri && $uri->can('path')) ? $uri->path : undef;

	return (defined $path && length $path) ? $path : undef;
}

# _root_candidates
# Purpose:     the root URLs to try for a scope entry, in order.
# Entry:       $entry is a concrete scope entry.
# Exit:        arrayref of URLs.
# Side effects: none.
sub _root_candidates :Private
{
	my ($self, $entry) = @_;

	my ($host, $port, $scheme) = @{$entry}{qw(host port scheme)};

	# An explicit port implies its scheme unless one was given; with
	# neither, HTTPS is tried first and HTTP second.
	$scheme //= $TLS_PORT{$port} ? 'https' : 'http' if $port;
	my $authority = $port ? "$host:$port" : $host;

	return [ map { "$_://$authority/" } $scheme ? ($scheme) : qw(https http) ];
}

# _fetch_root
# Purpose:     the first root URL that answers.
# Entry:       $entry is a concrete scope entry.
# Exit:        [base URL, response], or undef if none answered.
# Side effects: requests.
sub _fetch_root :Private
{
	my ($self, $entry) = @_;

	for my $base (@{ $self->_root_candidates($entry) }) {
		my $res = $self->{http}->fetch($base);
		return [ $base, $res ] unless $res->{error};
	}

	return undef;
}

# _links
# Purpose:     the crawlable links on a page.
# Entry:       $body is HTML; $base is the page URL.
# Exit:        arrayref of absolute http(s) URLs without fragments, assets
#              skipped, at most max_links_per_page.
# Side effects: none.
sub _links :Private
{
	my ($self, $body, $base) = @_;

	my $extor = (defined $body && length $body) ? eval { HTML::SimpleLinkExtor->new($base) } : undef;
	return [] unless $extor && eval { $extor->parse($body); 1 };

	my (@links, %seen);
	for my $found ($extor->links) {
		my $uri = eval { URI->new_abs($found, $base) } or next;
		next unless $WEB_SCHEME{ lc($uri->scheme // '') };

		$uri->fragment(undef);
		my ($extension) = ($uri->path // '') =~ /\.([A-Za-z0-9]+)\z/;
		next if defined $extension && $SKIP_EXTENSION{ lc $extension };

		my $string = $uri->as_string;
		next if $seen{$string}++;
		push @links, $string;
		last if @links >= $self->{max_links_per_page};
	}

	return \@links;
}

# _random_token
# Purpose:     a short random string for probe paths and markers.
# Entry:       none.
# Exit:        token_length characters of [a-z0-9].
# Side effects: consumes rand().  Not cryptographic: it only has to be
#              unlikely to exist on the server.
sub _random_token :Private
{
	return join '', map { $TOKEN_CHARS[ int rand @TOKEN_CHARS ] } 1 .. $config{token_length};
}

=head1 RULES

These rules come from the scan itself.  The page, TLS, port and path rules
are listed in L<App::WebPerimeterScan::Checks/RULES>.

	Rule id                   Severity  Reported when
	------------------------  --------  ---------------------------------------
	scan-error                high      a host was refused (not listed, or
	                                    private without allow_private), or its
	                                    scan failed part way
	host-unreachable          high      neither https:// nor http:// answered
	                                    at the root of the host
	no-https-redirect         medium    the site is served over HTTPS, but
	                                    http:// does not answer with a 301,
	                                    302, 303, 307 or 308 to https://
	                                    (checked only when the scope line names
	                                    no port; port 80 closed is fine)
	catch-all-200             info      with path probes on: a random path
	                                    that cannot exist
	                                    answers 200, so the server answers
	                                    every path alike
	reflected-input           medium    with reflection on: the marker sent
	                                    in the query came back unescaped
	source-file-in-docroot    medium    with docroots: a file that a critical
	                                    path probe looks for is on disk
	                          low       ... a file that a high path probe
	                                    looks for is on disk
	                                    (files for medium and low probes are
	                                    not looked for on disk)
	source-routes-unvisited   info      with source_dirs: routes in the code
	                                    that the crawl never reached

=head1 COMMON PITFALLS

=over 4

=item * B<Use a new object for each scan.>  C<run> adds to the same
findings collection every time it is called, and C<host_reports> keeps the
last details for each host.  A second C<run> on the same object gives the
findings of both runs together.

=item * B<A scope with only wildcard lines has nothing to scan.>
C<*.example.com> lets the crawler follow links to those hosts, but is not
a starting point.  C<run> dies with "No concrete hosts in scope" when the
scope lists no concrete host.

=item * B<C<run> dies only for a missing scope or an empty one.>  A host
that is refused (not listed, or private), cannot be reached or fails
during the scan does not stop the scan.  It is recorded as a C<scan-error>
or C<host-unreachable> finding, at high severity, and the next host is
scanned.  Look for those findings before you trust a clean result.

=item * B<C<undef> means "use the default".>  C<< depth => undef >> is the
same as leaving C<depth> out.  To turn something off, pass 0, for example
C<< path_probes => 0 >>.

=item * B<C<delay> protects the site.>  The default waits half a second
between two requests to the same host.  Do not set it to 0 for a real
site.

=item * B<C<docroots> and C<source_dirs> are paths on this machine.>  They
help only when this machine holds the files of the site being scanned.
A path that does not exist is ignored without a warning.

=item * B<Private addresses are refused by default.>  To scan a test server
on C<127.0.0.1> or on your local network, create the scope with
C<< App::WebPerimeterScan::Scope->new(allow_private => 1) >>, or pass
C<--allow-private> to F<webperimeter>.

=item * B<No findings is not proof of safety.>  The tool checks a fixed
list of things.  See L</LIMITATIONS>.

=item * B<Progress messages go to STDERR.>  With C<< verbose => 1 >>, the
progress lines are printed to STDERR, so they never mix with a report on
STDOUT.

=back

=head1 ENCODING

The scanner works with bytes from start to end, and never decodes or
encodes text itself.  In practice:

=over 4

=item * B<Web pages in any language are fine.>  Page text, titles and
header values are kept as the bytes the server sent.  A UTF-8 page,
including one with emoji, appears correctly in all three report formats.

=item * B<Links with non-ASCII characters are followed correctly.>  A link
written as raw UTF-8 and the same link written with C<%> escapes are the
same URL to the crawler.

=item * B<International host names work in the scope file.>  Save the file
as UTF-8 and write the names as they are; they are scanned under their
ASCII (Punycode) form, which is also the form shown in the reports.  See
L<App::WebPerimeterScan::Scope/ENCODING>.

=item * B<File and directory names are bytes.>  C<docroots>,
C<source_dirs> and the paths in the findings are used exactly as the
operating system gives them.

=item * B<Messages come from the catalogue.>  They are English and ASCII
today.  Error messages may contain the operating system's own text, in
the language of your locale.

=item * B<If you add your own findings or metadata, add bytes.>  Mixing
Perl character strings with the scanner's byte strings encodes the bytes a
second time.  See L<App::WebPerimeterScan::Findings/ENCODING>.

=back

=head1 LIMITATIONS

These are the design weaknesses a reviewer should know about before relying
on a clean report.  Each is a reason the tool can miss something, or report
something that is not there.

=over 4

=item * B<A clean report is not a clean site.>  The checks are passive and
unauthenticated: no form is submitted, no login is attempted and no
parameter other than the opt-in reflection marker is altered.  Anything
behind a login, or reachable only by a POST, is outside what this tool can
see.

=item * B<DNS can change between the check and the request.>  The scope is
checked against the name, and each connection resolves the name again, so a
name that resolves to a public address for the check and a private one for
the request (DNS rebinding) defeats C<--allow-private>.  The complete fix is
to resolve once and connect to that address, carrying the name in SNI and
the C<Host> header; the HTTP, TLS and port layers would all need to take an
address.

=item * B<IPv4 only for the port scan.>  The private-address check
considers IPv6 addresses, but the port scan connects over IPv4 only.

=item * B<The crawl follows links, not the application.>  Script-built
navigation, forms and API calls are not followed.  C<--source> mitigates
this by listing the routes the crawl never reached, but only for
Mojolicious-style route declarations.

=item * B<Header rules are host-wide.>  A missing header is reported once
per host, with the first page that lacked it as evidence.  A site whose
pages differ in policy shows only the first gap.

=item * B<Multiple CSP headers are read as one policy.>  Browsers apply each
policy separately, so a strict second policy can make a lax first one safe;
the lax one is still reported.

=item * B<Version rules trust banners.>  PHP2Shell and the OpenSSH check use
the version the server announces.  Back-ported fixes (as distributions
ship) are reported as vulnerable; a hidden or faked banner is not reported
at all.

=item * B<Path probes are a fixed list.>  Eighteen well-known files are
requested; a secret under any other name is only found by C<--docroot>.

=item * B<The docroot check is not tied to a host.>  A document root is a
directory on this machine, and nothing says which host in the scope serves
it.  So a sensitive file that any host already served over the network is
not reported again from the disk, even when the scope holds several sites
and the docroot belongs to a different one.  Scan one site at a time when
you give C<--docroot>.

=item * B<Only English is catalogued.>  The message layer is ready for
other languages (see L<App::WebPerimeterScan::I18N>), but none ships.

=item * B<Perl 5.26 is required> because L<Params::Validate::Strict> needs it.
The code in this distribution would run on 5.14.

=back

=encoding utf8

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


=head2 new

	┌─ InitScanner ───────────────────────────────────────
	│ Scanner'; args? : NAME ⇸ VALUE
	├─────────────────────────────────────────────────────
	│ dom args? ⊆ dom config
	│ ∀ k ∈ dom config • setting'(k) = (config ⊕ args?)(k)
	│ findings' = ∅ ∧ hosts' = ∅
	│ source' ≠ ⊥ ⇔ docroots? ≠ ⟨⟩ ∨ source_dirs? ≠ ⟨⟩
	└─────────────────────────────────────────────────────

=head2 findings

	┌─ FindingsOf ────────────────────────────────────────
	│ ΞScanner; result! : FINDINGS
	├─────────────────────────────────────────────────────
	│ result! = findings
	└─────────────────────────────────────────────────────

=head2 http

	┌─ HttpOf ────────────────────────────────────────────
	│ ΞScanner; result! : HTTP
	├─────────────────────────────────────────────────────
	│ result! = http
	└─────────────────────────────────────────────────────

=head2 host_reports

	┌─ HostReports ───────────────────────────────────────
	│ ΞScanner; result! : seq HOSTREPORT
	├─────────────────────────────────────────────────────
	│ ran result! = ran hosts
	│ ∀ i : 1 .. #result! − 1 • result!(i).host < result!(i + 1).host
	└─────────────────────────────────────────────────────

=head2 run

	┌─ Run ───────────────────────────────────────────────
	│ ΔScanner; result! : FINDINGS
	├─────────────────────────────────────────────────────
	│ scope ≠ ⊥ ∧ hosts(scope) ≠ ⟨⟩
	│ contacted' ⊆ { h | allows(scope, h) }
	│ ∀ e ∈ ran hosts(scope) •
	│     scanned(e) ∨ (scan-error, e.host) ∈ keys(findings')
	│ result! = findings'
	└─────────────────────────────────────────────────────

=head1 STATE DIAGRAM

A scanner object is created READY.  C<run> takes it through the steps
below for each host, then to DONE.  C<findings>, C<http> and
C<host_reports> can be called in any state and change nothing.

The object:

	  new(scope, options)
	        |  unknown option or bad value -> croak (no object)
	        v
	  +-------------+
	  |    READY    |  findings empty; no traffic sent
	  +-------------+
	        |
	        |  run()
	        |    no scope            -> croak "No scope was given"
	        |    no concrete host    -> croak "No concrete hosts in scope"
	        v
	  +-------------+
	  |  SCANNING   |  each host in scope->hosts, in turn (below)
	  +-------------+
	        |
	        |  every host done
	        v
	  +-------------+
	  | SOURCE PASS |  only with docroots or source_dirs: add file and
	  +-------------+  source to findings; report sensitive files on disk
	        |
	        v
	  +-------------+
	  |    DONE     |  run() returns the findings collection
	  +-------------+
	        |
	        |  run() again: SCANNING again; new findings are added to
	        |  the same collection (see COMMON PITFALLS)
	        v
	      (SCANNING)

One host, inside SCANNING.  Any croak inside these steps is caught, and
becomes a C<scan-error> finding for that host:

	  +-------------------+
	  | AUTHORISE         |--- not listed, or private and not allowed
	  +-------------------+       -> scan-error (high); next host
	        |
	        v
	  +-------------------+
	  | PORT SCAN         |  open ports and banners -> port findings
	  +-------------------+
	        |
	        v
	  +-------------------+
	  | FETCH ROOT        |--- neither https:// nor http:// answered
	  +-------------------+       -> host-unreachable (high); next host
	        |
	        |  the first that answered becomes the base URL
	        v
	  +-------------------+
	  | INSPECT TLS       |  on the HTTPS port, if one is open
	  +-------------------+
	        |
	        v
	  +-------------------+
	  | SAME-ORIGIN       |  CORS probe and OPTIONS probe
	  | PROBES            |
	  +-------------------+
	        |
	        v
	  +-------------------+
	  | PLAIN HTTP HOP    |  HTTPS base and no port in scope only: does
	  +-------------------+  http:// redirect to https://?
	        |
	        v
	  +-------------------+
	  | CRAWL             |  breadth first, up to 'depth' links deep and
	  +-------------------+  'max_urls' pages; only links that
	        |                scope->allows; page rules on each page
	        v
	  +-------------------+
	  | PATH PROBES       |  if path_probes: the sensitive paths,
	  +-------------------+  compared with a not-found baseline
	        |
	        v
	  +-------------------+
	  | REFLECTION PROBE  |  if reflection: one GET with a marker
	  +-------------------+
	        |
	        v
	  +-------------------+
	  | UNVISITED ROUTES  |  if source_dirs: routes the crawl never
	  +-------------------+  reached
	        |
	        v
	    next host

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
