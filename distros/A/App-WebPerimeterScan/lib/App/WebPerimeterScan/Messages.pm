package App::WebPerimeterScan::Messages;

use strict;
use warnings;
use autodie qw(:all);

our $VERSION = '0.001.0';

# The message catalogue: language => { key => message }.
#
# A message is a string with {name} or {name:%fmt} placeholders, or a
# selector hash - see App::WebPerimeterScan::I18N for the format.  It is a
# plain package hash, not Readonly, so that a translation can be added at run
# time:  $App::WebPerimeterScan::Messages::CATALOGUE{de} = { ... };
#
# Keys for findings follow one pattern, "<rule id>.<part>":
#   .title     required, one line
#   .detail    required, why it matters
#   .fix       optional, what to do
#   .evidence  optional, a template for the evidence line; rules whose
#              evidence is captured data (a body excerpt, a banner) pass it raw
our %CATALOGUE;

$CATALOGUE{en} = {
	# ------------------------------------------------------------------
	# The i18n layer itself
	# ------------------------------------------------------------------
	'i18n.missing_key' => 'No message is defined for "{key}"',

	# ------------------------------------------------------------------
	# Scope
	# ------------------------------------------------------------------
	'scope.unreadable' => "Cannot read scope file '{file}': {error}",
	'scope.unparsable' => 'Ignoring unparsable scope line: {line}',
	'scope.empty'      => "Scope file '{file}' contains no usable hosts",
	'scope.not_listed' => "Refusing to scan '{host}': not listed in {source}",
	'scope.private'    => "Refusing to scan '{host}': it resolves into private address space (use --allow-private if this is intentional)",
	'scope.no_source'  => '(none)',

	# ------------------------------------------------------------------
	# The scan runner
	# ------------------------------------------------------------------
	'scan.no_scope'       => 'No scope was given; a scan needs one before it can send any traffic',
	'scan.no_hosts'       => 'No concrete hosts in scope (only wildcards?)',
	'scan.progress'       => '[webperimeter] {message}',
	'scan.progress.host'  => 'host {host}',
	'scan.progress.base'  => 'base URL {base}',
	'scan.progress.urls'  => {
		plural => 'count',
		forms  => {
			one   => '{count} URL scanned on {host}',
			other => '{count} URLs scanned on {host}',
		},
	},
	'scan.note.main'      => 'main page',
	'scan.note.plaintext' => 'plaintext hop',
	'scan.note.origin'    => 'Origin: {origin}',

	# ------------------------------------------------------------------
	# Findings collector
	# ------------------------------------------------------------------
	'findings.unknown_severity' => "Unknown severity '{severity}' for finding '{id}'; recorded as info",
	'findings.foreign'          => 'annotate() was given a finding that this collection did not record',

	# ------------------------------------------------------------------
	# Source index
	# ------------------------------------------------------------------
	'source.unreadable' => "Skipping source file '{file}': {error}",

	# ------------------------------------------------------------------
	# HTTP client errors (these end up in report evidence)
	# ------------------------------------------------------------------
	'http.invalid_url'        => 'invalid URL',
	'http.unsupported_scheme' => "unsupported scheme '{scheme}'",
	'http.no_host'            => 'URL has no host',
	'http.connect_failed'     => 'connect failed: {error}',
	'http.write_failed'       => 'request write failed',
	'http.no_headers'         => 'no response headers',
	'http.malformed_status'   => 'malformed status line',

	# ------------------------------------------------------------------
	# Port scan and TLS errors
	# ------------------------------------------------------------------
	'ports.unresolvable'    => "cannot resolve '{host}'",
	'ports.no_tcp'          => 'no tcp protocol',
	'tls.verify_failed'     => 'certificate verification failed',
	'tls.unknown_name'      => 'unknown',
	'tls.unknown_error'     => 'unknown handshake error',

	# ------------------------------------------------------------------
	# Text report
	# ------------------------------------------------------------------
	'report.header'        => 'webperimeter {version}  {generated}',
	'report.scope'         => 'Scope: {scope}',
	'report.requests'      => 'Requests: {requests}',
	'report.tls'           => '  TLS: {protocol}, {cipher}, expires {expiry}',
	'report.tls_expiry'    => {
		plural => 'days',
		forms  => {
			one   => '{not_after} ({days} day)',
			other => '{not_after} ({days} days)',
		},
	},
	'report.unknown'       => 'unknown',
	'report.certificate'   => '  Certificate: {subject} issued by {issuer}',
	'report.tls_failed'    => '  TLS: handshake failed ({error})',
	'report.open_ports'    => '  Open ports: {ports}',
	'report.no_open_ports' => 'none of the tested ports',
	'report.urls_scanned'  => '  URLs scanned: {count}',
	'report.clean'         => "No findings. That is a clean result for the checks this tool performs,\nnot proof that the site is secure - see LIMITATIONS in the documentation.",
	'report.section'       => '{severity} ({count})',
	'report.file'          => '  File: {file}',
	'report.in_source'     => '  In source: {source}',
	'report.evidence'      => '  Evidence: {evidence}',
	'report.fix'           => '  Fix: {fix}',
	'report.see'           => '  See: {reference}',
	'report.summary'       => 'Summary: {summary}',
	'report.summary_item'  => '{count} {severity}',

	# ------------------------------------------------------------------
	# HTML report
	# ------------------------------------------------------------------
	'html.title'          => 'Perimeter scan - {generated}',
	'html.heading'        => 'External perimeter scan',
	'html.scope'          => 'scope: {scope}',
	'html.requests'       => {
		plural => 'requests',
		forms  => {
			one   => '{requests} request',
			other => '{requests} requests',
		},
	},
	'html.hosts'          => 'Hosts',
	'html.findings'       => 'Findings',
	'html.col.host'       => 'Host',
	'html.col.tls'        => 'TLS',
	'html.col.ports'      => 'Open ports',
	'html.col.urls'       => 'URLs scanned',
	'html.col.severity'   => 'Severity',
	'html.col.rule'       => 'Rule',
	'html.col.title'      => 'Title',
	'html.col.url'        => 'URL',
	'html.col.file'       => 'File',
	'html.col.source'     => 'Source',
	'html.col.detail'     => 'Detail',
	'html.col.evidence'   => 'Evidence',
	'html.col.fix'        => 'Fix',
	'html.tls'            => '{protocol} / {cipher}',
	'html.days_left'      => {
		plural => 'days',
		forms  => {
			one   => ' / {days} day left',
			other => ' / {days} days left',
		},
	},
	'html.not_inspected'  => 'not inspected',
	'html.no_findings'    => 'No findings.',

	# ------------------------------------------------------------------
	# Command line
	# ------------------------------------------------------------------
	'cli.error'          => 'webperimeter: {error}',
	'cli.version'        => 'webperimeter {version}',
	'cli.not_directory'  => '--{option} {dir} is not a directory',
	'cli.bad_format'     => '--format must be text, json or html',
	'cli.bad_fail_on'    => '--fail-on must be critical, high, medium, low, info or never',
	'cli.bad_port'       => "--ports: '{port}' is not a port number between 1 and 65535",
	'cli.written'        => 'Report written to {file}',
	'cli.dry_run.header' => 'Would scan, in this order:',
	'cli.dry_run.host'   => '  {where}',
	'cli.dry_run.private' => '  {where} (private address space - requires --allow-private)',
	'cli.dry_run.ports'  => 'Ports: {ports}',
	'cli.dry_run.docroots' => 'Docroots: {dirs}',
	'cli.dry_run.source' => 'Source: {dirs}',
	'cli.unauthorized'   => <<'EOF',
webperimeter: refusing to send traffic without --authorized.

Only scan hosts you own or have written permission to test.  Passing
--authorized confirms that the hosts in the scope file are yours.

Use --dry-run to see what would be scanned without sending anything.
EOF
	'cli.usage'          => <<'EOF',
Usage: webperimeter --scope FILE [options]

  -s, --scope FILE        Hosts you are authorised to test (required)
      --authorized        Confirm the scope hosts are yours (required to scan)
      --dry-run           Show what would be scanned, send nothing
  -f, --format FORMAT     text (default), json or html
  -o, --output FILE       Write the report to FILE instead of stdout
      --ports LIST        Comma separated ports to probe
      --docroot DIR       Docroot to resolve discovered paths against (repeatable)
      --source DIR        Source tree to map endpoints back to code (repeatable)
      --timeout SECONDS   HTTP response timeout (default 10)
      --connect-timeout N TCP connect timeout for port/TLS checks (default 3)
      --delay SECONDS     Minimum gap between requests to one host (default 0.5)
  -d, --depth N           Link-following depth from each root URL (default 1)
      --max-urls N        Page budget per host (default 40)
      --no-path-probes    Skip the well-known sensitive path checks
      --reflection-probe  Send one marker parameter to test output encoding
      --allow-private     Permit loopback and private targets (staging, tests)
      --fail-on LEVEL     Exit 1 at or above this severity (default high)
      --no-color          Disable ANSI colour in text output (or --no-colour)
  -v, --verbose           Progress on stderr
  -h, --help              This message
  -V, --version           Print the version

Scope file: one host per line, # comments allowed.

  example.com
  www.example.com:8443
  https://shop.example.com/
  *.example.com            # the domain and any sub-domain

Exit status: 0 nothing at or above --fail-on, 1 findings at or above it,
2 usage or setup error.
EOF

	# ==================================================================
	# Findings raised by the scan runner
	# ==================================================================
	'scan-error.title'  => 'Scan of {host} did not complete',
	'scan-error.detail' => 'The host could not be scanned, so none of the checks ran against it. A scan that did not run is not a clean result.',
	'scan-error.fix'    => 'Read the evidence, correct the scope file or the options, and run the scan again.',

	'host-unreachable.title'    => 'Host did not answer over HTTP or HTTPS',
	'host-unreachable.detail'   => 'No usable response was received on the default web ports, so the web checks could not run.',
	'host-unreachable.evidence' => 'Tried {tried}',
	'host-unreachable.fix'      => 'Confirm the hostname resolves and the web server is listening.',

	'no-https-redirect.title'    => 'Plain HTTP does not redirect to HTTPS',
	'no-https-redirect.detail'   => 'The first request a visitor makes can be read or rewritten by a network attacker before any HSTS policy is learned.',
	'no-https-redirect.evidence' => {
		select => 'redirect',
		forms  => {
			elsewhere => 'GET {url} returned {status} with Location: {location}',
			other     => 'GET {url} returned {status} with no HTTPS redirect',
		},
	},
	'no-https-redirect.fix'      => 'Redirect all HTTP requests to HTTPS with a 301, and send HSTS on the HTTPS response.',

	'catch-all-200.title'    => 'Application answers 200 for paths that do not exist',
	'catch-all-200.detail'   => 'Path-probe results were compared against this response and only reported when the content actually matched, so there should be no false positives from the catch-all behaviour. It is still worth fixing: it confuses monitoring and search engines.',
	'catch-all-200.evidence' => 'GET {path} returned 200',
	'catch-all-200.fix'      => 'Return 404 for unknown paths.',

	'reflected-input.title'    => 'Query parameter is reflected without HTML encoding',
	'reflected-input.detail'   => 'The marker was returned verbatim, including its angle brackets. That is the precondition for reflected cross-site scripting; it still needs a human to confirm that a browser will execute the result.',
	'reflected-input.evidence' => 'Sent {parameter} and received it back unencoded',
	'reflected-input.fix'      => 'HTML-encode all output, and add a CSP that forbids inline script.',

	'source-file-in-docroot.title'  => 'Sensitive file is inside a document root: {file}',
	'source-file-in-docroot.detail' => 'The file is on disk under a docroot but was not served during this scan. Any change that starts serving dotfiles - a handler, a rewrite, a new vhost - exposes it at once.',
	'source-file-in-docroot.fix'    => 'Move it above the document root, or deny the path at the web server.',

	'source-routes-unvisited.title' => {
		plural => 'count',
		forms  => {
			one   => '{count} endpoint defined in source was not scanned',
			other => '{count} endpoints defined in source were not scanned',
		},
	},
	'source-routes-unvisited.detail' => 'These routes exist in the code but no crawled page linked to them, so none of the checks above saw how they behave. They are exactly the surface a link-following scan never reaches.',
	'source-routes-unvisited.fix'    => 'Name them explicitly, raise --max-urls, or review them by hand.',

	# ==================================================================
	# Response header checks
	# ==================================================================
	'hsts-missing.title'    => 'Strict-Transport-Security header is missing',
	'hsts-missing.detail'   => 'Without HSTS a user who types the bare hostname makes one plaintext request, which is enough for a network attacker to intercept the session.',
	'hsts-missing.evidence' => 'No Strict-Transport-Security header on {url}',
	'hsts-missing.fix'      => 'Send Strict-Transport-Security: max-age=31536000; includeSubDomains on all HTTPS responses.',

	'hsts-short-max-age.title'    => 'HSTS max-age is shorter than six months',
	'hsts-short-max-age.detail'   => 'A short max-age gives an attacker a window to downgrade the connection once the policy expires.',
	'hsts-short-max-age.evidence' => 'Strict-Transport-Security: {value}',
	'hsts-short-max-age.fix'      => 'Raise max-age to at least {minimum}, ideally 31536000.',

	'hsts-no-subdomains.title'    => 'HSTS does not cover sub-domains',
	'hsts-no-subdomains.detail'   => 'Sub-domains remain downgradable, which matters if any of them serves the same cookies.',
	'hsts-no-subdomains.evidence' => 'Strict-Transport-Security: {value}',
	'hsts-no-subdomains.fix'      => 'Add includeSubDomains once every sub-domain is HTTPS-only.',

	'csp-missing.title'    => 'Content-Security-Policy is missing',
	'csp-missing.detail'   => 'CSP is the main defence-in-depth control against cross-site scripting; without it any injected script runs with full page privileges.',
	'csp-missing.evidence' => 'No Content-Security-Policy header on {url}',
	'csp-missing.fix'      => 'Start with a report-only policy, then enforce it once the reports are clean.',

	'csp-wildcard.title'  => 'Content-Security-Policy allows scripts from any origin',
	'csp-wildcard.detail' => 'The script sources include a bare wildcard or a whole scheme (such as https:), so the policy does not restrict where scripts load from.',
	'csp-wildcard.evidence' => '{directive} {sources}',
	'csp-wildcard.fix'    => 'List the specific origins that host scripts.',

	'csp-unsafe.title'    => 'Content-Security-Policy permits unsafe-inline or unsafe-eval for scripts',
	'csp-unsafe.detail'   => 'Inline script and eval are the two gaps most XSS payloads rely on. unsafe-inline is only reported when no nonce or hash makes browsers ignore it.',
	'csp-unsafe.evidence' => '{directive} {sources}',
	'csp-unsafe.fix'      => 'Move inline handlers into files and use a nonce or hash instead of unsafe-inline; remove unsafe-eval.',

	'clickjacking.title'    => 'No clickjacking protection',
	'clickjacking.detail'   => 'The page can be framed by another site, so its buttons can be overlaid and used for clickjacking.',
	'clickjacking.evidence' => 'No X-Frame-Options header and no frame-ancestors directive',
	'clickjacking.fix'      => "Send X-Frame-Options: DENY (or SAMEORIGIN), or CSP frame-ancestors 'self'.",

	'nosniff-missing.title'    => 'X-Content-Type-Options is missing',
	'nosniff-missing.detail'   => 'Without nosniff some browsers will sniff a text/plain upload as HTML, turning an upload into stored XSS.',
	'nosniff-missing.evidence' => {
		select => 'present',
		forms  => {
			yes   => 'X-Content-Type-Options: {value}',
			other => 'Header absent',
		},
	},
	'nosniff-missing.fix'      => 'Send X-Content-Type-Options: nosniff on every response.',

	'referrer-policy-missing.title'    => 'Referrer-Policy is missing',
	'referrer-policy-missing.detail'   => 'Full URLs, including tokens in query strings, leak to third parties through the Referer header.',
	'referrer-policy-missing.evidence' => 'No Referrer-Policy header',
	'referrer-policy-missing.fix'      => 'Send Referrer-Policy: strict-origin-when-cross-origin.',

	'permissions-policy-missing.title'    => 'Permissions-Policy is missing',
	'permissions-policy-missing.detail'   => 'Camera, microphone and geolocation remain available to any embedded or injected frame.',
	'permissions-policy-missing.evidence' => 'No Permissions-Policy header',
	'permissions-policy-missing.fix'      => 'Send Permissions-Policy denying the features the site does not use.',

	'server-version-disclosed.title'    => 'Server version disclosed: {server}',
	'server-version-disclosed.detail'   => 'Publishing an exact version lets an attacker go straight to the matching exploit instead of probing.',
	'server-version-disclosed.evidence' => 'Server: {server}',
	'server-version-disclosed.fix'      => 'Suppress the version token (ServerTokens Prod in Apache, server_tokens off in nginx).',

	'x-powered-by.title'    => 'X-Powered-By discloses the platform: {value}',
	'x-powered-by.detail'   => 'The header advertises the application stack and usually its version.',
	'x-powered-by.evidence' => 'X-Powered-By: {value}',
	'x-powered-by.fix'      => 'Remove X-Powered-By (expose_php = Off, or Header unset X-Powered-By).',

	'generator-disclosed.title'    => 'Generator meta tag discloses: {generator}',
	'generator-disclosed.detail'   => 'The CMS and its version are advertised in the markup.',
	'generator-disclosed.evidence' => '<meta name="generator" content="{generator}">',
	'generator-disclosed.fix'      => 'Remove the generator meta tag.',

	'php2shell.title'    => 'PHP version vulnerable to PHP2Shell ({version})',
	'php2shell.detail'   => {
		select => 'reason',
		forms  => {
			unsupported => 'PHP {version} has no upstream fix for PHP2Shell. CVE-2026-109618 and CVE-2026-109619 are remote code execution flaws that moved from disclosure to active exploitation within hours.',
			other       => 'PHP {version} is below the PHP2Shell fix level {fixed}. CVE-2026-109618 and CVE-2026-109619 are remote code execution flaws that moved from disclosure to active exploitation within hours.',
		},
	},
	'php2shell.evidence' => 'X-Powered-By reports PHP/{version}',
	'php2shell.fix'      => 'Upgrade to the fixed release for this branch ({fixed_list}) and restart the SAPI.',

	'cookie-flags.title'    => "Cookie '{name}' is missing {missing}",
	'cookie-flags.detail'   => 'A cookie without HttpOnly can be read by injected script; without Secure it is sent over plaintext; without SameSite it is attached to cross-site requests.',
	'cookie-flags.evidence' => 'Set-Cookie: {cookie} (seen on {url})',
	'cookie-flags.fix'      => 'Set Secure, HttpOnly and SameSite=Lax (or Strict) on session cookies.',

	# ==================================================================
	# Response body checks
	# ==================================================================
	'directory-listing.title'    => 'Directory listing is enabled',
	'directory-listing.detail'   => 'The server returns an index of the directory, which reveals files that are not linked from anywhere.',
	'directory-listing.evidence' => 'Response title is "{title}"',
	'directory-listing.fix'      => 'Disable auto-indexing (Options -Indexes / autoindex off).',

	'error-disclosure.title'  => 'Verbose error output discloses internals ({markers})',
	'error-disclosure.detail' => "Error pages leak file paths, framework versions and sometimes query fragments, which shortens an attacker's reconnaissance.",
	'error-disclosure.fix'    => 'Log details server-side and return a generic error page with the correct status code.',
	'error-marker.php'        => 'PHP error',
	'error-marker.perl'       => 'Perl error',
	'error-marker.python'     => 'Python traceback',
	'error-marker.java'       => 'Java stack trace',
	'error-marker.sql'        => 'SQL error',
	'error-marker.stack'      => 'stack trace',

	'mixed-content-active.title'  => 'Active mixed content on an HTTPS page',
	'mixed-content-active.detail' => 'Scripts, stylesheets, frames or form targets are loaded over plaintext, so a network attacker can replace them wholesale. Form actions over HTTP also send their contents in the clear.',
	'mixed-content-active.fix'    => 'Move every script, stylesheet, frame and form target to https:// and add upgrade-insecure-requests to the CSP.',

	'mixed-content-passive.title'  => 'Passive mixed content on an HTTPS page',
	'mixed-content-passive.detail' => 'Images, media or icons are fetched over plaintext, so they can be modified in transit and can leak the page URL through the Referer header.',
	'mixed-content-passive.fix'    => 'Reference these resources over https://.',

	# ==================================================================
	# CORS and methods
	# ==================================================================
	'cors-misconfiguration.title'    => 'CORS policy allows untrusted origins',
	'cors-misconfiguration.detail'   => {
		select => 'case',
		forms  => {
			credentials => 'Any origin may read authenticated responses, so a malicious site can act as the logged-in user.',
			reflected   => 'The server echoes back whatever Origin it is given, so any site can read these responses.',
			other       => 'Any origin may read these responses. Harmless for genuinely public data, dangerous for anything user-specific.',
		},
	},
	'cors-misconfiguration.evidence' => {
		select => 'credentials',
		forms  => {
			yes   => 'Access-Control-Allow-Origin: {allowed}; Access-Control-Allow-Credentials: true (request sent Origin: {origin})',
			other => 'Access-Control-Allow-Origin: {allowed} (request sent Origin: {origin})',
		},
	},
	'cors-misconfiguration.fix'      => 'Echo back only origins on an explicit allowlist, never a wildcard, and only with credentials when necessary.',

	'trace-enabled.title'    => 'HTTP TRACE is enabled',
	'trace-enabled.detail'   => 'TRACE echoes the request back, which can be combined with other flaws to read cookies and headers.',
	'trace-enabled.evidence' => 'Allow: {allow}',
	'trace-enabled.fix'      => 'Disable TRACE (TraceEnable off in Apache).',

	'write-methods-enabled.title'    => 'Write methods advertised on a public URL',
	'write-methods-enabled.detail'   => 'PUT, DELETE or PATCH are allowed here. That may be intended for an API, but it is worth confirming the endpoint authenticates and authorises.',
	'write-methods-enabled.evidence' => 'Allow: {allow}',
	'write-methods-enabled.fix'      => 'Restrict methods per route at the web server or application layer.',

	# ==================================================================
	# TLS
	# ==================================================================
	'tls-unavailable.title'  => 'TLS handshake failed',
	'tls-unavailable.detail' => 'The host did not complete a TLS handshake on the scanned port, so either HTTPS is not served there or the TLS configuration is broken.',
	'tls-unavailable.fix'    => 'Confirm the port serves HTTPS and that the certificate chain is complete.',

	'tls-invalid-certificate.title'  => 'TLS certificate does not verify',
	'tls-invalid-certificate.detail' => 'Browsers will show a full-page warning, and users who click through are training themselves to ignore the warning that protects them.',
	'tls-invalid-certificate.fix'    => 'Serve the full chain including intermediates, and issue the certificate for the names actually in use.',

	'tls-self-signed.title'    => 'TLS certificate is self-signed',
	'tls-self-signed.detail'   => 'A self-signed certificate provides no identity guarantee, so it offers no protection against interception.',
	'tls-self-signed.evidence' => 'Subject and issuer are identical: {subject}',
	'tls-self-signed.fix'      => 'Use a certificate from a publicly trusted CA.',

	'tls-expired.title' => {
		plural => 'days',
		forms  => {
			one   => 'TLS certificate expired {days} day ago',
			other => 'TLS certificate expired {days} days ago',
		},
	},
	'tls-expired.detail'   => 'Every visitor sees an interstitial warning, and API clients will reject the connection.',
	'tls-expired.evidence' => 'notAfter: {not_after}',
	'tls-expired.fix'      => 'Renew the certificate and automate renewal.',

	'tls-expiring.title' => {
		plural => 'days',
		forms  => {
			one   => 'TLS certificate expires in {days} day',
			other => 'TLS certificate expires in {days} days',
		},
	},
	'tls-expiring.detail'   => 'Certificate expiry is a self-inflicted outage, and automated clients fail closed.',
	'tls-expiring.evidence' => 'notAfter: {not_after}',
	'tls-expiring.fix'      => 'Renew now and automate renewal with ACME.',

	'tls-legacy-protocol.title'    => 'Deprecated TLS protocol version accepted ({protocols})',
	'tls-legacy-protocol.detail'   => 'TLS 1.0 and 1.1 are deprecated by RFC 8996 and are barred by PCI DSS. They only survive to support clients that should be retired.',
	'tls-legacy-protocol.evidence' => 'Server completed a handshake with {protocols}',
	'tls-legacy-protocol.fix'      => 'Require TLS 1.2 or newer (SSLProtocol -all +TLSv1.2 +TLSv1.3).',

	'tls-weak-cipher.title'    => 'Weak cipher negotiated: {cipher}',
	'tls-weak-cipher.detail'   => 'The negotiated suite is broken or has no authentication, so the connection can be decrypted or impersonated.',
	'tls-weak-cipher.evidence' => 'Cipher: {cipher}; protocol: {protocol}',
	'tls-weak-cipher.fix'      => 'Restrict the cipher list to AEAD suites and disable anonymous and export ciphers.',

	# ==================================================================
	# Ports
	# ==================================================================
	'portscan-failed.title'  => 'Port scan could not run',
	'portscan-failed.detail' => '{error}',

	'port-open.title'    => 'Port {port} accepts connections from outside the host',
	'port-open.detail'   => {
		select => 'port',
		forms  => {
			21    => 'FTP is unencrypted and frequently allows anonymous access',
			22    => 'SSH is reachable; confirm it only allows keys and is patched',
			23    => 'Telnet is unencrypted',
			25    => 'SMTP is reachable from the internet',
			445   => 'SMB should never be exposed to the internet',
			587   => 'Message submission is reachable',
			993   => 'IMAPS is reachable',
			995   => 'POP3S is reachable',
			1433  => 'Microsoft SQL Server should not be internet-facing',
			3000  => 'A development application server appears to be exposed',
			3306  => 'MySQL should not be internet-facing',
			3389  => 'RDP is a common ransomware entry point',
			5432  => 'PostgreSQL should not be internet-facing',
			5900  => 'VNC is unencrypted and often unauthenticated',
			6379  => 'Redis is unauthenticated by default',
			8000  => 'An alternate HTTP port is exposed',
			8080  => 'An alternate HTTP port is exposed',
			8443  => 'An alternate HTTPS port is exposed',
			8888  => 'An alternate HTTP port is exposed',
			9200  => 'Elasticsearch has no authentication by default',
			11211 => 'memcached has no authentication at all',
			27017 => 'MongoDB has historically shipped without authentication',
			other => 'A service is reachable on this port',
		},
	},
	'port-open.evidence' => {
		select => 'has_banner',
		forms  => {
			yes   => 'Banner: {banner}',
			other => 'TCP connect succeeded, no banner',
		},
	},
	'port-open.fix'      => 'Close the port at the firewall unless it must be public; if it must, restrict it by source address and require authentication.',

	'ports-other-open.title'    => 'Other reachable ports: {ports}',
	'ports-other-open.detail'   => 'These are not inherently unsafe, but every open port is attack surface that has to be patched and monitored.',
	'ports-other-open.evidence' => 'Open: {ports}',
	'ports-other-open.fix'      => 'Close anything not actively needed.',

	'outdated-ssh-banner.title'  => 'SSH announces an old version',
	'outdated-ssh-banner.detail' => 'OpenSSH releases before {minimum} include versions with published remote flaws; the banner alone is not proof of a working exploit, but it is a strong hint.',
	'outdated-ssh-banner.fix'    => 'Upgrade OpenSSH and restart sshd.',
	'outdated-ssh-banner.item'   => 'port {port}: {banner}',

	# ==================================================================
	# Well-known paths
	# ==================================================================
	'git-exposed.title'  => 'Exposed Git repository metadata',
	'git-exposed.detail' => 'The .git directory is being served. Source code, commit history and any credentials ever committed can be reconstructed from it.',
	'git-exposed.fix'    => 'Deny requests to /.git/ at the web server, and deploy with the repository outside the document root.',

	'git-head.title'  => 'Exposed Git HEAD',
	'git-head.detail' => 'A Git ref file is readable, which confirms the repository is exposed.',
	'git-head.fix'    => 'Deny requests to /.git/ at the web server.',

	'svn-exposed.title'  => 'Exposed Subversion metadata',
	'svn-exposed.detail' => 'Subversion administrative files are readable.',
	'svn-exposed.fix'    => 'Deny requests to /.svn/ at the web server.',

	'env-exposed.title'  => 'Exposed environment file',
	'env-exposed.detail' => 'A dotenv file is downloadable. These usually hold database passwords, API keys and application secrets.',
	'env-exposed.fix'    => 'Serve only the application entry point: deny dotfiles at the web server and keep configuration above the document root.',

	'htpasswd-exposed.title'  => 'Exposed password file',
	'htpasswd-exposed.detail' => 'An htpasswd file is downloadable, so password hashes can be taken offline and cracked.',
	'htpasswd-exposed.fix'    => 'Store password files outside the document root and deny access to dotfiles.',

	'htaccess-exposed.title'  => 'Exposed .htaccess',
	'htaccess-exposed.detail' => 'Server configuration is readable and reveals internal rewrite targets and module versions.',
	'htaccess-exposed.fix'    => 'Deny access to dotfiles at the web server.',

	'web-config-exposed.title'  => 'Exposed web.config',
	'web-config-exposed.detail' => 'An IIS configuration file is readable and may contain connection strings.',
	'web-config-exposed.fix'    => 'Deny access to web.config.',

	'php-config-backup.title'  => 'Exposed WordPress configuration backup',
	'php-config-backup.detail' => 'A backup copy of wp-config.php is downloadable, exposing database credentials and salts.',
	'php-config-backup.fix'    => 'Remove backup copies from the document root and deny requests for .bak/.old/.orig files.',

	'sql-dump-exposed.title'  => 'Exposed database dump',
	'sql-dump-exposed.detail' => 'A database dump is downloadable, which is usually a complete copy of the application data.',
	'sql-dump-exposed.fix'    => 'Remove dumps from the web root and store backups off the web server.',

	'ds-store-exposed.title'  => 'Exposed .DS_Store',
	'ds-store-exposed.detail' => 'A macOS folder index is readable, which leaks the names of files (sometimes files that are otherwise unreachable) in that directory.',
	'ds-store-exposed.fix'    => 'Deny dotfiles at the web server and stop deploying macOS metadata.',

	'server-status-exposed.title'  => 'Apache server-status is public',
	'server-status-exposed.detail' => 'mod_status is reachable, exposing internal URLs, client addresses and server load.',
	'server-status-exposed.fix'    => 'Restrict /server-status with Require ip on localhost, or disable mod_status.',

	'server-info-exposed.title'  => 'Apache server-info is public',
	'server-info-exposed.detail' => 'mod_info is reachable and publishes the full module configuration.',
	'server-info-exposed.fix'    => 'Restrict /server-info with Require ip on localhost, or disable mod_info.',

	'phpinfo-exposed.title'  => 'phpinfo() is public',
	'phpinfo-exposed.detail' => 'A phpinfo page leaks absolute paths, loaded extensions, environment variables and sometimes credentials.',
	'phpinfo-exposed.fix'    => 'Delete phpinfo scripts from production.',

	'spring-actuator-exposed.title'  => 'Spring Boot actuator environment is public',
	'spring-actuator-exposed.detail' => 'The actuator env endpoint is reachable and commonly exposes datasource credentials and API keys.',
	'spring-actuator-exposed.fix'    => 'Require authentication on /actuator/**, and only expose health and info.',

	'spring-health-exposed.title'  => 'Spring Boot actuator health is public',
	'spring-health-exposed.detail' => 'Health detail is public. This is minor on its own but confirms a Spring Boot management surface.',
	'spring-health-exposed.fix'    => 'Expose only the health endpoint, and set management.endpoint.health.show-details=never.',

	'composer-json-exposed.title'  => 'composer.json is public',
	'composer-json-exposed.detail' => 'Dependency pins are readable, which tells an attacker exactly which versions to try.',
	'composer-json-exposed.fix'    => 'Deny access to composer.json and composer.lock.',

	'package-json-exposed.title'  => 'package.json is public',
	'package-json-exposed.detail' => 'Dependency pins are readable, which tells an attacker exactly which versions to try.',
	'package-json-exposed.fix'    => 'Deny access to package.json and package-lock.json.',

	'crossdomain-xml.title'  => 'Permissive crossdomain.xml',
	'crossdomain-xml.detail' => 'A wildcard Flash cross-domain policy lets any site read responses from this origin (still honoured by some legacy clients).',
	'crossdomain-xml.fix'    => 'Remove crossdomain.xml, or restrict allow-access-from to specific trusted domains.',

	'security-txt-present.title'    => 'security.txt is published',
	'security-txt-present.detail'   => 'Good: this gives a researcher a route to report a finding to you privately.',
	'security-txt-present.evidence' => 'Contact directive found',

	'robots-disclosure.title' => {
		plural => 'count',
		forms  => {
			one   => 'robots.txt names {count} path',
			other => 'robots.txt names {count} paths',
		},
	},
	'robots-disclosure.detail'   => 'robots.txt is public. Anything listed there is a map of what the operator considers sensitive; it must not be the only protection.',
	'robots-disclosure.evidence' => 'Disallow: {paths}',
	'robots-disclosure.fix'      => 'Enforce access control on these paths rather than relying on robots.txt, and consider not listing them at all.',
};

