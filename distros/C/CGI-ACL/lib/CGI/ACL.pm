package CGI::ACL;

# Author Nigel Horne: njh@nigelhorne.com
# Copyright (C) 2017-2026, Nigel Horne
#
# Usage is subject to licence terms.

# TODO: Add deny_all_countries() so operators can easily allow only a few countries.
# TODO: Add optional rate-limiter to block brute-force attacks.

use 5.006_001;
use autodie qw(:all);
use warnings;
use strict;

# namespace::clean removes imported helper names from the public method list
use namespace::clean;

use Carp;
use Net::CIDR;
use Object::Configure;
use Params::Get;
use Readonly;
use Regexp::Common qw(net);
use Scalar::Util qw(blessed);
use Socket;

# ── Compile-time constants ─────────────────────────────────────────────────────

# Maximum seconds to wait for a DNS reverse lookup on non-Windows platforms.
Readonly my $DNS_TIMEOUT  => 10;

# Sentinel value stored in deny_countries to mean "deny every country".
Readonly my $WILDCARD     => q{*};

# Fallback client address when REMOTE_ADDR is absent (e.g. CLI or unit tests).
Readonly my $DEFAULT_ADDR => '127.0.0.1';

# Compiled regexes that identify cloud-provider reverse-DNS hostnames.
# _is_cloud_host() iterates this list; to add a provider, append a qr// here.
Readonly my @CLOUD_PATTERNS => (
	qr/\.compute(?:-\d+)?\.amazonaws\.com$/i,   # AWS EC2
	qr/\.bc\.googleusercontent\.com$/i,          # Google Cloud Compute
	qr/\.cloudapp\.net$/i,                       # Microsoft Azure
	qr/\.azure\.com$/i,                          # Microsoft Azure (general)
	qr/digitalocean/i,                           # DigitalOcean
	qr/\.members\.linode\.com$/i,               # Linode / Akamai
	qr/hetzner/i,                               # Hetzner Cloud
	qr/your-server\.de$/i,                      # Hetzner (legacy dedicated)
	qr/\.ovh\.net$/i,                           # OVH Cloud
	qr/^ip-\d+-\d+-\d+-\d+\.eu$/i,             # OVH European IP range
);

# ── Version ────────────────────────────────────────────────────────────────────

=head1 NAME

CGI::ACL - Decide whether to allow a client to run a CGI script

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

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

The module optionally integrates with L<CGI::Lingua> for country detection.
Runtime configuration is supported via L<Object::Configure>.

=head1 SUBROUTINES/METHODS

=head2 new

Creates and returns a new CGI::ACL object.

When called on an existing object it returns a shallow clone of that object,
optionally overriding fields with the supplied arguments.

Constructor arguments may also be supplied via environment variables of the
form C<CGI__ACL__E<lt>fieldE<gt>> or via a config file; see L<Object::Configure>
for details.

=head3 USAGE

    # No restrictions (allow all by default)
    my $acl = CGI::ACL->new();

    # Pre-seeded allow list
    my $acl = CGI::ACL->new(allowed_ips => { '127.0.0.1' => 1 });

    # Clone an existing ACL and add a restriction
    my $acl2 = $acl->new(deny_cloud => 1);

=head3 API SPECIFICATION

=head4 Input

    # Compatible with Params::Validate::Strict:
    {
        allowed_ips     => { type => 'hashref',  optional => 1 },
        deny_countries  => { type => 'hashref',  optional => 1 },
        allow_countries => { type => 'hashref',  optional => 1 },
        deny_cloud      => { type => 'boolean',  optional => 1 },
    }

=head4 Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }
    # or undef when called as CGI::ACL::new() instead of CGI::ACL->new()

=head3 MESSAGES

=over 4

=item C<< CGI::ACL use ->new() not ::new() to instantiate >>

B<Severity:> carp (warning).
B<Cause:> C<CGI::ACL::new(...)> was called as a plain function instead of
as a class method.
B<Action:> Change the call to C<< CGI::ACL->new(...) >>.

=back

=cut

