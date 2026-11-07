## Name

App::WebPerimeterScan - check your own web perimeter the way an outsider sees it

## Version

Version 0.001.0

## Synopsis

From the command line, scan the hosts listed in `scope.txt`:

```
    webperimeter --scope scope.txt --authorized
```

From Perl, scan and print the findings, worst first:

```perl
    use App::WebPerimeterScan;
    use App::WebPerimeterScan::Scope;

    my $scope    = App::WebPerimeterScan::Scope->new->load_file('scope.txt');
    my $scanner  = App::WebPerimeterScan->new(scope => $scope);
    my $findings = $scanner->run;

    print "$_->{severity} $_->{title}\n" for @{ $findings->sorted };
```

Stop a deployment when the scan finds anything high or critical:

```perl
    my $serious = App::WebPerimeterScan->new(scope => $scope)->run->at_or_above('high');
    die scalar(@{$serious}) . " serious finding(s)\n" if @{$serious};
```

A fast scan of only the web ports, without the sensitive-path probes:

```perl
    my $quick = App::WebPerimeterScan->new(
            scope       => $scope,
            ports       => [ 80, 443 ],
            max_urls    => 1,
            path_probes => 0,
    );
```

Scan your own site and point each finding at the file and the code behind
it.  Run this on the machine that serves the site:

```perl
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
```

Write an HTML report:

```perl
    use App::WebPerimeterScan::Report;

    open my $out, '>', 'report.html';
    print $out App::WebPerimeterScan::Report::as_html($scanner->findings,
            version => $App::WebPerimeterScan::VERSION,
            hosts   => $scanner->host_reports,
    );
    close $out;
```

## Description

This tool looks at your own web servers from the outside, the way a
stranger on the internet sees them.  It does not log in.  It answers these
questions for each host:

- Which TCP ports can be reached?
- Is the TLS certificate valid, and are old protocol versions still
accepted?
- Which security headers are missing, and are the session cookies
protected?
- Has a sensitive file, such as `.git/config` or `.env`, been left
where the web server will send it?

The tool does not attack the site.  It does not inject code, does not guess
passwords, and does not change any data: it sends only `GET` requests,
plus one `OPTIONS` request for each host.  So it is safe to run against a
production site.  (`--reflection-probe` adds one more `GET` with a
harmless marker in the query string.)

`README.md` is generated from this POD by `pod2github`: change the POD and
regenerate, rather than editing the README by hand.

The scope file is the authorisation boundary: a host that does not appear in
it is never contacted, including hosts discovered by following links, and a
host that resolves into private address space is refused unless
`--allow-private` is given.

Every message the tool prints comes from a catalogue
([App::WebPerimeterScan::Messages](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AMessages)), so the text can be translated without
touching the code; see [App::WebPerimeterScan::I18N](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AI18N).

## Requirements

Perl 5.26.0 or later, with the modules listed in `Makefile.PL`.  The floor
is set by [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict), which needs 5.26; the code in this
distribution would run on 5.14.  `cpan` installs anything that is missing, so these
floors matter mainly on a machine that already has older copies of them:

- `Socket` 2.020

    The port scan reads `SO_ERROR` from it to tell a refused connection from an
    open one, and the private-address check uses its `getaddrinfo`.

- `Net::SSLeay` 1.92

    The first release with OpenSSL 3 support.  Earlier releases are not
    supported: 1.46 does not compile against OpenSSL 3 at all.

- `IO::Socket::SSL` 2.000
- `IO::Select` 1.17 and `IO::Socket::INET` 1.31

    They are stated because the port scan relies on how they behave, not only
    on what they provide.

- `Sub::Private` 0.09 and `Sub::Protected` 0.03

    Every internal routine is wrapped so that a call from outside its package
    croaks.  Tests run under `prove` are exempt (`HARNESS_ACTIVE`).

- `Params::Get` 0.17 and `Params::Validate::Strict` 0.41

    Every public routine validates its arguments against the schema in its
    documentation.

