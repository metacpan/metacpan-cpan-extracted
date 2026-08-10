#!/usr/bin/env perl

=head1 NAME

t/cgi_security.t - CGI penetration tests for Class::Simple::Readonly::Cached

=head1 DESCRIPTION

Simulates hostile HTTP inputs reaching a CSRC-wrapped object deployed inside
a CGI application.  Each test block targets a specific exploit mechanism and
asserts that the module either I<rejects the input safely> (croak/carp with no
further damage) or is I<transparently safe> (the caching layer itself does not
introduce a new vulnerability, even though the application layer may still need
to sanitize).

Tests labelled C<TODO> document known limitations or undocumented bugs where
the module does B<not> yet handle the attack safely; they are expected to fail
until the underlying issue is fixed.

=head1 CGI SECURITY CONTRACT

This module is a library, not a standalone CGI script.  When deployed in a CGI
application the following inputs reach C<AUTOLOAD> as method arguments.  The
B<application layer> is responsible for validating and sanitizing these before
forwarding them.  The tests below verify how the caching layer behaves when
that sanitization is absent.

=head3 API SPECIFICATION

    # Typical CGI usage (application is responsible for untainting inputs):
    #
    # HTTP variables consumed indirectly via method args:
    #   QUERY_STRING  -- GET parameters forwarded as method arguments
    #   PATH_INFO     -- path segments forwarded as method arguments
    #   HTTP_COOKIE   -- cookie values forwarded as method arguments
    #   HTTP_REFERER  -- referrer forwarded as method arguments
    #   HTTP_USER_AGENT -- user-agent forwarded as method arguments
    #   CONTENT_LENGTH  -- governs POST body size; CSRC imposes no limit
    #
    # Parameters used in Class::Simple::Readonly::Cached->new():
    #   cache  => { type => ['hashref', 'object'], required => 1 }
    #   object => { type => 'ref',                 optional => 1 }
    #   quiet  => { type => 'bool',                optional => 1 }
    #
    # Output: CSRC is a transparent decorator; the caller is responsible
    # for escaping/validating return values before emitting them into HTTP
    # response headers or HTML bodies.

=head3 FORMAL SPECIFICATION (Z calculus)

    # Attacker model:
    #   A : Set of hostile strings (XSS, CRLF, shell metachar, null, path traversal)
    #
    # Safety invariant for AUTOLOAD:
    #   ∀ a ∈ A, m : MethodName:
    #     AUTOLOAD(wrapper, m, a) = inner.m(a)   -- transparent passthrough
    #     ∧ ¬∃ side-effect(exec | system | open-pipe)
    #                                              -- no code execution by CSRC
    #
    # Rejection invariant for new():
    #   ∀ s : Scalar, ∀ r : NonHashNonObjectRef:
    #     new(cache => s) → croak               -- scalar cache rejected
    #     new(cache => r) → croak               -- non-HASH ref cache rejected
    #     new(object => s) → carp ∧ return undef -- scalar object rejected

=cut

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Readonly;
use Class::Simple::Readonly::Cached;

# ===========================================================================
# Inline inner-object mock.
#
# Returns its first argument verbatim (echo), two args as a list (multi), or
# a constant (fixed).  Keeps the tests independent of Class::Simple attribute
# semantics and gives full control over what the inner object "returns" -- the
# key variable under attack.
# ===========================================================================
package CgiPenTest::Echo;
use strict;
use warnings;
sub new   { bless {}, shift }
sub echo  { $_[1] }              # reflect first arg; undef if none supplied
sub multi { ($_[1], $_[2]) }     # reflect first two args as a list
sub fixed { 'safe_value' }       # constant -- never varies

package main;

# ===========================================================================
# Hostile payload constants.  One definition per vector so every subtest uses
# the exact same byte sequences.  Readonly prevents accidental mutation.
# ===========================================================================
Readonly::Scalar my $XSS_PAYLOAD    => '<script>alert(document.cookie)</script>';
Readonly::Scalar my $CRLF_PAYLOAD   => "foo\r\nSet-Cookie: session=hijacked; Domain=.example.com";
Readonly::Scalar my $CMD_INJECT     => '$(rm -rf /); `whoami`; | cat /etc/passwd';
Readonly::Scalar my $NULL_PAYLOAD   => "safe\0injected";
Readonly::Scalar my $PATH_TRAVERSAL => '../../../etc/passwd';