1;

__END__

=encoding utf8

=head1 NAME

App::WebPerimeterScan::Messages - the message catalogue

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

Read one message, without the placeholders filled in:

	use App::WebPerimeterScan::Messages;

	my $en = $App::WebPerimeterScan::Messages::CATALOGUE{en};
	print $en->{'csp-missing.title'}, "\n";

Add a partial German catalogue.  Every key it does not have falls back to
English:

	$App::WebPerimeterScan::Messages::CATALOGUE{de} = {
		'csp-missing.title' => 'Content-Security-Policy fehlt',
		'report.no_findings' => 'Keine Befunde.',
	};

Add a message with a plural form:

	$App::WebPerimeterScan::Messages::CATALOGUE{de}{'source-routes-unvisited.title'} = {
		plural => 'count',
		forms  => {
			one   => '{count} Endpunkt wurde nicht gescannt',
			other => '{count} Endpunkte wurden nicht gescannt',
		},
	};

Translate a saved JSON report afterwards, using the rule ids in it:

	my $i18n   = 'App::WebPerimeterScan::I18N';
	my $report = JSON::PP::decode_json($json_text);
	for my $finding (@{ $report->{findings} }) {
		my $key = "$finding->{id}.title";
		# A title may need values (such as {url}) that the report does not
		# keep, so fall back to the English title already in the report.
		my $title = $i18n->has_message($key) ? $i18n->i18n($key, $finding) : $finding->{title};
		print "$title\n";
	}

