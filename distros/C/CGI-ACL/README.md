[![Travis Status](https://travis-ci.org/nigelhorne/CGI-ACL.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-ACL)
[![Appveyor status](https://ci.appveyor.com/api/projects/status/5wa2lsb6c86x9jp0?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-acl)
[![Coveralls Status](https://coveralls.io/repos/github/nigelhorne/CGI-ACL/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-ACL?branch=master)
[![CPAN](https://img.shields.io/cpan/v/CGI-ACL.svg)](http://search.cpan.org/~nhorne/CGI-ACL/)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/CGI-ACL.png)](http://cpants.cpanauthors.org/dist/CGI-ACL)

# NAME

CGI::ACL - Decide whether to allow a client to run a CGI script

# VERSION

Version 0.08

# SYNOPSIS

Provides access control for CGI scripts based on IP address, CIDR block,
geographic country, and cloud-provider origin.

    use CGI::Lingua;
    use CGI::ACL;

    # Allow only UK visitors from a specific subnet
    my $acl = CGI::ACL->new()
        ->deny_country('*')
        ->allow_country('GB')
        ->allow_ip('192.0.2.0/24');

    if ($acl->all_denied(lingua => CGI::Lingua->new(supported => ['en']))) {
        print "Access denied.\n";
        exit;
    }

The module optionally integrates with [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua) for country detection.
Runtime configuration is supported via [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

# SUBROUTINES/METHODS

## new

Creates and returns a new CGI::ACL object.

When called on an existing object it returns a shallow clone of that object,
optionally overriding fields with the supplied arguments.

Constructor arguments may also be supplied via environment variables of the
form `CGI__ACL__<field>` or via a config file; see [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)
for details.

### USAGE

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

### USAGE

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
    (e.g. `10.0.0.0/8`).  The value is stored verbatim; invalid addresses
    will be silently ignored during lookup.

### RETURNS

The object itself, to allow method chaining.

### SIDE EFFECTS

Invalidates the internal CIDR lookup cache so the next call to
`all_denied()` will rebuild it with the new entry included.

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

## deny\_country

Adds one or more countries to the deny list.  Countries are identified by
their ISO 3166-1 alpha-2 codes (case-insensitive).

Passing the special value `'*'` (wildcard) switches to default-deny mode:
all countries are denied unless they also appear in the allow list set by
`allow_country()`.

### USAGE

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

### USAGE

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

### USAGE

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

### USAGE

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
structure) as a performance optimisation.

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

## FORMAL SPECIFICATION

### new

    ──────────────── ACLState ────────────────────────────────────────
      allowed_ips    : IP_Str ⇸ Bool
      deny_countries : Country ⇸ Bool
      allow_countries: Country ⇸ Bool
      deny_cloud     : Bool
      _cidrlist      : [CIDR_Str]?        -- memoised; cleared on allow_ip
    ──────────────────────────────────────────────────────────────────

    ─────────────── New ──────────────────────────────────────────────
      class  : ClassName ∪ ACLState
      params : ACLState?
      ─────────────────────────────────────────────────────────────────
      blessed(class) ⟹
        result! = bless( class ∪ params, ref(class) )   -- clone
      ¬blessed(class) ⟹
        result! = bless( configure(class, params), class )
    ──────────────────────────────────────────────────────────────────

### allow\_ip

    ─────────────── AllowIP ──────────────────────────────────────────
      ΔACL
      ip? : IP_Str
      ─────────────────────────────────────────────────────────────────
      allowed_ips' = allowed_ips ∪ { ip? ↦ 1 }
      _cidrlist'   = ∅          -- cache invalidated
      deny_countries' = deny_countries
      allow_countries' = allow_countries
      deny_cloud'     = deny_cloud
    ──────────────────────────────────────────────────────────────────

### deny\_country

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

### allow\_country

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

### deny\_cloud

    ─────────────── DenyCloud ───────────────────────────────────────
      ΔACL
      ─────────────────────────────────────────────────────────────────
      deny_cloud'     = 1
      allowed_ips'    = allowed_ips
      deny_countries' = deny_countries
      allow_countries'= allow_countries
      _cidrlist'      = _cidrlist
    ──────────────────────────────────────────────────────────────────

### all\_denied

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
        ∧ allowed_ips = ∅ ∧ deny_countries = ∅
        ∧ allow_countries = ∅            ⟹ result! = 0

      addr ∈ dom(allowed_ips) ⟹ result! = 0
      cidr_match(addr, allowed_ips) ⟹ result! = 0

      (deny_countries ≠ ∅ ∨ allow_countries ≠ ∅)
        ∧ lingua? = ∅ ⟹ result! = 1      -- no lingua supplied
      lingua?.country() = undef ⟹ result! = 1   -- unknown country

      deny_countries($WILDCARD) = 1
        ∧ allow_countries(lc(lingua?.country())) = 1 ⟹ result! = 0
      deny_countries($WILDCARD) = 1
        ∧ allow_countries(lc(lingua?.country())) ≠ 1 ⟹ result! = 1

      deny_countries($WILDCARD) ≠ 1
        ∧ deny_countries(lc(lingua?.country())) = 1 ⟹ result! = 1
      deny_countries($WILDCARD) ≠ 1
        ∧ deny_countries(lc(lingua?.country())) ≠ 1 ⟹ result! = 0
    ──────────────────────────────────────────────────────────────────

# LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