# The exact internal sentinel string.  If the inner object can be made to
# return this value, the hit path silently coerces it to undef (Vector 3).
Readonly::Scalar my $UNDEF_SENTINEL => 'Class::Simple::Readonly::Cached>UNDEF<';

Readonly::Scalar my $FLOOD_N       => 200;      # unique args per flooding test
Readonly::Scalar my $LARGE_ARG_LEN => 65_536;   # 64 KiB -- one typical CGI field

Readonly::Scalar my $INNER_CLASS   => 'CgiPenTest::Echo';
Readonly::Scalar my $WRAPPER_CLASS => 'Class::Simple::Readonly::Cached';

# Convenience: fresh wrapper backed by a private hash cache.
sub _wrapped { $WRAPPER_CLASS->new(cache => {}, object => $INNER_CLASS->new()) }

# ===========================================================================
# VECTOR 1 -- Command Injection via CGI Arguments
#
# Exploit: AUTOLOAD forwards caller arguments directly to the inner object via
#   $object->$method(@_)
# If the inner object passes those args to system(), exec(), or a 2-arg open(),
# shell metacharacters in a CGI query parameter execute arbitrary commands.
# CSRC itself contains none of these calls; verify that it does not interpret
# the payload and that it stores/returns the raw bytes intact.
# ===========================================================================
subtest 'command injection: shell metacharacters stored and returned verbatim' => sub {
	local %ENV = (%ENV,
		QUERY_STRING    => "cmd=$CMD_INJECT",
		HTTP_USER_AGENT => $CMD_INJECT,
	);

	my $cached = _wrapped();

	# Miss path: AUTOLOAD proxies the hostile arg to the inner object.
	# echo() reflects it back.  The test asserts no transformation occurred.
	is($cached->echo($CMD_INJECT), $CMD_INJECT,
		'cache miss: shell metacharacters returned verbatim (CSRC does not execute them)');

	# Hit path: result comes from cache, still the raw hostile string.
	is($cached->echo($CMD_INJECT), $CMD_INJECT,
		'cache hit: shell metacharacters returned verbatim from cache');

	returns_is($cached->echo($CMD_INJECT), { type => 'scalar' },
		'return type is scalar regardless of shell content');
};

# ===========================================================================
# VECTOR 2 -- XSS Payload Passthrough
#
# Exploit: a CGI param value containing <script>...</script> is forwarded
# through the caching layer unchanged.  If the application reflects the cached
# value into an HTML response without HTML-entity encoding it, the browser will
# execute the injected script.
#
# CSRC is a transparent decorator: it must NOT alter values, so XSS sanitization
# is the responsibility of the output layer, not this module.  This test
# documents the passthrough behaviour and the application-layer obligation.
# ===========================================================================
subtest 'XSS payload passes through the caching layer unescaped' => sub {
	local %ENV = (%ENV,
		QUERY_STRING => "name=$XSS_PAYLOAD",
		HTTP_REFERER => $XSS_PAYLOAD,
	);

	my $cached = _wrapped();

	is($cached->echo($XSS_PAYLOAD), $XSS_PAYLOAD,
		'cache miss: XSS payload returned verbatim -- HTML-encode at the output layer');
	is($cached->echo($XSS_PAYLOAD), $XSS_PAYLOAD,
		'cache hit: XSS payload returned verbatim from cache');

	# Confirm no accidental escaping such as &lt; substitution was introduced.
	unlike($cached->echo($XSS_PAYLOAD), qr/&lt;/,
		'CSRC does not HTML-encode angle brackets (encoding is the caller\'s job)');
};

