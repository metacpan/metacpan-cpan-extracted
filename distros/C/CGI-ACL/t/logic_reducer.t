#!/usr/bin/env perl
# logic_reducer.t -- equivalence-partition proofs for all_denied() boolean logic.
#
# Each subtest targets exactly one decision boundary (one partition edge).
# Tests are named after their major premise so failures pinpoint the broken invariant.
#
# Mnemonic: if a subtest starts with "PREMISE:" it is asserting a top-level
# system invariant.  "BOUNDARY:" subtests probe the exact edge between allow/deny.

use strict;
use warnings;
use Carp;	# required: prevents Test::Carp glob aliasing from clearing Carp::carp

use Test::Most;
use Test::Carp;
use Test::Mockingbird;

BEGIN { use_ok('CGI::ACL') }

# ── Minimal lingua stub (avoids real WHOIS / GeoIP) ──────────────────────────

{
	package Test::FakeLingua;
	sub new     { my ($class, $cc) = @_; bless { cc => $cc }, $class }
	sub country { $_[0]->{cc} }
}

# ── Cloud-DNS mock (avoids real DNS) ─────────────────────────────────────────

my $dns_guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
	my $ip = $_[0];
	return 'ec2-1-2-3-4.compute-1.amazonaws.com' if $ip eq '1.2.3.4';  # AWS cloud
	return undef;  # non-cloud (no PTR or unverified)
};

# ── Helper ───────────────────────────────────────────────────────────────────

sub denied_at {
	my ($acl, $addr, @rest) = @_;
	local $ENV{REMOTE_ADDR} = $addr;
	return $acl->all_denied(@rest);
}

# =============================================================================
# PARTITION A — Early-return guard
# Major Premise: when no meaningful restrictions are configured, all_denied()
# returns 0 immediately without consulting REMOTE_ADDR or lingua.
# =============================================================================

subtest 'PREMISE: no restrictions => allow unconditionally' => sub {
	my $acl = CGI::ACL->new();
	local $ENV{REMOTE_ADDR} = 'not-an-ip';	# even an invalid addr is irrelevant
	is($acl->all_denied(), 0, 'empty ACL allows all');
};

subtest 'PREMISE: allow_country alone has no effect (guard returns early)' => sub {
	# Premise: allow_country without deny_country('*') never restricts.
	# Conclusion: the early-return guard must fire — no lingua is required.
	my $acl = CGI::ACL->new()->allow_country('GB');
	local $ENV{REMOTE_ADDR} = '203.0.113.1';
	is($acl->all_denied(), 0, 'allow_country alone allows without lingua');
};

# =============================================================================
# PARTITION B — Address validation
# =============================================================================

subtest 'BOUNDARY: malformed REMOTE_ADDR => deny' => sub {
	my $acl = CGI::ACL->new()->allow_ip('1.2.3.4');
	is(denied_at($acl, 'not-an-ip'), 1, 'invalid addr denied');
	is(denied_at($acl, '999.999.999.999'), 1, 'out-of-range quad denied');
};

# =============================================================================
# PARTITION C — Cloud check
# =============================================================================

subtest 'BOUNDARY: deny_cloud + cloud IP => deny (overrides allow_ip)' => sub {
	# Premise: deny_cloud has highest precedence.
	# Premise: 1.2.3.4 resolves to an AWS hostname via mock.
	# Conclusion: even if 1.2.3.4 is in the allow list, it must be denied.
	my $acl = CGI::ACL->new()->deny_cloud()->allow_ip('1.2.3.4');
	is(denied_at($acl, '1.2.3.4'), 1, 'cloud IP denied despite being in allow_ip');
};

subtest 'BOUNDARY: deny_cloud + non-cloud + no other restrictions => allow' => sub {
	# Premise: 5.6.7.8 has no PTR (mock returns undef) => non-cloud.
	# Premise: no allowed_ips, no deny_countries configured.
	# Conclusion: allow immediately after cloud check — no lingua needed.
	my $acl = CGI::ACL->new()->deny_cloud();
	is(denied_at($acl, '5.6.7.8'), 0, 'non-cloud allowed when deny_cloud is the only rule');
};