- `Data::Validate::IP` 0.31

    Classifies resolved addresses against the IANA special-purpose registries.

Both SSL modules need the OpenSSL headers at install time, which the
installer cannot supply for you; install your distribution's `openssl`
development package first if the build fails.

The remaining prerequisites are `autodie` with `IPC::System::Simple`,
`Getopt::Long` 2.50, `HTML::Parser` 3.71, `HTML::SimpleLinkExtor` 1.20,
`JSON::PP` 4.00, `Readonly` 2.05, `Time::HiRes` 1.97 and `URI` 1.70, plus
`Test::More` 1.302 for the test suite.

## Usage

```
    bin/webperimeter --scope scope.txt --authorized
```

The scope file lists the hosts you are allowed to test, one per line.  Without
`--authorized` the tool refuses to send any traffic.  Add `--docroot DIR` and
`--source DIR` to resolve findings back to the file on disk and the code that
serves them.

## Quick Test

To check the tool works where you installed it, scan example.com.  RFC 2606
reserves the name for documentation and it is always available, so it makes a
stable target.  It is not a licence to scan other people's hosts: the scope
file is still the boundary.

```
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
```

`--max-urls 1` holds the crawl to the front page and `--no-path-probes`
skips the sensitive path checks, so the run costs four requests.  Leave the
probes on when the target is a deployment of your own.

The findings are the point of the exercise.  example.com is a good smoke test
because it is not hardened: a run reporting missing CSP, HSTS and nosniff
shows the checks are wired up, and a run that reports nothing - or a critical
finding - means the scan is broken, not the site.

## Example

A run against a local application, with its source tree supplied so the
report can name the endpoints it never reached.  The output is trimmed in the
middle for length.

```
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
```

That application sends `style-src 'self' 'unsafe-inline'` with a
nonce-based `script-src`.  Only the script sources are judged, so the
inline-style allowance is not reported as a cross-site scripting gap.

`--allow-private` is required for a loopback or private target; without it
the host is refused before any traffic is sent, and the refusal is reported
as a high-severity `scan-error` so the exit status shows that nothing was
scanned.  The exit status is 0 here because `--fail-on` defaults to
`high` and nothing reached it.

`--no-path-probes` skips the well-known sensitive path checks, which ask
whether a deployed document root exposes files such as `/.git/config`.  The
target here is local, so those paths can be inspected directly on disk - with
`--docroot`, or by reading the tree - and the probes would only add requests.
Against a real deployment, leave them on.

`source-routes-unvisited` is the reason to pass `--source`: 71 routes exist in
the code that no crawled page linked to, so none of the checks above saw how
they behave.  That is exactly the surface a link-following scan cannot reach.
Raise `--max-urls`, or review them by hand.

Findings also carry `File:` and `In source:` lines when `--docroot` or
`--source` lets the scan resolve them.

## Report Format

`--format json` records the response header block behind each header finding,
so a report can be audited later without repeating the requests.  Abridged to
one header:

```
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
```

A header appears once per value, so a second `Content-Security-Policy` or
`Set-Cookie` is not lost.  `raw` is the block exactly as it arrived.
`responses` holds the same structure for the CORS and `OPTIONS` probes, which
is where the CORS and method findings come from.

## Subroutines/Methods

### New

Purpose: configure a scan.

Args: named, all optional except that `run` needs `scope`:

```
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
```

Defaults come from `%App::WebPerimeterScan::config`.

Returns: the new object.

Side Effects: none; no traffic is sent until `run`.

Usage: `my $scanner = App::WebPerimeterScan->new(scope => $scope);`

#### Example

```perl
    my $scanner = App::WebPerimeterScan->new(
            scope       => $scope,
            ports       => [ 80, 443 ],
            max_urls    => 1,
            path_probes => 0,
            source_dirs => [ "$ENV{HOME}/src/my-app" ],
    );
```

#### Api Specification

##### Input

```perl
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
```