# ===========================================================================
# VECTOR 3 -- CRLF Header Injection via Cached Return Values
#
# Exploit: a cached value containing \r\n, when placed into a CGI
#   Location: or Set-Cookie: header without stripping the CR/LF, injects
#   attacker-controlled HTTP headers into the response -- response splitting.
# CSRC stores and returns the value unchanged; sanitization must happen before
# the value is emitted into any HTTP header.
# ===========================================================================
subtest 'CRLF header injection: CRLF in cached value is not stripped' => sub {
	local %ENV = (%ENV, QUERY_STRING => "redirect=$CRLF_PAYLOAD");

	my $cached = _wrapped();

	# Verify the raw CRLF bytes are present in the cached return value.
	my $result = $cached->echo($CRLF_PAYLOAD);
	like($result, qr/\r\n/,
		'cache miss: CRLF sequence preserved -- strip \\r\\n before emitting into HTTP headers');

	my $hit_result = $cached->echo($CRLF_PAYLOAD);
	like($hit_result, qr/\r\n/,
		'cache hit: CRLF sequence preserved in cache -- same stripping obligation');
};

# ===========================================================================
# VECTOR 4 -- Null Byte Injection in Cache Keys
#
# Exploit: some cache backends (BerkeleyDB, Memcached, file stores) use
# C-string semantics and silently truncate keys at the first \0 byte.
# If an attacker injects "safe\0injected" as a CGI argument, a C-string
# backend would store it under the key for "safe", causing a false hit
# when a legitimate "safe" lookup is performed later (cross-user data leak).
#
# The hash-ref backend is backed by a Perl hash; Perl strings are binary-
# safe, so the full key including \0 is preserved.  The test documents both
# the hash-backend behaviour (safe) and the CHI-backend risk (application-
# layer concern: validate CGI inputs to exclude \0 before using a C-string-
# unsafe backend).
# ===========================================================================
subtest 'null byte injection: hash backend stores full binary key (binary-safe)' => sub {
	local %ENV = (%ENV, QUERY_STRING => "file=$NULL_PAYLOAD");

	my $cache  = {};
	my $object = $INNER_CLASS->new();
	my $cached = $WRAPPER_CLASS->new(cache => $cache, object => $object);

	$cached->echo($NULL_PAYLOAD);    # populate the cache

	my $full_key  = $WRAPPER_CLASS . '::echo::' . $NULL_PAYLOAD;
	my $trunc_key = $WRAPPER_CLASS . '::echo::safe';    # what a C-string backend would store

	ok(exists $cache->{$full_key},
		'hash backend: full key including \\0 byte is stored intact');
	ok(!exists $cache->{$trunc_key},
		'hash backend: no entry exists under the truncated key -- no false collision');
};

# ===========================================================================
# VECTOR 5 -- Path Traversal as Method Argument
#
# Exploit: a CGI script may pass a user-supplied file path to a cached method,
# e.g. $cached->load('../../../etc/passwd').  CSRC forwards the arg unchanged
# to the inner object; the inner object is responsible for rejecting traversal.
# CSRC must not alter the string (which would mask a traversal from inspection)
# and must not perform any file I/O itself.
# ===========================================================================
subtest 'path traversal: argument is forwarded unchanged to the inner object' => sub {
	local %ENV = (%ENV, PATH_INFO => $PATH_TRAVERSAL);

	my $cached = _wrapped();

	is($cached->echo($PATH_TRAVERSAL), $PATH_TRAVERSAL,
		'path traversal string forwarded to inner object verbatim (no I/O by CSRC)');
	is($cached->echo($PATH_TRAVERSAL), $PATH_TRAVERSAL,
		'path traversal string returned from cache verbatim');

	# Inner object bears sole responsibility for rejecting traversal paths.
	like($PATH_TRAVERSAL, qr/\.\./,
		'sanity: the path does contain .. traversal sequences (the test is valid)');
};

