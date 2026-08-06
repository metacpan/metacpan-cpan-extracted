# NAME

CGI::ACL - Decide whether to allow a client to run a CGI script

# VERSION

Version 0.09

# SYNOPSIS

CGI::ACL controls who can run your CGI script.  You build a set of rules
and then call `all_denied()` on every request.  If it returns `1`,
send an error response or redirect; if it returns `0`, allow the request.

Rules can be stacked in any order using method chaining.  An unrestricted
object (no rules added) allows everything.

## Block all cloud-hosted visitors

The simplest use case -- no country list or lingua object needed.

    use CGI::ACL;

    my $acl = CGI::ACL->new()->deny_cloud();

    if ($acl->all_denied()) {
        print "Content-Type: text/plain\n\n";
        print "Automated cloud traffic is not permitted.\n";
        exit;
    }

## Allow only specific IP addresses or CIDR ranges

Localhost is NOT automatically allowed once any restriction is set.
Add it explicitly if your script is called from the same machine.

    use CGI::ACL;

    my $acl = CGI::ACL->new()
        ->allow_ip('127.0.0.1')        # local machine
        ->allow_ip('203.0.113.0/24')   # office CIDR block
        ->allow_ip('2001:db8::1');     # single IPv6 address

    if ($acl->all_denied()) {
        print "Content-Type: text/plain\n\n";
        print "Your IP address is not on the allow list.\n";
        exit;
    }

## Block visitors from specific countries

Deny mode: allow everyone except the listed countries.

    use CGI::Lingua;
    use CGI::ACL;

    my $lingua = CGI::Lingua->new(supported => ['en']);

    my $acl = CGI::ACL->new()
        ->deny_country('CN')
        ->deny_country(country => ['RU', 'KP']);

    if ($acl->all_denied(lingua => $lingua)) {
        print "Content-Type: text/plain\n\n";
        print "Access from your country is not permitted.\n";
        exit;
    }

## Allow only specific countries (allowlist)

Default-deny mode: block everyone except the listed countries.
Use `deny_all_countries()` to turn on default-deny, then list
each permitted country with `allow_country()`.

    use CGI::Lingua;
    use CGI::ACL;

    my $lingua = CGI::Lingua->new(supported => ['en', 'de', 'fr']);

    my $acl = CGI::ACL->new()
        ->deny_all_countries()
        ->allow_country('GB')
        ->allow_country('US')
        ->allow_country('DE');

    if ($acl->all_denied(lingua => $lingua)) {
        print "Content-Type: text/plain\n\n";
        print "This service is available in GB, US, and DE only.\n";
        exit;
    }

## Production-grade: IP allowlist + country allowlist + cloud block

Combine all three rule types.  Rules are evaluated in this fixed order:
cloud check, IP check, country check.

    use CGI::Lingua;
    use CGI::ACL;

    my $lingua = CGI::Lingua->new(supported => ['en']);

    my $acl = CGI::ACL->new()
        ->deny_cloud()                  # block AWS, GCP, Azure, etc.
        ->allow_ip('127.0.0.1')         # always allow localhost
        ->allow_ip('198.51.100.0/24')   # corporate network
        ->deny_all_countries()          # default-deny all countries...
        ->allow_country('GB')           # ...except UK
        ->allow_country('US');          # ...and US

    if ($acl->all_denied(lingua => $lingua)) {
        print "Content-Type: text/plain\n\n";
        print "Access denied.\n";
        exit;
    }

## Sharing a base ACL across routes with cloning

Call `new()` on an existing object to get an independent copy.
Changing the copy does not affect the original.

    use CGI::ACL;

    # Shared base: block cloud for all routes
    my $base_acl = CGI::ACL->new()->deny_cloud();

    # Admin route: additionally restrict to a single IP
    my $admin_acl = $base_acl->new()->allow_ip('198.51.100.1');

    if ($admin_acl->all_denied()) {
        print "Content-Type: text/plain\n\n";
        print "Admin access denied.\n";
        exit;
    }