sub new {
	my $class = shift;

	# Parse arguments uniformly (hashref, named pairs, or no args)
	my $params = Params::Get::get_params(undef, @_);

	# Handle the rare case of being called as a plain function: CGI::ACL::new()
	if(!defined($class)) {
		Carp::carp(__PACKAGE__ . ': use ->new() not ::new() to instantiate');
		return;
	} elsif(blessed($class)) {
		# Called on an existing object: return a clone with deep-copied sub-hashes
		# so that mutations to the clone do not affect the original.
		$params ||= {};
		my %copy = %{$class};
		for my $key (qw(allowed_ips deny_countries allow_countries)) {
			$copy{$key} = { %{$copy{$key}} } if ref($copy{$key}) eq 'HASH';
		}
		# The CIDR cache depends on allowed_ips; invalidate so it is rebuilt fresh.
		delete $copy{_cidrlist};
		return bless { %copy, %{$params} }, ref($class);
	}

	# Merge any config-file or environment-variable overrides
	$params = Object::Configure::configure($class, $params);

	return bless $params, $class;
}

# ── allow_ip ───────────────────────────────────────────────────────────────────

=head2 allow_ip

Adds an IPv4/IPv6 address or CIDR block to the set of explicitly permitted
clients.  When C<allowed_ips> is non-empty, any client address not matched
by an entry in the set is denied (subject to C<deny_cloud> taking precedence).

=head3 USAGE

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

=head3 ARGUMENTS

=over 4

=item ip (required)

A string containing an IPv4 address, an IPv6 address, or a CIDR block
(e.g. C<10.0.0.0/8>).  The value is stored verbatim; invalid addresses
will be silently ignored during lookup.

=back

=head3 RETURNS

The object itself, to allow method chaining.

=head3 SIDE EFFECTS

Invalidates the internal CIDR lookup cache so the next call to
C<all_denied()> will rebuild it with the new entry included.

=head3 API SPECIFICATION

=head4 Input

    # Compatible with Params::Validate::Strict:
    {
        ip => { type => 'string', regex => qr/\S+/, required => 1 },
    }

=head4 Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

=head3 MESSAGES

=over 4

=item C<Usage: allow_ip($ip_address)>

B<Severity:> carp (warning).
B<Cause:> Called with no argument, with a non-hash reference, or without
supplying the C<ip> key.
B<Action:> Pass a scalar IP/CIDR string: C<allow_ip('192.0.2.1')> or
C<allow_ip(ip =E<gt> '192.0.2.1')>.

=back

=cut

sub allow_ip {
	my $self = shift;

	# Reject non-hash, non-scalar references (e.g. a scalar ref passed by mistake)
	if(ref($_[0]) && ref($_[0]) ne 'HASH') {
		Carp::carp('Usage: allow_ip($ip_address)');
		return $self;
	}

	# Normalise positional, named, and hashref calling conventions
	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{ip} = shift;
	}

	# Store the address and invalidate the memoised CIDR list
	if(defined(my $ip = $params{ip})) {
		$self->{allowed_ips}->{$ip} = 1;
		delete $self->{_cidrlist};
	} else {
		Carp::carp('Usage: allow_ip($ip_address)');
	}
	return $self;
}

# ── deny_country ───────────────────────────────────────────────────────────────

=head2 deny_country

Adds one or more countries to the deny list.  Countries are identified by
their ISO 3166-1 alpha-2 codes (case-insensitive).

Passing the special value C<'*'> (wildcard) switches to default-deny mode:
all countries are denied unless they also appear in the allow list set by
C<allow_country()>.

=head3 USAGE

    use CGI::ACL;

    # Deny a single country
    my $acl = CGI::ACL->new()->deny_country('BR');

    # Deny a list of countries
    my $acl = CGI::ACL->new()->deny_country(country => ['BR', 'CN', 'RU']);

    # Default-deny all countries (use with allow_country to whitelist)
    my $acl = CGI::ACL->new()->deny_country('*')->allow_country('US');

=head3 ARGUMENTS

=over 4

=item country (required)

A scalar ISO code, the wildcard C<'*'>, or an array reference of ISO codes.