# ===========================================================================
# VECTOR 6 -- Cache Key Collision via '::' in CGI Arguments
#
# Exploit: CSRC builds cache keys by joining defined arguments with '::'.
# A CGI parameter value containing '::' (e.g. a namespace-qualified string)
# makes two distinct argument lists produce the same key:
#   echo('a::b')     => key ...::echo::a::b
#   echo('a', 'b')   => key ...::echo::a::b  (identical!)
# An attacker who controls a CGI parameter can poison a cache slot intended
# for a different argument combination, causing the wrong cached result to be
# served to other users.
#
# This is a documented LIMITATIONS entry.  The test makes the collision
# explicit and visible; a fix would require a collision-resistant serializer
# (e.g. JSON or URI-encoded arg list) as the cache key.
# ===========================================================================
subtest 'key collision: :: in CGI arg produces same key as two-arg call' => sub {
	local %ENV = (%ENV, QUERY_STRING => 'q=a%3A%3Ab');    # URL-decoded: a::b

	my $cache  = {};
	my $object = $INNER_CLASS->new();
	my $cached = $WRAPPER_CLASS->new(cache => $cache, object => $object);

	# The single-arg call with 'a::b' stores the value under key ...::echo::a::b
	my $result_one_arg = $cached->echo('a::b');

	# A different logical call -- two args 'a' and 'b' -- hits the same key.
	# Premise:   join('::', 'a', 'b') = 'a::b' = join('::', 'a::b')
	# Conclusion: the two-arg call is a false hit against the one-arg entry.
	my $result_two_arg = $cached->echo('a', 'b');

	TODO: {
		local $TODO = 'DOCUMENTED LIMITATION: :: in args causes cache key collision (see LIMITATIONS in POD)';
		isnt($result_two_arg, $result_one_arg,
			'two distinct arg lists should not share a cache entry');
	}

	# Document the colliding key slot directly.
	my $collision_key = $WRAPPER_CLASS . '::echo::a::b';
	ok(exists $cache->{$collision_key},
		'both call forms share the single key slot ' . $collision_key);
};

# ===========================================================================
# VECTOR 7 -- UNDEF Sentinel Spoofing via Attacker-Controlled Return Value
#
# Exploit: CSRC uses the magic string
#   'Class::Simple::Readonly::Cached>UNDEF<'
# to represent a cached undef/empty-list result.  On a cache hit it checks
# whether the stored value is eq to that sentinel and, if so, returns undef.
# If an attacker can make the inner object (e.g. a DB-backed accessor) return
# exactly that string -- for example by storing it as a database record --
# subsequent cache hits for that key will silently return undef instead of the
# real value.  Any downstream code that treats undef as "not found" would be
# corrupted without any error.
#
# This is an undocumented bug.  The fix is to wrap the stored value in an
# opaque blessed object so the sentinel can never be confused with a real string.
# ===========================================================================
subtest 'UNDEF sentinel spoofing: attacker-controlled return value corrupts cache hit' => sub {
	my $cache  = {};
	my $object = $INNER_CLASS->new();
	my $cached = $WRAPPER_CLASS->new(cache => $cache, object => $object);

	# Miss path: the inner object returns exactly the sentinel string.
	# This simulates a data source (e.g. a DB row) whose content was set by
	# an attacker to equal the sentinel.
	my $first = $cached->echo($UNDEF_SENTINEL);
	is($first, $UNDEF_SENTINEL,
		'first call (miss): inner object returns sentinel string -- value received correctly');

	# Hit path: the sentinel is now stored in the cache.  The hit-branch code
	# checks ($cached_val eq $UNDEF_SENTINEL) and returns undef.  This silently
	# corrupts the cached result: the real string is dropped.
	my $second = $cached->echo($UNDEF_SENTINEL);

	TODO: {
		local $TODO = 'BUG: UNDEF_SENTINEL spoofing -- hit path returns undef when inner object returned the sentinel string (use an opaque blessed wrapper to fix)';
		is($second, $UNDEF_SENTINEL,
			'second call (hit): sentinel string should be returned unchanged, not coerced to undef');
	}
};

# ===========================================================================
# VECTOR 8 -- Cache Flooding DoS via Unique CGI Arguments
#
# Exploit: every unique argument combination produces a new cache entry.
# A CGI attacker who controls a method argument (e.g. a search query) can
# send FLOOD_N unique values, causing FLOOD_N unique entries.  For a hash-ref
# backend this grows process memory without bound; for a file-based CHI cache
# it exhausts disk space.  CSRC imposes no per-instance or global entry limit.
# The application layer must rate-limit CGI inputs or cap the argument value
# space before passing them to a cached method.
# ===========================================================================
subtest 'cache flooding DoS: each unique CGI arg creates a new cache entry' => sub {
	my $cache   = {};
	my $object  = $INNER_CLASS->new();
	my $cached  = $WRAPPER_CLASS->new(cache => $cache, object => $object);

	$cached->echo("payload_$_") for 1 .. $FLOOD_N;

	cmp_ok(scalar(keys %{$cache}), '==', $FLOOD_N,
		"$FLOOD_N unique CGI params create $FLOOD_N distinct cache entries (no eviction or limit)");
};