subtest 'PREMISE: deny_cloud + allow_country alone => allow non-cloud without lingua' => sub {
	# Major premise: allow_country without deny_country('*') never restricts.
	# Minor premise: after the cloud check passes (non-cloud IP), allow_countries
	#               alone is not a meaningful further restriction.
	# Conclusion: all_denied() must return 0 without consulting lingua.
	#
	# This was a bug before the optimization: including allow_countries in the
	# cloud fast-path caused an unnecessary lingua lookup and a spurious deny.
	my $acl = CGI::ACL->new()->deny_cloud()->allow_country('GB');
	is(denied_at($acl, '5.6.7.8'), 0,
		'non-cloud IP allowed; allow_country alone does not require lingua');
};

subtest 'BOUNDARY: deny_cloud + deny_country(*) + allow_country + non-cloud + no lingua => deny' => sub {
	# Premise: deny_country('*') IS a meaningful restriction.
	# Premise: deny_countries is set => cloud fast-path does NOT short-circuit.
	# Premise: no lingua => country is unknown => deny.
	my $acl = CGI::ACL->new()->deny_cloud()->deny_all_countries()->allow_country('GB');
	does_carp(sub {
		my $result = denied_at($acl, '5.6.7.8');
		is($result, 1, 'missing lingua => deny when deny_countries is active');
	});
};

# =============================================================================
# PARTITION D — IP allow-list
# =============================================================================

subtest 'BOUNDARY: allow_ip exact match => allow' => sub {
	my $acl = CGI::ACL->new()->allow_ip('198.51.100.5');
	is(denied_at($acl, '198.51.100.5'), 0, 'exact IP match allows');
	is(denied_at($acl, '198.51.100.6'), 1, 'IP not in list is denied');
};

subtest 'BOUNDARY: allow_ip CIDR match => allow' => sub {
	my $acl = CGI::ACL->new()->allow_ip('192.0.2.0/24');
	is(denied_at($acl, '192.0.2.100'), 0, 'IP inside CIDR allowed');
	is(denied_at($acl, '192.0.3.1'),   1, 'IP outside CIDR denied');
};

subtest 'BOUNDARY: allow_ip set, no match, no country rules => deny (fall-through)' => sub {
	# Premise: allowed_ips is set and addr does not match.
	# Premise: no deny_countries or deny_cloud.
	# Conclusion: fall-through return 1 fires.
	my $acl = CGI::ACL->new()->allow_ip('198.51.100.5');
	is(denied_at($acl, '203.0.113.99'), 1, 'unlisted IP denied when allow_ip is the only rule');
};

# =============================================================================
# PARTITION E — Country check
# =============================================================================

subtest 'BOUNDARY: deny_country(specific) + matching country => deny' => sub {
	my $acl  = CGI::ACL->new()->deny_country('cn');
	my $cn   = Test::FakeLingua->new('cn');
	my $us   = Test::FakeLingua->new('us');
	is(denied_at($acl, '5.6.7.8', lingua => $cn), 1, 'denied country is denied');
	is(denied_at($acl, '5.6.7.8', lingua => $us), 0, 'non-denied country is allowed');
};

subtest 'BOUNDARY: deny_country case-insensitivity' => sub {
	# Premise: codes are stored lowercase; country() may return mixed case.
	# Conclusion: lc() normalization must make 'CN' == 'cn'.
	my $acl = CGI::ACL->new()->deny_country('CN');
	my $cn  = Test::FakeLingua->new('cn');
	my $CN  = Test::FakeLingua->new('CN');
	is(denied_at($acl, '5.6.7.8', lingua => $cn), 1, 'lowercase country code denied');
	is(denied_at($acl, '5.6.7.8', lingua => $CN), 1, 'uppercase country code denied');
};

subtest 'BOUNDARY: deny_country(*) wildcard => deny non-listed country' => sub {
	my $acl = CGI::ACL->new()->deny_country('*')->allow_country('GB');
	my $gb  = Test::FakeLingua->new('gb');
	my $us  = Test::FakeLingua->new('us');
	is(denied_at($acl, '5.6.7.8', lingua => $gb), 0, 'allowed country passes wildcard-deny');
	is(denied_at($acl, '5.6.7.8', lingua => $us), 1, 'non-listed country denied under wildcard');
};