##### Output

```perl
    { type => 'object', isa => 'App::WebPerimeterScan' }
```

#### Messages

```perl
    Message                                   Meaning / resolution
    ----------------------------------------  ------------------------------
    Unknown parameter 'X' (fatal)             A misspelt argument name.
    Parameter 'X' ... must be ... (fatal)     A value of the wrong type or
                                              out of range, e.g. depth => -1.
    Parameter 'scope' must be an object that  Pass an App::WebPerimeterScan::
    understands the ... method (fatal)        Scope.
```

#### Pseudocode

```
    validate the arguments
    overlay them on %config
    create the findings collector and the HTTP client
    create the source index if any docroot or source tree was given
```

### Findings

Purpose: the findings collector the scan writes to.

Args: none.

Returns: an [App::WebPerimeterScan::Findings](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AFindings).

Side Effects: none.

Usage: `my $count = $scanner->findings->count;`

#### Example

```
    $scanner->run;
    printf "%d finding(s)\n", $scanner->findings->count;
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'object', isa => 'App::WebPerimeterScan::Findings' }
```

#### Messages

None.

### Http

Purpose: the HTTP client, for its request count or to make further
requests under the same throttle.

Args: none.

Returns: an [App::WebPerimeterScan::HTTP](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AHTTP).

Side Effects: none.

Usage: `printf "Requests: %d\n", $scanner->http->requests;`

#### Example

```
    $scanner->run;
    print $scanner->http->requests, " requests sent\n";
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'object', isa => 'App::WebPerimeterScan::HTTP' }
```

#### Messages

None.

### Host\_Reports

Purpose: what the scan learned about each host, for the report formats.

Args: none.