=back

=head3 RETURNS

The object itself, to allow method chaining.

=head3 SIDE EFFECTS

Updates C<< $self->{deny_countries} >>.

=head3 NOTES

C<allow_country()> has no effect unless C<deny_country('*')> has been called
first.  Calling C<allow_country()> alone (without the wildcard deny) does
not restrict access.

=head3 API SPECIFICATION

=head4 Input

    # Compatible with Params::Validate::Strict:
    {
        country => {
            type     => 'string' | 'arrayref',
            required => 1,
        },
    }

=head4 Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

=head3 MESSAGES

=over 4

=item C<Usage: deny_country($country)>

B<Severity:> carp (warning).
B<Cause:> Called with no argument, with a non-hash/non-array reference, or
without supplying the C<country> key.
B<Action:> Pass a scalar ISO code or arrayref:
C<deny_country('BR')> or C<deny_country(country =E<gt> ['BR','CN'])>.

=back

=cut

sub deny_country {
	my $self = shift;

	# Reject references that are neither hashes nor arrays
	if(ref($_[0]) && ref($_[0]) ne 'HASH' && ref($_[0]) ne 'ARRAY') {
		Carp::carp('Usage: deny_country($country)');
		return $self;
	}

	# Normalise positional, named, and hashref calling conventions
	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{country} = shift;
	}

	# Add the country or list of countries to the deny set.
	# An empty arrayref is a no-op — do not create deny_countries = {}.
	if(defined(my $c = $params{country})) {
		return $self if ref($c) eq 'ARRAY' && !@{$c};
		_set_countries($self->{deny_countries} ||= {}, $c);
	} else {
		Carp::carp('Usage: deny_country($country)');
	}
	return $self;
}

# ── allow_country ──────────────────────────────────────────────────────────────

=head2 allow_country

Adds one or more countries to the explicit permit list.  This is meaningful
only when C<deny_country('*')> has been called first; without the wildcard
deny, this method has no observable effect on access decisions.

=head3 USAGE

    use CGI::ACL;

    # Allow only the UK and US
    my $acl = CGI::ACL->new()
        ->deny_country('*')
        ->allow_country(country => ['GB', 'US']);

    # Single country as positional argument
    my $acl = CGI::ACL->new()->deny_country('*')->allow_country('US');

=head3 ARGUMENTS

=over 4

=item country (required)

A scalar ISO code or an array reference of ISO codes.

=back

=head3 RETURNS

The object itself, to allow method chaining.

=head3 SIDE EFFECTS

Updates C<< $self->{allow_countries} >>.

=head3 NOTES

Call C<deny_country('*')> before this method; otherwise all traffic is
already allowed by the default-allow rule and the permit list is never
consulted.

=head3 API SPECIFICATION

=head4 Input

    # Compatible with Params::Validate::Strict:
    {
        country => {
            type     => 'string' | 'arrayref',
            required => 1,
        },
    }

=head4 Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

=head3 MESSAGES

=over 4

=item C<Usage: allow_country($country)>

B<Severity:> carp (warning).
B<Cause:> Called with no argument, with a non-hash/non-array reference, or
without supplying the C<country> key.
B<Action:> Pass a scalar ISO code or arrayref:
C<allow_country('US')> or C<allow_country(country =E<gt> ['GB','US'])>.

=back

=cut

sub allow_country {
	my $self = shift;

	# Reject references that are neither hashes nor arrays
	if(ref($_[0]) && ref($_[0]) ne 'HASH' && ref($_[0]) ne 'ARRAY') {
		Carp::carp('Usage: allow_country($country)');
		return $self;
	}

	# Normalise positional, named, and hashref calling conventions
	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{country} = shift;
	}

	# Add the country or list of countries to the permit set.
	# An empty arrayref is a no-op — do not create allow_countries = {}.
	if(defined(my $c = $params{country})) {
		return $self if ref($c) eq 'ARRAY' && !@{$c};
		_set_countries($self->{allow_countries} ||= {}, $c);
	} else {
		Carp::carp('Usage: allow_country($country)');
	}
	return $self;
}