The module optionally integrates with [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua) for country detection.
Runtime configuration is supported via [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

# COMMON PITFALLS

The following mistakes are easy to make.  Read this section before filing
a bug report.

## allow\_country alone has no effect

`allow_country()` only restricts access when default-deny mode is active.
Default-deny mode is activated by `deny_country('*')` or
`deny_all_countries()`.  Without it, `allow_country()` is silently
ignored and everyone is still allowed.

    # WRONG -- this allows everyone; allow_country is ignored
    my $acl = CGI::ACL->new()->allow_country('US');

    # RIGHT -- deny all countries first, then add permitted ones
    my $acl = CGI::ACL->new()->deny_all_countries()->allow_country('US');

## deny\_cloud overrides allow\_ip

Cloud detection has the highest priority.  An IP address that is listed
in `allow_ip()` is still blocked if its reverse DNS resolves to a cloud
provider hostname.  This is intentional: cloud IPs can be reassigned, so
the rDNS check is more reliable than the IP address alone.

    # This STILL blocks the IP if it is a cloud host
    my $acl = CGI::ACL->new()
        ->deny_cloud()
        ->allow_ip('198.51.100.5');   # blocked if rDNS says EC2

## Localhost is not automatically allowed

Once any restriction is set, `127.0.0.1` is subject to the same rules
as any other address.  If you need to allow local access (for example,
a health-check endpoint), add it explicitly.

    my $acl = CGI::ACL->new()
        ->allow_ip('127.0.0.1')   # must be explicit
        ->deny_all_countries()
        ->allow_country('US');

## Forgetting the lingua argument

When country restrictions are active and `all_denied()` is called without
a `lingua` argument, the module emits a `carp` warning and denies the
request.  Always pass a `CGI::Lingua` object when country rules are in use.

    # WRONG -- will carp and deny every request
    my $acl = CGI::ACL->new()->deny_all_countries()->allow_country('US');
    $acl->all_denied();

    # RIGHT
    my $lingua = CGI::Lingua->new(supported => ['en']);
    $acl->all_denied(lingua => $lingua);

## VPN and proxy users bypass IP and country checks

A visitor who connects through a VPN, Tor exit node, or anonymous proxy
will appear to come from the proxy's IP address and country, not their
own.  CGI::ACL has no way to detect this.  Cloud blocking provides some
mitigation for VPS-based proxies.

## Country codes are case-insensitive but stored lowercase

`deny_country('BR')` and `deny_country('br')` are equivalent.  All
country codes are stored in lowercase.  `CGI::Lingua::country()` may
return either case; `all_denied()` normalises it with `lc()` before
comparing.

## The DNS result cache is not shared between CGI requests

In traditional CGI (one process per request), the per-object DNS cache
is destroyed at the end of every request.  The cache is only useful in
persistent-process setups such as FastCGI, mod\_perl, or Plack servers,
where the same `CGI::ACL` object survives across many requests.

# SUBROUTINES/METHODS

## new

Creates and returns a new CGI::ACL object.

When called on an existing object it returns a deep clone of that object,
optionally overriding public fields with the supplied arguments.  The public
data hashes (`allowed_ips`, `deny_countries`, `allow_countries`) are
copied so that mutations to the clone do not affect the original.
Derived/private keys (`_cidrlist`, `_cloud_cache`) are always cleared;
they are rebuilt from the cloned public state on the next `all_denied()`
call.

**Security note:** private `_*` keys are stripped from all constructor
arguments, including those supplied via environment variables or a config
file.  Accepting `_cloud_cache` entries from outside the process would
allow an attacker with environment-variable access to pre-seed the DNS
result cache and bypass `deny_cloud()` for specific IP addresses.

Constructor arguments may also be supplied via environment variables of the
form `CGI__ACL__<field>` or via a config file; see [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)
for details.

### EXAMPLE

    # No restrictions (allow all by default)
    my $acl = CGI::ACL->new();

    # Pre-seeded allow list
    my $acl = CGI::ACL->new(allowed_ips => { '127.0.0.1' => 1 });

    # Clone an existing ACL and add a restriction
    my $acl2 = $acl->new(deny_cloud => 1);

### API SPECIFICATION

#### Input

    # Compatible with Params::Validate::Strict:
    {
        allowed_ips     => { type => 'hashref',  optional => 1 },
        deny_countries  => { type => 'hashref',  optional => 1 },
        allow_countries => { type => 'hashref',  optional => 1 },
        deny_cloud      => { type => 'boolean',  optional => 1 },
    }

#### Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }
    # or undef when called as CGI::ACL::new() instead of CGI::ACL->new()

### MESSAGES

- `CGI::ACL use ->new() not ::new() to instantiate`

    **Severity:** carp (warning).
    **Cause:** `CGI::ACL::new(...)` was called as a plain function instead of
    as a class method.
    **Action:** Change the call to `CGI::ACL->new(...)`.

## allow\_ip

Adds an IPv4/IPv6 address or CIDR block to the set of explicitly permitted
clients.  When `allowed_ips` is non-empty, any client address not matched
by an entry in the set is denied (subject to `deny_cloud` taking precedence).

### EXAMPLE

    use CGI::ACL;

    # Single address
    my $acl = CGI::ACL->new()->allow_ip('203.0.113.5');

    # Named parameter
    my $acl = CGI::ACL->new()->allow_ip(ip => '203.0.113.5');

    # CIDR block
    my $acl = CGI::ACL->new()->allow_ip(ip => '192.0.2.0/24');

    # Method chaining
    my $acl = CGI::ACL->new()
        ->allow_ip('192.0.2.1')
        ->allow_ip('10.0.0.0/8');

### ARGUMENTS

- ip (required)

    A string containing an IPv4 address, an IPv6 address, or a CIDR block
    (e.g. `10.0.0.0/8`).  The format is validated before storage;
    syntactically invalid values are rejected with a carp warning and the
    object is returned unchanged.

### RETURNS

The object itself, to allow method chaining.

### SIDE EFFECTS

On the first call (even if the supplied address is invalid), initialises
`$self->{allowed_ips}` to an empty hashref so that `all_denied()`
treats the ACL as having IP restrictions configured.  This ensures
fail-closed behaviour: an ACL whose only `allow_ip()` calls all supplied
invalid addresses denies all traffic rather than allowing it.

On a successful (valid) call, also invalidates the internal CIDR lookup
cache so the next call to `all_denied()` rebuilds it with the new entry.

### API SPECIFICATION

#### Input

    # Compatible with Params::Validate::Strict:
    {
        ip => { type => 'string', regex => qr/\S+/, required => 1 },
    }

#### Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

### MESSAGES

- `Usage: allow_ip($ip_address)`

    **Severity:** carp (warning).
    **Cause:** Called with no argument, with a non-hash reference, or without
    supplying the `ip` key.
    **Action:** Pass a scalar IP/CIDR string: `allow_ip('192.0.2.1')` or
    `allow_ip(ip => '192.0.2.1')`.

- `allow_ip: 'X' is not a valid IP address or CIDR block`

    **Severity:** carp (warning).
    **Cause:** The supplied string does not parse as a syntactically valid IPv4
    address, IPv6 address, or CIDR block.  The value (truncated to 60 chars in
    the message) was not stored.  `$self-`{allowed\_ips}> is still initialised
    so the ACL remains in fail-closed mode.
    **Action:** Check the supplied string for typos.  Use dotted-quad notation
    for IPv4 (e.g. `192.0.2.1`), colon-hex for IPv6 (e.g. `2001:db8::1`),
    or slash-notation for CIDR (e.g. `10.0.0.0/8`).

## deny\_country

Adds one or more countries to the deny list.  Countries are identified by
their ISO 3166-1 alpha-2 codes (case-insensitive).

Passing the special value `'*'` (wildcard) switches to default-deny mode:
all countries are denied unless they also appear in the allow list set by
`allow_country()`.

### EXAMPLE

    use CGI::ACL;

    # Deny a single country
    my $acl = CGI::ACL->new()->deny_country('BR');

    # Deny a list of countries
    my $acl = CGI::ACL->new()->deny_country(country => ['BR', 'CN', 'RU']);

    # Default-deny all countries (use with allow_country to whitelist)
    my $acl = CGI::ACL->new()->deny_country('*')->allow_country('US');

### ARGUMENTS

- country (required)

    A scalar ISO code, the wildcard `'*'`, or an array reference of ISO codes.

### RETURNS

The object itself, to allow method chaining.

### SIDE EFFECTS

Updates `$self->{deny_countries}`.

### NOTES

`allow_country()` has no effect unless `deny_country('*')` has been called
first.  Calling `allow_country()` alone (without the wildcard deny) does
not restrict access.

### API SPECIFICATION

#### Input

    # Compatible with Params::Validate::Strict:
    {
        country => {
            type     => 'string' | 'arrayref',
            required => 1,
        },
    }

#### Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

### MESSAGES

- `Usage: deny_country($country)`

    **Severity:** carp (warning).
    **Cause:** Called with no argument, with a non-hash/non-array reference, or
    without supplying the `country` key.
    **Action:** Pass a scalar ISO code or arrayref:
    `deny_country('BR')` or `deny_country(country => ['BR','CN'])`.

## allow\_country

Adds one or more countries to the explicit permit list.  This is meaningful
only when `deny_country('*')` has been called first; without the wildcard
deny, this method has no observable effect on access decisions.

### EXAMPLE

    use CGI::ACL;

    # Allow only the UK and US
    my $acl = CGI::ACL->new()
        ->deny_country('*')
        ->allow_country(country => ['GB', 'US']);

    # Single country as positional argument
    my $acl = CGI::ACL->new()->deny_country('*')->allow_country('US');

### ARGUMENTS

- country (required)

    A scalar ISO code or an array reference of ISO codes.

### RETURNS

The object itself, to allow method chaining.

### SIDE EFFECTS

Updates `$self->{allow_countries}`.

### NOTES

Call `deny_country('*')` before this method; otherwise all traffic is
already allowed by the default-allow rule and the permit list is never
consulted.

### API SPECIFICATION

#### Input

    # Compatible with Params::Validate::Strict:
    {
        country => {
            type     => 'string' | 'arrayref',
            required => 1,
        },
    }

#### Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

### MESSAGES

- `Usage: allow_country($country)`

    **Severity:** carp (warning).
    **Cause:** Called with no argument, with a non-hash/non-array reference, or
    without supplying the `country` key.
    **Action:** Pass a scalar ISO code or arrayref:
    `allow_country('US')` or `allow_country(country => ['GB','US'])`.

## deny\_cloud

Enables blocking of requests that originate from major cloud-hosting
providers.  Detection is performed via verified reverse DNS: the client
IP is looked up, the resulting hostname is forward-confirmed to prevent
spoofing, and the confirmed hostname is matched against a list of
provider-specific patterns.

Covered providers (as of this release): AWS EC2, Google Cloud Compute,
Microsoft Azure, DigitalOcean, Linode/Akamai, Hetzner, OVH.

**Important:** `deny_cloud` takes precedence over `allow_ip`.  An IP
that is explicitly permitted via `allow_ip()` is still denied if its
reverse DNS resolves to a cloud provider hostname.

### EXAMPLE

    use CGI::ACL;

    my $acl = CGI::ACL->new()->deny_cloud();

    if ($acl->all_denied()) {
        print "Cloud-hosted clients are not permitted.\n";
        exit;
    }

### ARGUMENTS

None.

### RETURNS

The object itself, to allow method chaining.

### SIDE EFFECTS

Sets `$self->{deny_cloud}` to `1`.

### NOTES

IPv4 and IPv6 clients are both subject to the cloud check.  A client with
no reverse DNS record, or whose forward confirmation fails, is treated as
a non-cloud host and allowed through the cloud check (though it may still
be denied by other rules).

DNS lookups are performed synchronously.  On non-Windows platforms a
`$DNS_TIMEOUT`-second alarm is used to prevent indefinite blocking.

### API SPECIFICATION

#### Input

    # No parameters accepted.
    {}

#### Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

### MESSAGES

This method emits no messages.

## deny\_all\_countries

Convenience method equivalent to `deny_country('*')`.  Switches the ACL
into default-deny mode for country checks: every country is denied unless
it also appears in the permit list added by `allow_country()`.

This is the idiomatic way to build an allowlist-only country policy without
spelling out the wildcard literal.

### EXAMPLE

    use CGI::ACL;

    # Allow only the UK and US; deny every other country
    my $acl = CGI::ACL->new()
        ->deny_all_countries()
        ->allow_country('GB')
        ->allow_country('US');

    if ($acl->all_denied(lingua => $lingua)) {
        print "Your country is not permitted.\n";
        exit;
    }

### ARGUMENTS

None.

### RETURNS

The object itself, to allow method chaining.

### SIDE EFFECTS

Sets `$self->{deny_countries}{'*'}` to `1`, activating default-deny
mode.  `allow_country()` calls made before or after this method both take
effect - evaluation order is irrelevant because all data is applied at
`all_denied()` call time.

### NOTES

`allow_country()` has no restrictive effect unless this method (or
`deny_country('*')`) has also been called.

### API SPECIFICATION

#### Input

    # No parameters accepted.
    {}

#### Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

### MESSAGES

This method emits no messages.

## all\_denied

Evaluates every active restriction against the current client and returns
`1` (deny) or `0` (allow).

The evaluation order is:

1. If **no** restrictions are configured at all, return `0` (allow).
2. Validate `REMOTE_ADDR` as a syntactically correct IPv4 or IPv6 address.
If it is missing or malformed, return `1` (deny).
3. If `deny_cloud` is set, perform a verified reverse-DNS lookup.  If the
hostname matches a cloud provider, return `1` (deny) immediately,
regardless of `allowed_ips`.  If the IP is not a cloud host and no
other restrictions are active, return `0` (allow).
4. If `allowed_ips` is set, check the client address against the exact-match
hash and then the CIDR list.  Return `0` (allow) on a match.
5. If country restrictions are set, resolve the client's country via the
`lingua` argument.  Apply default-deny or default-allow country logic.
If no lingua is provided, emit a warning and return `1` (deny).

Note that localhost (`127.0.0.1`) is **not** automatically allowed once
any restriction is configured; call `allow_ip('127.0.0.1')` explicitly.

### EXAMPLE

    use CGI::Lingua;
    use CGI::ACL;

    my $acl = CGI::ACL->new()->allow_ip('8.35.80.39');

    if ($acl->all_denied()) {
        print "You are not allowed to view this site.\n";
        exit;
    }

    # Country check
    my $acl2 = CGI::ACL->new()
        ->deny_country('*')
        ->allow_country('US');

    if ($acl2->all_denied(lingua => CGI::Lingua->new(supported => ['en']))) {
        print "US-only site.\n";
        exit;
    }

### ARGUMENTS

- lingua (optional)

    A [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua) object (or any object with a `country()` method returning
    an ISO 3166-1 alpha-2 code or `undef`).  Required when country restrictions
    are active; ignored otherwise.

### RETURNS

`1` if access is denied, `0` if access is allowed.

### SIDE EFFECTS

May populate or update `$self->{_cidrlist}` (the memoised CIDR lookup
structure) and `$self->{_cloud_cache}` (the per-object DNS result
cache, keyed by IP address string) as performance optimisations.

### API SPECIFICATION

#### Input

    # Compatible with Params::Validate::Strict:
    {
        lingua => { type => 'object', optional => 1 },
    }

#### Output

    # Compatible with Return::Set:
    { type => 'string', regex => qr/^[01]$/ }

### MESSAGES

- `Usage: all_denied($lingua)`

    **Severity:** carp (warning).
    **Cause:** Country restrictions are active (`deny_country` or
    `allow_country` was called) but no `lingua` argument was supplied.
    **Action:** Pass a `CGI::Lingua` object:
    `all_denied(lingua => $lingua)`.

### PSEUDOCODE

    IF no restrictions configured THEN
        RETURN 0  (allow -- fast path)

    raw := REMOTE_ADDR // '127.0.0.1'
    -- \A and \z anchors (not ^ / $): \z never matches before a trailing \n
    IF raw not matched by /\A IPv4-or-IPv6 \z/ THEN
        RETURN 1  (deny -- bad or injected address)
    -- Detaint: extract addr via character-class capture so the value
    -- is clean under Perl -T taint mode for all downstream callers
    addr := capture [0-9A-Fa-f:.]+ from raw

    IF deny_cloud is set THEN
        consult per-object cache keyed by addr (TTL 300 s)
        IF cache miss THEN
            is_cloud := _is_cloud_host(addr)  [DNS; may throw]
            IF no error THEN cache result END IF
        END IF
        IF is_cloud THEN RETURN 1 (deny -- cloud host)
        IF no meaningful further restrictions THEN RETURN 0 (allow)
        -- "meaningful" = allowed_ips ≠ ∅ OR deny_countries ≠ ∅
        -- allow_countries alone is not meaningful (never changes the decision)
    END IF

    IF allowed_ips is set THEN
        IF addr matches exact-match entry THEN RETURN 0 (allow)
        IF addr falls inside any CIDR range THEN RETURN 0 (allow)
    END IF

    IF deny_countries is set THEN
        -- Premise: allow_countries alone is vacuous (always returns 0 in
        -- non-wildcard mode); if only allow_countries was set, earlier guards
        -- already returned 0.  This condition is therefore necessary and sufficient.
        IF no lingua supplied THEN carp; RETURN 1 (deny)
        IF lingua is not a blessed object THEN carp; RETURN 1 (deny)
        country := lingua->country()   [wrapped in eval]
        IF country is falsy (undef / "" / "0") THEN RETURN 1 (deny)
        country := lc(country)
        -- Transitive reduction: deny_countries is provably non-nil here.
        IF wildcard (*) in deny_countries THEN
            IF country in allow_countries THEN RETURN 0 (allow)
            ELSE                               RETURN 1 (deny)
        ELSE
            IF country in deny_countries THEN RETURN 1 (deny)
            ELSE                              RETURN 0 (allow)
        END IF
    END IF

    RETURN 1  (deny -- no rule permitted the request)

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report any bugs or feature requests to
`bug-cgi-acl at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-ACL](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-ACL).

A VPN or proxy will most likely bypass IP-based access control.

# SEE ALSO

- [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Net::CIDR](https://metacpan.org/pod/Net%3A%3ACIDR)
- [Test Dashboard](https://nigelhorne.github.io/CGI-ACL/coverage/)

# SUPPORT

    perldoc CGI::ACL

- MetaCPAN: [https://metacpan.org/release/CGI-ACL](https://metacpan.org/release/CGI-ACL)
- RT: [https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-ACL](https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-ACL)
- CPANTS: [http://cpants.cpanauthors.org/dist/CGI-ACL](http://cpants.cpanauthors.org/dist/CGI-ACL)
- CPAN Testers: [http://matrix.cpantesters.org/?dist=CGI-ACL](http://matrix.cpantesters.org/?dist=CGI-ACL)

# LIMITATIONS

- A VPN or anonymous proxy will likely bypass IP-based access control and may
defeat country detection as well.
- Country detection relies on [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua) and its underlying GeoIP database,
which must be updated regularly.  GeoIP databases are never fully accurate;
satellite and mobile networks in particular can be misattributed.
- Cloud detection depends on provider-maintained reverse-DNS records.  A cloud
host whose PTR record does not follow its provider's naming convention will
not be detected.  Conversely, a legitimate host whose PTR record accidentally
matches a cloud pattern could be falsely denied.
- DNS lookups are synchronous.  On non-Windows platforms a `$DNS_TIMEOUT`-second
alarm prevents indefinite blocking, but under high resolver load that latency
can still affect every request for an uncached IP.  For persistent processes
(FastCGI, mod\_perl) the built-in per-object cache (`$CLOUD_CACHE_TTL` seconds)
mitigates this significantly.
- The per-object DNS result cache is neither shared between processes nor
persistent across objects.  Under a pre-forking server each worker child
maintains an independent cache.
- Private methods (`_is_cloud_host`, `_verified_rdns`, `_rdns_forward`,
`_set_countries`) are not enforced as private with
`Sub::Private` because this module's white-box test suite (`t/function.t`,
`t/extended_tests.t`, etc.) calls them directly by fully-qualified name to
exercise specific code paths.  The `namespace::clean` pragma removes them
from the object's method dispatch table, and the `_` naming convention
signals their internal nature.
- Windows platforms do not support `alarm()`-based timeouts.  DNS lookups on
Windows block synchronously for as long as the OS resolver takes.
- An optional rate-limiting feature (to block brute-force attacks) has not yet
been implemented.  It would require persistent shared state (e.g. Redis or an
in-memory cache) beyond this module's current dependency set.

# FORMAL SPECIFICATION

## new

    ──────────────── ACLState ────────────────────────────────────────
      allowed_ips    : IP_Str ⇸ Bool
      deny_countries : Country ⇸ Bool
      allow_countries: Country ⇸ Bool
      deny_cloud     : Bool
      _cidrlist      : [CIDR_Str]?   -- memoised; cleared on allow_ip
      _cloud_cache   : IP_Str ⇸ {result: Bool, expires: Nat}?
    ──────────────────────────────────────────────────────────────────

    ─────────────── New ──────────────────────────────────────────────
      class  : ClassName ∪ ACLState
      params : ACLState?
      ─────────────────────────────────────────────────────────────────
      -- strip_private: removes keys whose names begin with '_'
      blessed(class) ⟹
        result! = bless( deepcopy(class) ∪ strip_private(params),
                         ref(class) )                    -- clone
      ¬blessed(class) ⟹
        result! = bless( strip_private(configure(class, params)),
                         class )
    ──────────────────────────────────────────────────────────────────

## allow\_ip

    ─────────────── AllowIP ──────────────────────────────────────────
      ΔACL
      ip? : IP_Str                 -- must satisfy valid_ip(ip?)
      ─────────────────────────────────────────────────────────────────
      allowed_ips' = allowed_ips₀ // {}   -- initialised on every call
      valid_ip(ip?) ⟹
        allowed_ips' = allowed_ips' ∪ { ip? ↦ 1 }
        _cidrlist'   = ∅          -- cache invalidated
      ¬valid_ip(ip?) ⟹
        allowed_ips' = allowed_ips' -- only initialisation, no entry
        _cidrlist'   = _cidrlist
      deny_countries' = deny_countries
      allow_countries' = allow_countries
      deny_cloud'     = deny_cloud
    ──────────────────────────────────────────────────────────────────

## deny\_country

    ─────────────── DenyCountry ─────────────────────────────────────
      ΔACL
      country? : ISO_Code ∪ {'*'} ∪ seq ISO_Code
      ─────────────────────────────────────────────────────────────────
      country? ∈ seq ISO_Code ⟹
        deny_countries' = deny_countries ∪
                          { lc(c) ↦ 1 | c ∈ country? }
      country? ∉ seq ISO_Code ⟹
        deny_countries' = deny_countries ∪ { lc(country?) ↦ 1 }
      allow_countries' = allow_countries
      allowed_ips'     = allowed_ips
      deny_cloud'      = deny_cloud
    ──────────────────────────────────────────────────────────────────

## allow\_country

    ─────────────── AllowCountry ────────────────────────────────────
      ΔACL
      country? : ISO_Code ∪ seq ISO_Code
      ─────────────────────────────────────────────────────────────────
      country? ∈ seq ISO_Code ⟹
        allow_countries' = allow_countries ∪
                           { lc(c) ↦ 1 | c ∈ country? }
      country? ∉ seq ISO_Code ⟹
        allow_countries' = allow_countries ∪ { lc(country?) ↦ 1 }
      deny_countries' = deny_countries
      allowed_ips'    = allowed_ips
      deny_cloud'     = deny_cloud
    ──────────────────────────────────────────────────────────────────

## deny\_cloud

    ─────────────── DenyCloud ───────────────────────────────────────
      ΔACL
      ─────────────────────────────────────────────────────────────────
      deny_cloud'     = 1
      allowed_ips'    = allowed_ips
      deny_countries' = deny_countries
      allow_countries'= allow_countries
      _cidrlist'      = _cidrlist
    ──────────────────────────────────────────────────────────────────

## deny\_all\_countries

    ─────────────── DenyAllCountries ────────────────────────────────
      ΔACL
      ─────────────────────────────────────────────────────────────────
      deny_countries' = deny_countries ∪ { '*' ↦ 1 }
      allow_countries' = allow_countries
      allowed_ips'    = allowed_ips
      deny_cloud'     = deny_cloud
    ──────────────────────────────────────────────────────────────────

## all\_denied

    ──────────────────────── AllDenied ──────────────────────────────
      ΞACL                          -- state unchanged (modulo cache)
      addr    : IPv4 ∪ IPv6         -- REMOTE_ADDR or DEFAULT_ADDR
      lingua? : Lingua              -- country resolver (optional)
      result! : {0, 1}              -- 0 = allow, 1 = deny
      ─────────────────────────────────────────────────────────────────
      no_restrictions(self) ⟹ result! = 0

      ¬valid_ip(addr) ⟹ result! = 1

      deny_cloud = 1 ∧ is_cloud(addr) ⟹ result! = 1
      deny_cloud = 1 ∧ ¬is_cloud(addr)
        ∧ allowed_ips = ∅ ∧ deny_countries = ∅ ⟹ result! = 0
        -- allow_countries is intentionally absent: it never changes the result
        -- without deny_countries('*'), so it is not a meaningful restriction.

      addr ∈ dom(allowed_ips) ⟹ result! = 0
      cidr_match(addr, allowed_ips) ⟹ result! = 0

      deny_countries ≠ ∅ ∧ lingua? = ∅ ⟹ result! = 1
        -- allow_countries alone is vacuous; only deny_countries triggers the check.
      lingua?.country() = undef ⟹ result! = 1

      deny_countries('*') = 1
        ∧ allow_countries(lc(lingua?.country())) = 1 ⟹ result! = 0
      deny_countries('*') = 1
        ∧ allow_countries(lc(lingua?.country())) ≠ 1 ⟹ result! = 1

      deny_countries('*') ≠ 1
        ∧ deny_countries(lc(lingua?.country())) = 1 ⟹ result! = 1
      deny_countries('*') ≠ 1
        ∧ deny_countries(lc(lingua?.country())) ≠ 1 ⟹ result! = 0
    ──────────────────────────────────────────────────────────────────

# LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