# ===========================================================================
# VECTOR 9 -- Oversized CGI Argument (Memory/Disk DoS via large cache key)
#
# Exploit: HTTP does not mandate a query-string length limit; some servers pass
# arbitrarily long values to CGI scripts.  A 64 KiB argument becomes a 64 KiB+
# cache key.  The hash backend stores this as an unbounded Perl scalar; a file
# backend would write a 64 KiB filename.  The module must not crash, but the
# application must enforce a maximum argument length before this layer.
# ===========================================================================
subtest 'oversized CGI argument: 64 KiB arg stored intact, no crash' => sub {
	my $large_arg = 'A' x $LARGE_ARG_LEN;
	my $cached    = _wrapped();

	my $result = $cached->echo($large_arg);
	is(length($result // ''), $LARGE_ARG_LEN,
		'64 KiB argument stored and returned intact (CSRC imposes no length limit)');
};

# ===========================================================================
# VECTOR 10 -- Invalid 'cache' Supplied from CGI Input
#
# Exploit: a CGI script that naively constructs the wrapper from user-supplied
# parameters might pass $ENV{QUERY_STRING} directly as the cache argument.
# new() MUST croak immediately rather than bless a scalar string into the
# wrapper and later cause a cryptic "Can't call method" death.
# ===========================================================================
subtest 'invalid cache (CGI scalar): croak with clear message' => sub {
	local %ENV = (%ENV, QUERY_STRING => 'cache=memcached_host:11211');

	# Simulate: developer naively passes a CGI param as the cache backend.
	# throws_ok captures the full Carp message including " at file line N.",
	# so we match a substring rather than anchoring with \z.
	throws_ok {
		$WRAPPER_CLASS->new(
			cache  => $ENV{QUERY_STRING},
			object => $INNER_CLASS->new(),
		)
	} qr/Cache must be ref to HASH or object/,
		'scalar cache from CGI QUERY_STRING croaks with the expected message';

	# An array ref (another non-HASH, non-object ref) is equally rejected.
	throws_ok {
		$WRAPPER_CLASS->new(
			cache  => [],
			object => $INNER_CLASS->new(),
		)
	} qr/Cache must be ref to HASH or object/,
		'arrayref cache (non-HASH ref) croaks at the same boundary';
};

# ===========================================================================
# VECTOR 11 -- Invalid 'object' Supplied from CGI Input
#
# Exploit: if a CGI script passes a plain string (e.g. a class name from
# $ENV{HTTP_HOST} or a user-supplied value) as the object argument, new() must
# emit a carp warning and return undef rather than attempting to call methods
# on a string -- which would die with "Can't locate object method".
# ===========================================================================
subtest 'invalid object (CGI scalar): carp warning and undef return' => sub {
	local %ENV = (%ENV, HTTP_HOST => 'example.com; rm -rf /');

	my $result;
	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		$result = $WRAPPER_CLASS->new(
			cache  => {},
			object => $ENV{HTTP_HOST},
		);
	}

	is($result, undef,
		'scalar object from HTTP_HOST returns undef -- no wrapper created');
	ok(scalar(@warnings) > 0 && $warnings[0] =~ /must be a reference/,
		'carp warning mentions "must be a reference"');
};