# ── deny_cloud ─────────────────────────────────────────────────────────────────

=head2 deny_cloud

Enables blocking of requests that originate from major cloud-hosting
providers.  Detection is performed via verified reverse DNS: the client
IP is looked up, the resulting hostname is forward-confirmed to prevent
spoofing, and the confirmed hostname is matched against a list of
provider-specific patterns.

Covered providers (as of this release): AWS EC2, Google Cloud Compute,
Microsoft Azure, DigitalOcean, Linode/Akamai, Hetzner, OVH.

B<Important:> C<deny_cloud> takes precedence over C<allow_ip>.  An IP
that is explicitly permitted via C<allow_ip()> is still denied if its
reverse DNS resolves to a cloud provider hostname.

=head3 USAGE

    use CGI::ACL;

    my $acl = CGI::ACL->new()->deny_cloud();

    if ($acl->all_denied()) {
        print "Cloud-hosted clients are not permitted.\n";
        exit;
    }

=head3 ARGUMENTS

None.

=head3 RETURNS

The object itself, to allow method chaining.

=head3 SIDE EFFECTS

Sets C<< $self->{deny_cloud} >> to C<1>.

=head3 NOTES

IPv4 and IPv6 clients are both subject to the cloud check.  A client with
no reverse DNS record, or whose forward confirmation fails, is treated as
a non-cloud host and allowed through the cloud check (though it may still
be denied by other rules).

DNS lookups are performed synchronously.  On non-Windows platforms a
C<$DNS_TIMEOUT>-second alarm is used to prevent indefinite blocking.

=head3 API SPECIFICATION

=head4 Input

    # No parameters accepted.
    {}

=head4 Output

    # Compatible with Return::Set:
    { type => 'object', isa => 'CGI::ACL' }

=head3 MESSAGES

This method emits no messages.

=cut

sub deny_cloud {
	my $self = shift;

	# Mark cloud-origin blocking as active
	$self->{deny_cloud} = 1;
	return $self;
}

# ── all_denied ─────────────────────────────────────────────────────────────────

=head2 all_denied

Evaluates every active restriction against the current client and returns
C<1> (deny) or C<0> (allow).

The evaluation order is:

=over 4

=item 1.

If B<no> restrictions are configured at all, return C<0> (allow).

=item 2.

Validate C<REMOTE_ADDR> as a syntactically correct IPv4 or IPv6 address.
If it is missing or malformed, return C<1> (deny).

=item 3.

If C<deny_cloud> is set, perform a verified reverse-DNS lookup.  If the
hostname matches a cloud provider, return C<1> (deny) immediately,
regardless of C<allowed_ips>.  If the IP is not a cloud host and no
other restrictions are active, return C<0> (allow).

=item 4.

If C<allowed_ips> is set, check the client address against the exact-match
hash and then the CIDR list.  Return C<0> (allow) on a match.

=item 5.

If country restrictions are set, resolve the client's country via the
C<lingua> argument.  Apply default-deny or default-allow country logic.
If no lingua is provided, emit a warning and return C<1> (deny).

=back

Note that localhost (C<127.0.0.1>) is B<not> automatically allowed once
any restriction is configured; call C<allow_ip('127.0.0.1')> explicitly.

=head3 USAGE

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

=head3 ARGUMENTS

=over 4

=item lingua (optional)

A L<CGI::Lingua> object (or any object with a C<country()> method returning
an ISO 3166-1 alpha-2 code or C<undef>).  Required when country restrictions
are active; ignored otherwise.

=back

=head3 RETURNS

C<1> if access is denied, C<0> if access is allowed.

=head3 SIDE EFFECTS

May populate or update C<< $self->{_cidrlist} >> (the memoised CIDR lookup
structure) as a performance optimisation.

=head3 API SPECIFICATION

=head4 Input

    # Compatible with Params::Validate::Strict:
    {
        lingua => { type => 'object', optional => 1 },
    }

=head4 Output

    # Compatible with Return::Set:
    { type => 'string', regex => qr/^[01]$/ }

=head3 MESSAGES

=over 4