Returns: an array reference, sorted by host, of hash references with
`host`, `entry` (the scope entry), `urls` (pages crawled),
`open_ports`, `base` (the root URL that answered), `tls` (the
["inspect" in App::WebPerimeterScan::TLS](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3ATLS#inspect) result, when TLS was inspected),
`response` (the main page's header block) and `responses` (the probes'
header blocks).  See ["REPORT FORMAT"](#report-format).

Side Effects: none.

Usage: `my $hosts = $scanner->host_reports;`

#### Example

```perl
    for my $host (@{ $scanner->host_reports }) {
            printf "%s: %d page(s)\n", $host->{host}, scalar @{ $host->{urls} };
    }
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'arrayref', element_type => 'hashref' }
```

#### Messages

None.

### Run

Purpose: scan every concrete host in the scope.

Args: none.

Returns: the [App::WebPerimeterScan::Findings](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AFindings) collector.

Side Effects: network traffic to the hosts in scope, and only to them.  A
host that cannot be scanned (refused by the scope, or an unexpected error)
becomes a high-severity `scan-error` finding rather than stopping the run,
so the other hosts are still scanned and the exit status shows the gap.

Usage: `my $findings = $scanner->run;`

#### Example

```perl
    my $findings = App::WebPerimeterScan->new(scope => $scope)->run;
    exit(@{ $findings->at_or_above('high') } ? 1 : 0);
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'object', isa => 'App::WebPerimeterScan::Findings' }
```

#### Messages

```perl
    Message                                     Meaning / resolution
    ------------------------------------------  ------------------------------
    No scope was given; a scan needs one        Pass scope => ... to new().
    before it can send any traffic (fatal)
    No concrete hosts in scope (only            The scope file lists only
    wildcards?) (fatal)                         *.domain lines; add a host.
```

#### Pseudocode

```
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
```

## Rules

These rules come from the scan itself.  The page, TLS, port and path rules
are listed in ["RULES" in App::WebPerimeterScan::Checks](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AChecks#RULES).

```
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
```

## Common Pitfalls

- **Use a new object for each scan.**  `run` adds to the same
findings collection every time it is called, and `host_reports` keeps the
last details for each host.  A second `run` on the same object gives the
findings of both runs together.
- **A scope with only wildcard lines has nothing to scan.**
`*.example.com` lets the crawler follow links to those hosts, but is not
a starting point.  `run` dies with "No concrete hosts in scope" when the
scope lists no concrete host.
- **`run` dies only for a missing scope or an empty one.**  A host
that is refused (not listed, or private), cannot be reached or fails
during the scan does not stop the scan.  It is recorded as a `scan-error`
or `host-unreachable` finding, at high severity, and the next host is
scanned.  Look for those findings before you trust a clean result.
- **`undef` means "use the default".**  `depth => undef` is the
same as leaving `depth` out.  To turn something off, pass 0, for example
`path_probes => 0`.
- **`delay` protects the site.**  The default waits half a second
between two requests to the same host.  Do not set it to 0 for a real
site.
- **`docroots` and `source_dirs` are paths on this machine.**  They
help only when this machine holds the files of the site being scanned.
A path that does not exist is ignored without a warning.
- **Private addresses are refused by default.**  To scan a test server
on `127.0.0.1` or on your local network, create the scope with
`App::WebPerimeterScan::Scope->new(allow_private => 1)`, or pass
`--allow-private` to `webperimeter`.
- **No findings is not proof of safety.**  The tool checks a fixed
list of things.  See ["LIMITATIONS"](#limitations).
- **Progress messages go to STDERR.**  With `verbose => 1`, the
progress lines are printed to STDERR, so they never mix with a report on
STDOUT.

## Encoding

The scanner works with bytes from start to end, and never decodes or
encodes text itself.  In practice:

- **Web pages in any language are fine.**  Page text, titles and
header values are kept as the bytes the server sent.  A UTF-8 page,
including one with emoji, appears correctly in all three report formats.
- **Links with non-ASCII characters are followed correctly.**  A link
written as raw UTF-8 and the same link written with `%` escapes are the
same URL to the crawler.
- **International host names work in the scope file.**  Save the file
as UTF-8 and write the names as they are; they are scanned under their
ASCII (Punycode) form, which is also the form shown in the reports.  See
["ENCODING" in App::WebPerimeterScan::Scope](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AScope#ENCODING).
- **File and directory names are bytes.**  `docroots`,
`source_dirs` and the paths in the findings are used exactly as the
operating system gives them.
- **Messages come from the catalogue.**  They are English and ASCII
today.  Error messages may contain the operating system's own text, in
the language of your locale.
- **If you add your own findings or metadata, add bytes.**  Mixing
Perl character strings with the scanner's byte strings encodes the bytes a
second time.  See ["ENCODING" in App::WebPerimeterScan::Findings](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AFindings#ENCODING).

## Limitations

These are the design weaknesses a reviewer should know about before relying
on a clean report.  Each is a reason the tool can miss something, or report
something that is not there.

- **A clean report is not a clean site.**  The checks are passive and
unauthenticated: no form is submitted, no login is attempted and no
parameter other than the opt-in reflection marker is altered.  Anything
behind a login, or reachable only by a POST, is outside what this tool can
see.
- **DNS can change between the check and the request.**  The scope is
checked against the name, and each connection resolves the name again, so a
name that resolves to a public address for the check and a private one for
the request (DNS rebinding) defeats `--allow-private`.  The complete fix is
to resolve once and connect to that address, carrying the name in SNI and
the `Host` header; the HTTP, TLS and port layers would all need to take an
address.
- **IPv4 only for the port scan.**  The private-address check
considers IPv6 addresses, but the port scan connects over IPv4 only.
- **The crawl follows links, not the application.**  Script-built
navigation, forms and API calls are not followed.  `--source` mitigates
this by listing the routes the crawl never reached, but only for
Mojolicious-style route declarations.
- **Header rules are host-wide.**  A missing header is reported once
per host, with the first page that lacked it as evidence.  A site whose
pages differ in policy shows only the first gap.
- **Multiple CSP headers are read as one policy.**  Browsers apply each
policy separately, so a strict second policy can make a lax first one safe;
the lax one is still reported.
- **Version rules trust banners.**  PHP2Shell and the OpenSSH check use
the version the server announces.  Back-ported fixes (as distributions
ship) are reported as vulnerable; a hidden or faked banner is not reported
at all.
- **Path probes are a fixed list.**  Eighteen well-known files are
requested; a secret under any other name is only found by `--docroot`.
- **The docroot check is not tied to a host.**  A document root is a
directory on this machine, and nothing says which host in the scope serves
it.  So a sensitive file that any host already served over the network is
not reported again from the disk, even when the scope holds several sites
and the docroot belongs to a different one.  Scan one site at a time when
you give `--docroot`.
- **Only English is catalogued.**  The message layer is ready for
other languages (see [App::WebPerimeterScan::I18N](https://metacpan.org/pod/App%3A%3AWebPerimeterScan%3A%3AI18N)), but none ships.
- **Perl 5.26 is required** because [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) needs it.
The code in this distribution would run on 5.14.

## Formal Specification

This section states exactly what each method does, in the Z notation.  You
do not need it to use the module: the method descriptions above say the same
thing in words.  It is here for reviewers and for anyone who writes tests.

How to read a schema box:

- The part above the middle line declares names.  A name that ends in
`?` is an input.  A name that ends in `!` is an output.
- The part below the middle line lists facts that are true after the
call.
- A name with a dash after it, such as `items'`, is the value after
the call.  The same name without the dash is the value before the call.
- `Delta X` (written with the Greek capital delta) means the call
may change the state `X`.  `Xi X` (the Greek capital xi) means the call
does not change it.

The symbols used are:

```
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
```

### New

```
    ┌─ InitScanner ───────────────────────────────────────
    │ Scanner'; args? : NAME ⇸ VALUE
    ├─────────────────────────────────────────────────────
    │ dom args? ⊆ dom config
    │ ∀ k ∈ dom config • setting'(k) = (config ⊕ args?)(k)
    │ findings' = ∅ ∧ hosts' = ∅
    │ source' ≠ ⊥ ⇔ docroots? ≠ ⟨⟩ ∨ source_dirs? ≠ ⟨⟩
    └─────────────────────────────────────────────────────
```

### Findings

```
    ┌─ FindingsOf ────────────────────────────────────────
    │ ΞScanner; result! : FINDINGS
    ├─────────────────────────────────────────────────────
    │ result! = findings
    └─────────────────────────────────────────────────────
```

### Http

```
    ┌─ HttpOf ────────────────────────────────────────────
    │ ΞScanner; result! : HTTP
    ├─────────────────────────────────────────────────────
    │ result! = http
    └─────────────────────────────────────────────────────
```

### Host\_Reports

```
    ┌─ HostReports ───────────────────────────────────────
    │ ΞScanner; result! : seq HOSTREPORT
    ├─────────────────────────────────────────────────────
    │ ran result! = ran hosts
    │ ∀ i : 1 .. #result! − 1 • result!(i).host < result!(i + 1).host
    └─────────────────────────────────────────────────────
```

### Run

```
    ┌─ Run ───────────────────────────────────────────────
    │ ΔScanner; result! : FINDINGS
    ├─────────────────────────────────────────────────────
    │ scope ≠ ⊥ ∧ hosts(scope) ≠ ⟨⟩
    │ contacted' ⊆ { h | allows(scope, h) }
    │ ∀ e ∈ ran hosts(scope) •
    │     scanned(e) ∨ (scan-error, e.host) ∈ keys(findings')
    │ result! = findings'
    └─────────────────────────────────────────────────────
```

## State Diagram

A scanner object is created READY.  `run` takes it through the steps
below for each host, then to DONE.  `findings`, `http` and
`host_reports` can be called in any state and change nothing.

The object:

```
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
```

One host, inside SCANNING.  Any croak inside these steps is caught, and
becomes a `scan-error` finding for that host:

```
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
```

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