=head1 DESCRIPTION

This module holds every piece of text that the distribution shows to a
person: finding titles and advice, error messages, warnings, report labels
and the command-line help.  No other module contains English sentences.

The text is in one hash, C<%App::WebPerimeterScan::Messages::CATALOGUE>.
Its keys are language codes (C<en>), and each value is a hash of
I<message key> to I<message>.  How a message is written (placeholders,
plural and select forms) and how the language is chosen are described in
L<App::WebPerimeterScan::I18N>.

=head2 Message keys

Keys are short, stable names made of words joined by dots, such as
C<scope.empty> or C<report.no_findings>.  The first word is the part of the
program that uses the message.

The text of a finding uses the finding's rule id as the first part:

	<rule id>.title      required; one line
	<rule id>.detail     required; why the problem matters
	<rule id>.fix        optional; what to do about it
	<rule id>.evidence   optional; a template for the evidence line

The rule id is the C<id> field of each finding, so a saved JSON report can
be translated later by looking its ids up here.  The one exception is the
port rule: its ids are C<port-open-22>, C<port-open-3306> and so on, and
all of them share the messages under C<port-open>.

This module has no subroutines.

=head1 COMMON PITFALLS

=over 4

=item * B<Do not replace the English catalogue.>  English is the fallback
for every other language.  A key removed from C<en> makes every language
die when that message is needed.  Add to it, or add a new language.