=item C<Usage: all_denied($lingua)>

B<Severity:> carp (warning).
B<Cause:> Country restrictions are active (C<deny_country> or
C<allow_country> was called) but no C<lingua> argument was supplied.
B<Action:> Pass a C<CGI::Lingua> object:
C<all_denied(lingua =E<gt> $lingua)>.

=back

=cut

sub all_denied {
	my $self = shift;

	# Fast-path: if no restrictions are configured at all, allow immediately.
	# This guard must list every restriction type; missing one means that
	# restriction silently has no effect when used alone.
	if(
		(!defined($self->{allowed_ips}))    &&
		(!defined($self->{deny_countries})) &&
		(!$self->{deny_cloud})              &&
		(!defined($self->{allow_countries}))
	) {
		return 0;
	}

	# Determine the client address, falling back to localhost when absent.
	# Use // (defined-or) not || to avoid treating "0" or "" as absent.
	my $addr = $ENV{REMOTE_ADDR} // $DEFAULT_ADDR;

	# Reject addresses that are not syntactically valid IPv4 or IPv6
	return 1 unless $addr =~ /^$RE{net}{IPv4}$/o
	             || $addr =~ /^$RE{net}{IPv6}$/o;

	# ── Cloud check (highest precedence; overrides allow_ip) ────────────────
	if($self->{deny_cloud}) {
		# Deny if the IP resolves to a cloud provider hostname.
		# Wrap in eval: DNS failures must not kill the CGI process; fail safe.
		my $is_cloud = eval { _is_cloud_host($addr) };
		return 1 if !$@ && $is_cloud;

		# Non-cloud and no other restrictions: allow
		return 0 unless $self->{allowed_ips}
		             || $self->{deny_countries}
		             || $self->{allow_countries};
	}

	# ── IP / CIDR allow-list check ──────────────────────────────────────────
	if($self->{allowed_ips}) {
		# Check for an exact-match entry first (fast path)
		return 0 if $self->{allowed_ips}->{$addr};

		# Build and memoise the CIDR lookup structure on first use.
		# Wrap in eval: Net::CIDR dies on non-IP strings (injection attempts).
		if(!$self->{_cidrlist}) {
			my @cidrlist;
			for my $block (keys %{$self->{allowed_ips}}) {
				eval { @cidrlist = Net::CIDR::cidradd($block, @cidrlist) };
			}
			$self->{_cidrlist} = \@cidrlist;
		}

		# Check whether the address falls inside any allowed CIDR range.
		# Wrap in eval in case the list was built from partly-invalid entries.
		my $in_cidr = eval { Net::CIDR::cidrlookup($addr, @{$self->{_cidrlist}}) };
		return 0 if $in_cidr;
	}

	# ── Country check ───────────────────────────────────────────────────────
	if($self->{deny_countries} || $self->{allow_countries}) {
		# Parse the lingua argument (positional, named, or hashref)
		my %params;
		if(ref($_[0]) eq 'HASH') {
			%params = %{$_[0]};
		} elsif(@_ % 2 == 0) {
			%params = @_;
		} else {
			$params{lingua} = shift;
		}

		if(my $lingua = $params{lingua}) {
			# Reject non-objects to avoid "can't call method on non-ref" crashes
			unless(blessed($lingua)) {
				Carp::carp('all_denied: lingua must be a blessed object');
				return 1;
			}
			# Resolve and normalise the client's country code.
			# Wrap in eval: the object may not implement country().
			my $country_val = eval { $lingua->country() };
			return 1 if $@;    # method missing or threw — treat as unknown
			if(my $country = $country_val) {
				$country = lc $country;

				# Default-deny mode: deny_countries contains the wildcard
				if($self->{deny_countries} && $self->{deny_countries}->{$WILDCARD}) {
					return ($self->{allow_countries} && $self->{allow_countries}->{$country})
						? 0   # country is explicitly permitted
						: 1;  # not in the permit list; deny
				}

				# Default-allow mode: deny only explicitly listed countries
				return ($self->{deny_countries} && $self->{deny_countries}->{$country})
					? 1   # country is explicitly denied
					: 0;  # not in the deny list; allow
			}
			# country() returned undef: country is unknown; deny access
		} else {
			# Country restrictions active but no lingua was provided
			Carp::carp('Usage: all_denied($lingua)');
		}
	}

	# Fall-through: no rule allowed the request; deny
	return 1;
}