subtest 'BOUNDARY: deny_country active + country=undef => deny' => sub {
	# Premise: undef country means "unknown" => fail closed (deny).
	my $acl    = CGI::ACL->new()->deny_country('cn');
	my $nocc   = Test::FakeLingua->new(undef);
	is(denied_at($acl, '5.6.7.8', lingua => $nocc), 1, 'unknown country denied');
};

subtest 'BOUNDARY: deny_country active + no lingua => carp + deny' => sub {
	my $acl = CGI::ACL->new()->deny_country('cn');
	does_carp(sub {
		is(denied_at($acl, '5.6.7.8'), 1, 'missing lingua causes deny');
	});
};

subtest 'BOUNDARY: deny_country active + non-blessed lingua => carp + deny' => sub {
	my $acl = CGI::ACL->new()->deny_country('cn');
	does_carp(sub {
		is(denied_at($acl, '5.6.7.8', lingua => 'not-an-object'), 1,
			'scalar lingua causes deny');
	});
};

# =============================================================================
# PARTITION F — Combinatorics (multi-rule interactions)
# =============================================================================

subtest 'BOUNDARY: allow_ip + deny_country + IP matches => allow (IP takes priority)' => sub {
	# Premise: if the IP is in the allow list, the country check is skipped.
	my $acl = CGI::ACL->new()
		->allow_ip('198.51.100.5')
		->deny_country('us');
	is(denied_at($acl, '198.51.100.5', lingua => Test::FakeLingua->new('us')),
		0, 'allowed IP is let through even though country is denied');
};

subtest 'BOUNDARY: allow_ip no match + deny_country non-matching => allow (country check passes)' => sub {
	my $acl = CGI::ACL->new()
		->allow_ip('198.51.100.5')
		->deny_country('cn');
	is(denied_at($acl, '203.0.113.99', lingua => Test::FakeLingua->new('us')),
		0, 'non-listed IP from allowed country is permitted via country check');
};

subtest 'PREMISE: allow_country without deny_country(*) does not affect IP-only ACL' => sub {
	# Major premise: allow_country alone has no effect without deny_country('*').
	# Minor premise: allow_ip is set; an unmatched IP falls to the country check.
	# Optimization: the country check now only fires when deny_countries is set.
	# Conclusion: an unmatched IP with allow_country (no deny_country) is DENIED —
	# the correct result because no rule permitted the request.
	my $acl = CGI::ACL->new()
		->allow_ip('198.51.100.5')
		->allow_country('GB');    # no deny_country('*') — vacuous
	my $gb = Test::FakeLingua->new('gb');

	# Matched IP: allowed (as before)
	is(denied_at($acl, '198.51.100.5', lingua => $gb), 0,
		'listed IP still allowed with allow_country present');

	# Unmatched IP: denied — allow_country has no effect, country check does not fire
	is(denied_at($acl, '203.0.113.99', lingua => $gb), 1,
		'unlisted IP denied; allow_country alone is not a permit rule');

	# Unmatched IP without lingua: same result (no carp because country check is skipped)
	is(denied_at($acl, '203.0.113.99'), 1,
		'unlisted IP denied without lingua; no carp because country check is skipped');
};

subtest 'BOUNDARY: deny_all_countries() is sugar for deny_country(*)' => sub {
	# Premise: deny_all_countries() ≡ deny_country('*').
	my $acl_a = CGI::ACL->new()->deny_country('*')->allow_country('US');
	my $acl_b = CGI::ACL->new()->deny_all_countries()->allow_country('US');
	my $us    = Test::FakeLingua->new('us');
	my $cn    = Test::FakeLingua->new('cn');

	is(denied_at($acl_a, '5.6.7.8', lingua => $us),
		denied_at($acl_b, '5.6.7.8', lingua => $us),
		'allow: deny_all_countries identical to deny_country(*)');
	is(denied_at($acl_a, '5.6.7.8', lingua => $cn),
		denied_at($acl_b, '5.6.7.8', lingua => $cn),
		'deny: deny_all_countries identical to deny_country(*)');
};

done_testing();