=item * B<A new language replaces nothing until it is chosen.>  Adding
C<$CATALOGUE{de}> does not change the output for a user whose environment
says C<en_GB>.  See L<App::WebPerimeterScan::I18N/language>.

=item * B<Keep every placeholder.>  A translation that leaves out C<{host}>
loses that value, with no warning.  A translation that adds a placeholder
the code does not pass shows it as C<{name}>.

=item * B<A finding needs both C<.title> and C<.detail>.>  The test
F<t/i18n.t> fails when the code uses a rule id that does not have them.

=item * B<C<%CATALOGUE> is a normal hash.>  Any code can change it at any
time, and the change is seen by every later message.

=back

=head1 ENCODING

=over 4

=item * This file is ASCII, and the English catalogue is ASCII.

=item * A translation may use any UTF-8 text, including emoji.  Write it as
UTF-8 bytes, as F<Messages.pm> does: do not add C<use utf8>.  The reason is
explained in L<App::WebPerimeterScan::I18N/ENCODING>.

=item * A translation added at run time from a decoded source (for example
a JSON file read with C<decode_json>) is made of character strings.
Encode each string to UTF-8 bytes before you add it.

=back

=head1 LIMITATIONS

Only English (C<en>) is provided.

=head1 FORMAL SPECIFICATION