# ── Internal helpers ──────────────────────────────────────────────────────────

# _set_countries
#
# Purpose:    Shared logic for deny_country() and allow_country().  Inserts one
#             or more lowercased country codes into the supplied hashref.
#
# Entry:      $hashref  - the target hash (already initialised by caller)
#             $value    - a scalar country code OR an arrayref of codes
#
# Exit:       Returns nothing (modifies $hashref in place).
#
# Side effects: Modifies the caller-supplied hashref.
#
# Notes:      Keys are forced to lower case for case-insensitive comparison.
sub _set_countries {
	my ($hashref, $value) = @_;

	# Handle both a single country code and a list reference.
	# Skip undef elements to avoid "uninitialised value" warnings.
	if(ref($value) eq 'ARRAY') {
		$hashref->{lc $_} = 1 for grep { defined } @{$value};
	} else {
		$hashref->{lc $value} = 1;
	}
	return;
}

# _is_cloud_host
#
# Purpose:    Determines whether a given IP address belongs to a major cloud
#             provider by performing a verified reverse-DNS lookup and then
#             matching the confirmed hostname against @CLOUD_PATTERNS.
#
# Entry:      $ip - a validated IPv4 or IPv6 address string.
#
# Exit:       Returns 1 (cloud host) or 0 (not a cloud host / no PTR record).
#
# Side effects: Performs DNS lookups; may block for up to $DNS_TIMEOUT seconds
#               on non-Windows platforms.
#
# Notes:      An IP with no PTR record, or whose forward confirmation fails,
#             returns 0 (not cloud).  This is the safe default because
#             legitimate cloud providers consistently set rDNS records.
sub _is_cloud_host {
	my $ip = $_[0];

	# Attempt a verified reverse DNS lookup; returns undef on failure
	my $hostname = _verified_rdns($ip) or return 0;

	# Compare the confirmed hostname against every known cloud pattern
	for my $pattern (@CLOUD_PATTERNS) {
		return 1 if $hostname =~ $pattern;
	}
	return 0;
}

# _verified_rdns
#
# Purpose:    Performs a two-step DNS verification to prevent rDNS spoofing:
#               1. Reverse lookup: IP -> hostname
#               2. Forward confirmation: hostname -> [IPs]; IP must appear
#
# Entry:      $ip - a syntactically valid IPv4 or IPv6 address string.
#
# Exit:       Returns the confirmed hostname string on success, undef otherwise.
#             undef is returned when:
#               - $ip cannot be packed (invalid address)
#               - no PTR record exists
#               - forward lookup does not include the original IP
#               - DNS lookup times out (non-Windows only)
#
# Side effects: Performs two DNS round-trips; installs and restores a temporary
#               SIGALRM handler on non-Windows platforms.
#
# Notes:      On non-Windows platforms a $DNS_TIMEOUT-second alarm is set to
#             prevent CGI workers from blocking indefinitely on slow resolvers.
#             alarm(0) is called inside the eval to close the race window
#             between eval exit and the outer alarm(0) call.
sub _verified_rdns {
	my $ip = $_[0];

	# Determine address family and produce the packed binary address
	my ($family, $packed);
	if($ip =~ /:/o) {
		# IPv6: use inet_pton which handles all valid IPv6 formats
		$family = Socket::AF_INET6;
		$packed = Socket::inet_pton(Socket::AF_INET6, $ip) or return;
	} else {
		# IPv4: inet_aton handles dotted-quad addresses
		$family = AF_INET;
		$packed = inet_aton($ip) or return;
	}

	# Normalise the IP to canonical form for reliable string comparison.
	# This handles abbreviated IPv6 forms such as '::1' vs '0:0:...:1'.
	my $canonical = ($family == AF_INET)
		? inet_ntoa($packed)
		: Socket::inet_ntop(Socket::AF_INET6, $packed);

	my ($hostname, @forward_ips);

	if($^O ne 'MSWin32') {
		# Non-Windows: guard against indefinitely-blocking DNS calls
		local $SIG{ALRM} = sub { die "DNS timeout: $ip" };
		alarm($DNS_TIMEOUT);
		eval {
			# Step 1: reverse lookup (IP -> hostname)
			$hostname = gethostbyaddr($packed, $family);
			if($hostname) {
				# Step 2: forward lookup (hostname -> IP list)
				@forward_ips = _rdns_forward($hostname, $family);
			}
			# Cancel the alarm inside the eval to avoid a post-eval race
			alarm(0);
		};
		# Belt-and-suspenders: ensure the alarm is always cancelled
		alarm(0);
		return if $@ || !$hostname;
	} else {
		# Windows: no alarm support; perform lookups synchronously
		$hostname = gethostbyaddr($packed, $family) or return;

		# Forward lookup to confirm the hostname maps back to the original IP
		@forward_ips = _rdns_forward($hostname, $family);
	}

	# Step 3: the hostname is only trusted if a forward record confirms the IP
	return (grep { $_ eq $canonical } @forward_ips) ? $hostname : undef;
}