# ===========================================================================
# VECTOR 12 -- Undef Argument Collapse (Parameter-Omission Attack)
#
# Exploit: undefined CGI parameters (e.g. optional fields absent from
# QUERY_STRING) are dropped from the cache key:
#   foo(undef) and foo() both produce key ...::foo::
# If an authenticated call uses undef as a meaningful sentinel parameter
# and an unauthenticated caller simply omits the parameter, they receive
# the same cached result -- a cross-user data access without any error.
# This is a documented limitation; validate and reject undef arguments at
# the application layer before they reach the cached method.
# ===========================================================================
subtest 'undef arg collapse: foo(undef) and foo() share the same cache slot' => sub {
	local %ENV = (%ENV, QUERY_STRING => '');    # no query params -- undef args

	my $cache  = {};
	my $object = $INNER_CLASS->new();
	my $cached = $WRAPPER_CLASS->new(cache => $cache, object => $object);

	# Prime the cache with an undef argument.
	$cached->echo(undef);

	# The zero-arg key (no defined args appended).
	my $collapsed_key = $WRAPPER_CLASS . '::echo::';

	ok(exists $cache->{$collapsed_key},
		'undef arg collapses: key is ...::echo:: (same as the zero-arg key)');

	# Now call with NO argument at all -- should be a false hit.
	$cached->echo();

	my $state = $cached->state();

	TODO: {
		local $TODO = 'DOCUMENTED LIMITATION: foo(undef) and foo() share the same cache entry (see LIMITATIONS in POD)';
		is($state->{misses}{$collapsed_key}, 1,
			'foo() should be a miss when only foo(undef) has been called');
	}
};

# ===========================================================================
# VECTOR 13 -- can() with Hostile Method Name from CGI Input
#
# Exploit: a CGI introspection endpoint might call
#   $cached->can($ENV{QUERY_STRING})
# A hostile method name containing shell chars, XSS, or path segments must not
# be executed -- can() delegates to UNIVERSAL::can which does a simple symbol-
# table lookup, returning undef for any name not defined in the package.
# No eval, no exec, no dynamic dispatch occurs inside can().
# ===========================================================================
subtest 'can() with hostile CGI method names returns undef without side effects' => sub {
	local %ENV = (%ENV, QUERY_STRING => "method=$CMD_INJECT");

	my $cached = _wrapped();

	is($cached->can($CMD_INJECT), undef,
		'can() with shell-injection method name returns undef (no code executed)');
	is($cached->can($XSS_PAYLOAD), undef,
		'can() with XSS method name returns undef');
	is($cached->can($PATH_TRAVERSAL), undef,
		'can() with path-traversal method name returns undef');

	# Sanity: can() on a real method still returns a coderef.
	returns_is($cached->can('new'), { type => 'coderef' },
		'can("new") returns a coderef (positive control)');
};

# ===========================================================================
# VECTOR 14 -- isa() with Hostile Class Name from CGI Input
#
# Exploit: same pattern as can() -- a hostile class name string passed to
# isa() must not trigger eval, file I/O, or AUTOLOAD on the inner object.
# isa() compares with eq/SUPER::isa only.
# ===========================================================================
subtest 'isa() with hostile CGI class names returns false without side effects' => sub {
	local %ENV = (%ENV, HTTP_USER_AGENT => 'EVIL/1.0');

	my $cached = _wrapped();

	ok(!$cached->isa($CMD_INJECT),
		'isa() with shell-injection class name returns false (no code executed)');
	ok(!$cached->isa($XSS_PAYLOAD),
		'isa() with XSS class name returns false');
	ok(!$cached->isa($PATH_TRAVERSAL),
		'isa() with path-traversal class name returns false');

	# Sanity: isa() on the real class name still returns true.
	ok($cached->isa($WRAPPER_CLASS),
		'isa() for the actual wrapper class returns true (positive control)');
};

# ===========================================================================
# VECTOR 15 -- Clone Path: _hits/_misses Stats Bleed Between Requests
#
# Exploit: calling $wrapper->new() (object invocation) shallow-copies all
# hash fields from the original, including the _hits and _misses hash refs.
# The clone and the original share the SAME stats hashes, so a hit or miss
# recorded through one is immediately visible in the other's state().
#
# Under mod_perl or Plack (persistent-process CGI), if two concurrent or
# sequential requests each obtain a clone of the same long-lived wrapper,
# their hit/miss statistics bleed into each other -- an information leak that
# could corrupt rate-limiting, quota enforcement, or observability dashboards.
# ===========================================================================
subtest 'clone stats bleed: _misses hash is shared between original and clone' => sub {
	my $original = _wrapped();

	# Prime the original with one miss.
	$original->echo('x');

	# Clone with no cache override -- _misses ref is inherited.
	my $clone = $original->new();

	# Record a miss through the clone.
	$clone->echo('y');

	my $orig_state  = $original->state();
	my $clone_state = $clone->state();

	TODO: {
		local $TODO = 'DESIGN ISSUE: clone shallow-copies _misses ref; stats from clone are visible in original (use deep copy or fresh stats in clone path)';

		# Original should only know about its own 'x' miss.
		is($orig_state->{misses}{ $WRAPPER_CLASS . '::echo::y' }, undef,
			"original's misses must not include the clone's echo('y') miss");

		# Clone should only know about its own 'y' miss.
		is($clone_state->{misses}{ $WRAPPER_CLASS . '::echo::x' }, undef,
			"clone's misses must not include the original's echo('x') miss");
	}
};