The catalogue is data, not code.  This schema states the rules it must
follow.  F<t/i18n.t> checks the last two for every key the code uses.
The symbols are explained in
L<App::WebPerimeterScan::I18N/FORMAL SPECIFICATION>.  C<MESSAGE ::= ...>
defines a type with three kinds of value; the double angle brackets hold
the data each kind carries.

=head2 CATALOGUE

	┌─ Catalogue ─────────────────────────────────────────
	│ CATALOGUE : LANGUAGE ⇸ (KEY ⇸ MESSAGE)
	│ MESSAGE ::= text⟨⟨STRING⟩⟩
	│           | plural⟨⟨NAME × (FORM ⇸ MESSAGE)⟩⟩
	│           | select⟨⟨NAME × (FORM ⇸ MESSAGE)⟩⟩
	├─────────────────────────────────────────────────────
	│ en ∈ dom CATALOGUE
	│ ∀ k : used_keys • k ∈ dom CATALOGUE(en)
	│ ∀ r : rule_ids • r.title ∈ dom CATALOGUE(en)
	│                ∧ r.detail ∈ dom CATALOGUE(en)
	└─────────────────────────────────────────────────────

=head1 STATE DIAGRAM

The catalogue is filled once, when the module is loaded.  After that it
changes only when some code assigns to it.

	  use App::WebPerimeterScan::Messages
	        |
	        v
	  +----------------+
	  |  ENGLISH ONLY  |  CATALOGUE = { en => { ... } }
	  +----------------+
	        |
	        |  code assigns $CATALOGUE{xx} = { ... }
	        v
	  +----------------+
	  | MORE LANGUAGES |  CATALOGUE = { en => ..., xx => ... }
	  +----------------+
	        |      ^
	        +------+  code adds or changes a key, or another language

	Every i18n() call reads the catalogue as it is at that moment.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