# _rdns_forward
#
# Purpose:    Resolves a hostname to a list of IP address strings for use in
#             the forward-confirmation step of _verified_rdns().
#
# Entry:      $hostname - the fully-qualified domain name to resolve.
#             $family   - address family: AF_INET or Socket::AF_INET6.
#
# Exit:       Returns a list of IP address strings (may be empty on failure).
#
# Side effects: Performs a DNS A or AAAA lookup.
#
# Notes:      For IPv4 uses the classic inet_aton/inet_ntoa chain.
#             For IPv6 uses Socket::getaddrinfo and Socket::getnameinfo
#             (available since Perl 5.14 / Socket 1.99).
sub _rdns_forward {
	my ($hostname, $family) = @_;

	# IPv4 path: resolve A record and convert each packed address to a string
	if($family == AF_INET) {
		return map  { inet_ntoa($_)  }
		       grep { defined        }
		       map  { inet_aton($_)  }
		       ($hostname);
	}

	# IPv6 path: use getaddrinfo to resolve AAAA records
	my ($err, @addrs) = Socket::getaddrinfo(
		$hostname, undef,
		{ family => $family, socktype => SOCK_STREAM },
	);
	return () if $err;

	# Convert each opaque sockaddr to a numeric IP string
	my @ips;
	for my $addr_info (@addrs) {
		my ($e, $host) = Socket::getnameinfo(
			$addr_info->{addr}, Socket::NI_NUMERICHOST,
		);
		push @ips, $host unless $e;
	}
	return @ips;
}

=encoding utf-8

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-acl at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-ACL>.

A VPN or proxy will most likely bypass IP-based access control.

=head1 SEE ALSO

=over 4

=item * L<CGI::Lingua>

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Net::CIDR>

=item * L<Test Dashboard|https://nigelhorne.github.io/CGI-ACL/coverage/>

=back

=head1 SUPPORT

    perldoc CGI::ACL

=over 4

=item * MetaCPAN: L<https://metacpan.org/release/CGI-ACL>

=item * RT: L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-ACL>

=item * CPANTS: L<http://cpants.cpanauthors.org/dist/CGI-ACL>

=item * CPAN Testers: L<http://matrix.cpantesters.org/?dist=CGI-ACL>

=back

=head2 FORMAL SPECIFICATION

=head3 new

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

=head3 allow_ip

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

=head3 deny_country

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

=head3 allow_country

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

=head3 deny_cloud

    ─────────────── DenyCloud ───────────────────────────────────────
      ΔACL
      ─────────────────────────────────────────────────────────────────
      deny_cloud'     = 1
      allowed_ips'    = allowed_ips
      deny_countries' = deny_countries
      allow_countries'= allow_countries
      _cidrlist'      = _cidrlist
    ──────────────────────────────────────────────────────────────────

=head3 all_denied

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

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