# ===========================================================================
# VECTOR 16 -- CHI Backend: UNDEF Sentinel Spoofing
#
# Same exploit as Vector 7 exercised over the CHI dispatch path.  The CHI
# _get/_set closures follow the same hit-branch logic as the hash backend,
# so the spoofing is equally reachable.
# ===========================================================================
subtest 'CHI backend: UNDEF sentinel spoofing corrupts the hit path' => sub {
	my $chi_cache;
	eval { require CHI; $chi_cache = CHI->new(driver => 'RawMemory', datastore => {}) };
	if($@) {
		plan(skip_all => 'CHI required for this test');
		return;
	}

	my $object = $INNER_CLASS->new();
	my $cached = $WRAPPER_CLASS->new(cache => $chi_cache, object => $object);

	my $first = $cached->echo($UNDEF_SENTINEL);
	is($first, $UNDEF_SENTINEL,
		'CHI miss: inner object returns sentinel string verbatim');

	my $second = $cached->echo($UNDEF_SENTINEL);

	TODO: {
		local $TODO = 'BUG (CHI path): UNDEF_SENTINEL spoofing -- hit returns undef instead of the real sentinel string';
		is($second, $UNDEF_SENTINEL,
			'CHI hit: sentinel string should survive the hit path unchanged');
	}
};

# ===========================================================================
# VECTOR 17 -- CHI Backend: Cache Key Collision via '::' in CGI Argument
#
# Same exploit as Vector 6 exercised over the CHI dispatch path.
# ===========================================================================
subtest 'CHI backend: :: in CGI arg causes cache key collision' => sub {
	my $chi_cache;
	eval { require CHI; $chi_cache = CHI->new(driver => 'RawMemory', datastore => {}) };
	if($@) {
		plan(skip_all => 'CHI required for this test');
		return;
	}

	local %ENV = (%ENV, QUERY_STRING => 'q=a%3A%3Ab');

	my $object = $INNER_CLASS->new();
	my $cached = $WRAPPER_CLASS->new(cache => $chi_cache, object => $object);

	$cached->echo('a::b');           # prime under single-arg key
	my $state_after_prime = $cached->state();
	is($state_after_prime->{misses}{ $WRAPPER_CLASS . '::echo::a::b' }, 1,
		'CHI: first call (a::b) is a miss, as expected');

	$cached->echo('a', 'b');         # same key via two-arg join

	my $state_after_collision = $cached->state();

	TODO: {
		local $TODO = 'DOCUMENTED LIMITATION (CHI path): :: collision -- two-arg call is a false hit against the one-arg slot';
		is($state_after_collision->{misses}{ $WRAPPER_CLASS . '::echo::a::b' }, 1,
			'CHI: two-arg ("a","b") call should be a miss (separate logical arguments)');
	}
};

# ===========================================================================
# VECTOR 18 -- state() Return Type Under Hostile Conditions
#
# state() must always return a hashref, even after hostile inputs have been
# cycled through the cache, so observability and rate-limiting code that
# depends on it cannot be crashed by an attacker.
# ===========================================================================
subtest 'state() returns a hashref regardless of hostile input content' => sub {
	my $cached = _wrapped();

	# Cycle through all hostile payloads as method arguments.
	for my $payload ($XSS_PAYLOAD, $CRLF_PAYLOAD, $CMD_INJECT, $PATH_TRAVERSAL) {
		$cached->echo($payload);
	}

	returns_is($cached->state(), { type => 'hashref' },
		'state() returns a hashref after hostile inputs have been processed');

	my $s = $cached->state();
	ok(exists $s->{hits},   'state() hash has a "hits" key');
	ok(exists $s->{misses}, 'state() hash has a "misses" key');
};

done_testing();
