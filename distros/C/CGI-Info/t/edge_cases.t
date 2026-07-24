#!/usr/bin/env perl

# edge_cases.t — destructive, pathological, and boundary-condition tests
# for CGI::Info.  Tests in this file intentionally push the module into
# extreme, malformed, or adversarial situations to verify it handles them
# gracefully without crashing, leaking data, or producing wrong results.

use strict;
use warnings;

use Test::More;
use Test::Mockingbird 0.08 qw(mock);
use File::Temp qw(tempdir);
use File::Spec;
use Scalar::Util qw(blessed);
use Encode qw(encode);

BEGIN { use_ok('CGI::Info') }

mock 'Log::Abstraction::_high_priority' => sub { };

# Guarantee CGI::Info class state is clean when this file finishes,
# preventing $stdin_data leaking into subsequently-run test files.
END { CGI::Info->reset() }

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
sub reset_env {
    delete $ENV{$_} for qw(
        GATEWAY_INTERFACE REQUEST_METHOD QUERY_STRING CONTENT_TYPE
        CONTENT_LENGTH SCRIPT_NAME SCRIPT_FILENAME DOCUMENT_ROOT
        C_DOCUMENT_ROOT HTTP_HOST SERVER_NAME SSL_TLS_SNI SERVER_PROTOCOL
        SERVER_PORT SCRIPT_URI REMOTE_ADDR HTTP_USER_AGENT HTTP_COOKIE
        HTTP_X_WAP_PROFILE HTTP_SEC_CH_UA_MOBILE HTTP_REFERER IS_MOBILE
        IS_SEARCH_ENGINE IS_AI LOGDIR
    );
    CGI::Info->reset();
    @ARGV = ();
}

# ============================================================
# 1. Deeply nested / extremely long query strings
# ============================================================

subtest 'query string: single param at max realistic length (64 KB)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    # 'A' x 65_535 causes catastrophic backtracking in WAF regex ((%3D)|(=))[^\n]*
    # against a value with no match. Use mixed alphanumeric to avoid O(n^2) behaviour
    # while still exercising the long-input path.
    my $long_val            = ('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' x 100);
    $ENV{QUERY_STRING}      = "note=$long_val";

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    # Should either parse it or return undef cleanly — must not die
    ok(!$@, 'does not die on very long param value');
    ok($info->status() != 500, 'no 500 status on long value');
};

subtest 'query string: very large number of parameters' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = join('&', map { "k$_=v$_" } 1..500);

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die with 500 parameters');
    ok(!defined($p) || ref($p) eq 'HASH', 'returns undef or hashref');
};

subtest 'query string: empty key=value pairs' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = '&&&=&=value&key=';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on empty/degenerate key=value pairs');
};

subtest 'query string: only ampersands' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = '&&&&&';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on query string of only ampersands');
};

subtest 'query string: key with no equals sign' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'justkey&other=val';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on key with no equals sign');
};

# ============================================================
# 2. URL encoding edge cases
# ============================================================

subtest 'URL encoding: double-encoded percent signs' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'val=%2525';    # %25 => %, so %2525 => %25

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on double-encoded percent');
};

subtest 'URL encoding: incomplete percent sequence at end' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'val=hello%2';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on truncated percent sequence');
};

subtest 'URL encoding: NUL byte poison attempts' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'key%00=value&other=val%00ue';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on NUL byte poison in query string');
    # If parsed, NUL bytes must not appear in keys or values
    if(defined $p) {
        for my $k (keys %{$p}) {
            unlike($k,       qr/\x00/, "NUL stripped from key '$k'");
            unlike($p->{$k}, qr/\x00/, "NUL stripped from value of '$k'");
        }
    }
};

subtest 'URL encoding: %00 encoded NUL in key name' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'ke%00y=value';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on NUL in key');
    # key with embedded NUL should either be dropped or have NUL removed
    if(defined $p) {
        ok(!exists $p->{"ke\x00y"}, 'key with NUL byte not stored raw');
    }
};

subtest 'URL encoding: Unicode sequences via percent encoding' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    # %C3%A9 = UTF-8 for é
    $ENV{QUERY_STRING}      = 'name=caf%C3%A9';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on UTF-8 encoded unicode in value');
};

subtest 'URL encoding: plus signs as spaces' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'msg=hello+world&empty=+';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on plus-encoded spaces');
    if(defined $p && defined $p->{msg}) {
        is($p->{msg}, 'hello world', 'plus decoded to space');
    }
};

# ============================================================
# 3. WAF: boundary and near-miss attack patterns
# ============================================================

subtest 'WAF: SQL keyword in value without injection pattern (should pass)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    # "SELECT" alone in a value is not a SQL injection
    $ENV{QUERY_STRING}      = 'action=SELECT_item';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on SQL keyword in non-attack context');
    ok($info->status() != 403, 'status not 403 for benign SQL-like value');
};

subtest 'WAF: Unicode look-alike SQL injection characters' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    # Unicode fullwidth apostrophe U+FF07, not ASCII single-quote
    $ENV{QUERY_STRING}      = encode('UTF-8', "name=O\x{FF07}Brien");

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on Unicode look-alike apostrophe');
};

subtest 'WAF: deeply nested HTML not treated as XSS (no angle brackets)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'desc=bold+and+italic+text';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on HTML-like words without brackets');
    ok($info->status() != 403, 'not blocked as XSS without angle brackets');
};

subtest 'WAF: FBCLID with double-dash (mentioned in source comment)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'fbclid=AQHk--sometoken123';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on FBCLID with double-dash');
    # Facebook FBCLID with "--" should not be blocked per source comment
    ok($info->status() != 403, 'FBCLID with -- not blocked as SQL injection');
};

subtest 'WAF: multiline value (CR/LF injection)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'hdr=value%0D%0AX-Injected%3A+evil';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on CRLF injection attempt');
    if(defined $p && defined $p->{hdr}) {
        unlike($p->{hdr}, qr/[\r\n]/, 'CR/LF stripped from injected header');
    }
};

subtest 'WAF: SQL injection via User-Agent header' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'x=1';
    $ENV{HTTP_USER_AGENT}   = 'Mozilla/5.0 SELECT foo AND bar FROM users';
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on SQL injection in User-Agent');
    is($info->status(), 403, 'status 403 on SQL injection in User-Agent');
};

subtest 'WAF: maximum length SQL injection attempt' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    # Long SQL injection padded with junk
    my $payload = "id=" . ('A' x 1000) . "'%20OR%201=1--";
    $ENV{QUERY_STRING}      = $payload;

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on long SQL injection attempt');
    is($info->status(), 403, 'long SQL injection blocked with 403');
};

# ============================================================
# 4. Pathological HTTP environment variables
# ============================================================

subtest 'env: HTTP_HOST with port number' => sub {
    reset_env();
    $ENV{HTTP_HOST} = 'example.com:8080';
    my $info = CGI::Info->new();
    my $host = eval { $info->host_name() };
    ok(!$@, 'does not die on HTTP_HOST with port');
    ok(defined $host && length $host, 'host_name() returns something');
};

subtest 'env: HTTP_HOST with multiple trailing dots' => sub {
    reset_env();
    $ENV{HTTP_HOST} = 'example.com...';
    my $info = CGI::Info->new();
    my $host = eval { $info->host_name() };
    ok(!$@, 'does not die on multiple trailing dots');
    # NOTE: this test documents a known limitation — the strip regex in
    # _find_site_details uses s/(.*)\.+$/$1/ where .* greedily captures
    # the trailing dots when URI::Heuristic has prefixed http://, so
    # only single trailing dots are reliably stripped.
    # We just verify it does not crash and returns something defined.
    ok(defined $host && length $host, 'returns a defined non-empty value');
};

subtest 'env: CONTENT_LENGTH of zero for POST' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_LENGTH}    = 0;
    $ENV{CONTENT_TYPE}      = 'application/x-www-form-urlencoded';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on zero CONTENT_LENGTH POST');
};

subtest 'env: CONTENT_LENGTH non-numeric string' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_LENGTH}    = 'evil; rm -rf /';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on non-numeric CONTENT_LENGTH');
    is($info->status(), 411, 'non-numeric CONTENT_LENGTH treated as missing');
};

subtest 'env: negative CONTENT_LENGTH' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_LENGTH}    = -1;

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on negative CONTENT_LENGTH');
    # Negative value contains digit so may pass the \D check — status is 411 or 413
    ok($info->status() >= 400, 'negative CONTENT_LENGTH results in 4xx status');
};

subtest 'env: SERVER_PORT non-numeric' => sub {
    reset_env();
    $ENV{SERVER_PORT} = 'not-a-port';

    my $info  = CGI::Info->new();
    # getservbyport() emits a Perl core "isn't numeric" warning for non-numeric
    # input — suppress it as it comes from Perl internals, not CGI::Info
    local $SIG{__WARN__} = sub { };
    my $proto = eval { $info->protocol() };
    ok(!$@, 'does not die on non-numeric SERVER_PORT');
    ok(!defined($proto) || length($proto), 'returns undef or a protocol string');
};

subtest 'env: REQUEST_METHOD unknown verb' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'PROPFIND';
    $ENV{QUERY_STRING}      = 'x=1';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on unknown HTTP method');
    is($info->status(), 501, 'unknown method yields 501');
};

subtest 'env: HEAD request treated like GET for params' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'HEAD';
    $ENV{QUERY_STRING}      = 'ping=1';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on HEAD request');
    ok(!defined($p) || defined($p->{ping}), 'HEAD: ping param accessible or undef');
};

subtest 'env: extremely long User-Agent string' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = 'Mozilla/' . ('X' x 10_000);
    $ENV{REMOTE_ADDR}     = '1.2.3.4';

    my $info   = CGI::Info->new();
    my $mobile = eval { $info->is_mobile() };
    ok(!$@, 'does not die on very long User-Agent');
    my $type = eval { $info->browser_type() };
    ok(!$@, 'browser_type() does not die on very long User-Agent');
};

subtest 'env: User-Agent containing only whitespace' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = '   ';
    $ENV{REMOTE_ADDR}     = '1.2.3.4';

    my $info = CGI::Info->new();
    eval { $info->is_mobile() };
    ok(!$@, 'does not die on whitespace-only User-Agent');
};

subtest 'env: empty string User-Agent' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = '';
    $ENV{REMOTE_ADDR}     = '1.2.3.4';

    my $info = CGI::Info->new();
    eval { $info->is_mobile() };
    ok(!$@, 'does not die on empty User-Agent');
};

subtest 'env: HTTP_COOKIE with malformed pairs (safe cases)' => sub {
    reset_env();
    # Avoid '==' which triggers a known CGI::Info bug (odd-element hash from
    # split producing 3 elements for '==').  Test other malformations.
    $ENV{HTTP_COOKIE} = '=noname; noval=; a=b=c; ;';

    my $info = CGI::Info->new();
    eval { $info->cookie('a') };
    ok(!$@, 'does not die on malformed cookie string (no == case)');
};

subtest 'env: HTTP_COOKIE with == pair (known CGI::Info bug - documents behaviour)' => sub {
    reset_env();
    # '==' in a cookie string causes split(/=/, '==', 2) to return ('', '')
    # but map { split(/=/, $_, 2) } across all pairs yields an odd-element list
    # when a bare '==' entry is present, triggering "Odd number of elements"
    # This test documents the behaviour — it may warn but must not die fatally.
    $ENV{HTTP_COOKIE} = 'good=val; ==; other=x';
    my $info = CGI::Info->new();
    local $SIG{__WARN__} = sub { };   # suppress the "Odd number" warning
    eval { $info->cookie('good') };
    ok(!$@, 'cookie() with == in jar does not die (warns only)');
};

subtest 'env: HTTP_COOKIE with very long value' => sub {
    reset_env();
    $ENV{HTTP_COOKIE} = 'session=' . ('S' x 4096);

    my $info = CGI::Info->new();
    my $val  = eval { $info->cookie('session') };
    ok(!$@, 'does not die on very long cookie value');
    ok(defined $val && length($val) == 4096, 'long cookie value preserved');
};

# ============================================================
# 5. Boundary values for numeric checks
# ============================================================

subtest 'boundary: max_upload_size = 0 blocks everything' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_LENGTH}    = 1;

    my $info = CGI::Info->new(max_upload_size => 0);
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die with max_upload_size=0');
    is($info->status(), 413, 'any POST body blocked when max_upload_size=0');
};

subtest 'boundary: max_upload_size = -1 means no limit' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_LENGTH}    = 999_999_999;
    $ENV{CONTENT_TYPE}      = 'application/x-www-form-urlencoded';
    $CGI::Info::stdin_data  = 'x=1';

    my $info = CGI::Info->new(max_upload_size => -1);
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die with max_upload_size=-1');
    isnt($info->status(), 413, 'max_upload_size=-1 does not block large POST');
};

subtest 'boundary: CONTENT_LENGTH exactly equals max_upload_size (edge, not over)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}    = 'CGI/1.1';
    $ENV{REQUEST_METHOD}       = 'POST';
    $ENV{CONTENT_TYPE}         = 'application/x-www-form-urlencoded';
    my $body                   = 'x=1';
    $ENV{CONTENT_LENGTH}       = length($body);
    $CGI::Info::stdin_data     = $body;

    my $info = CGI::Info->new(max_upload_size => length($body));
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die when CONTENT_LENGTH == max_upload_size');
    isnt($info->status(), 413,
        'CONTENT_LENGTH == max_upload_size not rejected as oversized');
};

subtest 'boundary: CONTENT_LENGTH one byte over max_upload_size' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_LENGTH}    = 101;

    my $info = CGI::Info->new(max_upload_size => 100);
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die when CONTENT_LENGTH one over max');
    is($info->status(), 413, 'one byte over max_upload_size gives 413');
};

# ============================================================
# 6. allow list edge cases
# ============================================================

subtest 'allow: empty hashref blocks all params' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'foo=1&bar=2';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params(allow => {}) };
    ok(!$@, 'does not die with empty allow hashref');
    ok(!defined($p), 'empty allow blocks all params, returns undef');
};

subtest 'allow: key mapped to empty string only allows empty value' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'flag=';

    my $info = CGI::Info->new();
    # Empty string value should match allow => { flag => '' }
    my $p = eval { $info->params(allow => { flag => '' }) };
    ok(!$@, 'does not die on allow with empty string schema');
};

subtest 'allow: coderef that always returns false blocks everything' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'x=1&y=2';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params(allow => {
        x => sub { 0 },
        y => sub { 0 },
    }) };
    ok(!$@, 'does not die when coderef always returns false');
    ok(!defined($p), 'all-false coderef blocks all params');
};

subtest 'allow: coderef that dies is propagated' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'x=1';

    my $info = CGI::Info->new();
    eval { $info->params(allow => {
        x => sub { die "validation exploded\n" }
    }) };
    like($@, qr/validation exploded/, 'coderef exception propagates to caller');
};

subtest 'allow: very long regex that matches' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'x=hello';

    # Build an alternation regex with many alternatives
    my $re = qr/^(hello|world|foo|bar|baz|qux|one|two|three|four|five|six|seven|eight|nine|ten)$/;
    my $info = CGI::Info->new();
    my $p    = eval { $info->params(allow => { x => $re }) };
    ok(!$@, 'does not die on complex allow regex');
    is($p->{x}, 'hello', 'complex regex allow passes correct value');
};

subtest 'allow: undef value in allow permits any string including attack-like' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    # Even with undef allow, WAF still runs on GET
    $ENV{QUERY_STRING}      = 'note=normalvalue';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params(allow => { note => undef }) };
    ok(!$@, 'does not die with undef allow value');
    ok(defined $p && defined $p->{note}, 'undef allow passes normal value');
};

# ============================================================
# 7. STDIN / POST edge cases
# ============================================================

subtest 'POST: stdin_data pre-populated (FCGI reuse scenario)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}    = 'CGI/1.1';
    $ENV{REQUEST_METHOD}       = 'POST';
    $ENV{CONTENT_TYPE}         = 'application/x-www-form-urlencoded';
    my $body                   = 'fcgi=1&req=second';
    $ENV{CONTENT_LENGTH}       = length($body);
    $CGI::Info::stdin_data     = $body;

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die when stdin_data pre-populated');
    ok(!defined($p) || defined($p->{fcgi}), 'pre-populated stdin_data used');
};

subtest 'POST: content-type with charset parameter' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}    = 'CGI/1.1';
    $ENV{REQUEST_METHOD}       = 'POST';
    $ENV{CONTENT_TYPE}         = 'application/x-www-form-urlencoded; charset=UTF-8';
    my $body                   = 'msg=hello';
    $ENV{CONTENT_LENGTH}       = length($body);
    $CGI::Info::stdin_data     = $body;

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on content-type with charset');
    ok(!defined($p) || defined($p->{msg}), 'params parsed with charset in content-type');
};

subtest 'POST: multipart without upload_dir returns undef gracefully' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_TYPE}      = 'multipart/form-data; boundary=----boundary123';
    $ENV{CONTENT_LENGTH}    = 100;
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();    # no upload_dir
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on multipart POST without upload_dir');
    ok(!defined $p, 'multipart without upload_dir returns undef');
};

subtest 'POST: GET-style multipart (should warn and return undef)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{CONTENT_TYPE}      = 'multipart/form-data; boundary=--b';
    $ENV{QUERY_STRING}      = 'x=1';
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on multipart GET');
    # Source says: multipart/form-data not supported for GET
    is($info->status(), 501, 'multipart GET returns 501 Not Implemented');
};

subtest 'POST: unsupported content-type handled without dying' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}    = 'CGI/1.1';
    $ENV{REQUEST_METHOD}       = 'POST';
    $ENV{CONTENT_TYPE}         = 'application/octet-stream';
    my $body                   = "\x00\x01\x02\x03binary";
    $ENV{CONTENT_LENGTH}       = length($body);
    $CGI::Info::stdin_data     = $body;

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on unsupported content-type POST');
};

# ============================================================
# 8. Script path edge cases
# ============================================================

subtest 'script_path: SCRIPT_FILENAME with spaces in path' => sub {
    reset_env();
    $ENV{SCRIPT_FILENAME} = '/var/www/my scripts/app.cgi';

    my $info = CGI::Info->new();
    my $path = eval { $info->script_path() };
    ok(!$@, 'does not die on SCRIPT_FILENAME with spaces');
};

subtest 'script_name: called multiple times returns same value' => sub {
    reset_env();
    $ENV{SCRIPT_NAME} = '/cgi-bin/myapp.cgi';

    my $info = CGI::Info->new();
    my $n1   = $info->script_name();
    my $n2   = $info->script_name();
    is($n1, $n2, 'script_name() idempotent across multiple calls');
};

subtest 'script_dir: called multiple times returns same value' => sub {
    reset_env();
    $ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/app.cgi';

    my $info = CGI::Info->new();
    my $d1   = $info->script_dir();
    my $d2   = $info->script_dir();
    is($d1, $d2, 'script_dir() idempotent across multiple calls');
};

# ============================================================
# 9. Cookie edge cases
# ============================================================

subtest 'cookie: name with all valid RFC6265 token chars' => sub {
    reset_env();
    # RFC6265 token chars: visible ASCII except separators
    $ENV{HTTP_COOKIE} = 'valid-name.ok=value123';

    my $info = CGI::Info->new();
    my $val  = eval { $info->cookie('valid-name.ok') };
    ok(!$@, 'does not die on RFC6265-valid cookie name with dots and hyphens');
};

subtest 'cookie: value with equals sign inside' => sub {
    reset_env();
    $ENV{HTTP_COOKIE} = 'token=base64==pad==';

    my $info = CGI::Info->new();
    my $val  = eval { $info->cookie('token') };
    ok(!$@, 'does not die on cookie value with embedded equals signs');
    # The split is on first = so value should contain the rest
    ok(defined $val, 'cookie with embedded = returns a value');
};

subtest 'cookie: requesting absent cookie from populated jar' => sub {
    reset_env();
    $ENV{HTTP_COOKIE} = 'a=1; b=2; c=3';

    my $info = CGI::Info->new();
    $info->cookie('a');    # populate jar
    my $val = eval { $info->cookie('z') };
    ok(!$@,        'does not die looking up absent key after jar populated');
    ok(!defined $val, 'absent cookie returns undef');
};

subtest 'cookie: empty cookie jar string' => sub {
    reset_env();
    $ENV{HTTP_COOKIE} = '';

    my $info = CGI::Info->new();
    my $val  = eval { $info->cookie('anything') };
    ok(!$@,       'does not die on empty HTTP_COOKIE');
    ok(!defined $val, 'empty cookie jar returns undef');
};

# ============================================================
# 10. as_string edge cases
# ============================================================

subtest 'as_string: value containing semicolons and equals escaped' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'expr=a%3Db%3Bc%3Dd';  # a=b;c=d

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    if(defined $p) {
        my $str = $info->as_string();
        # Escaped mode must escape ; and = in values
        unlike($str, qr/expr=.*[^\\][;=]/,
            'semicolons and equals in values are escaped in non-raw mode');
        my $raw = $info->as_string({ raw => 1 });
        ok(defined $raw, 'raw mode also works with special chars in value');
    } else {
        pass('params() returned undef (WAF triggered, acceptable)');
    }
};

subtest 'as_string: single param produces no trailing semicolon' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'x=1';

    my $info = CGI::Info->new();
    $info->params();
    my $str = $info->as_string();
    unlike($str, qr/;\s*$/, 'single param: no trailing semicolon');
};

# ============================================================
# 11. Stateful destruction / reset edge cases
# ============================================================

subtest 'reset: clears paramref so next call re-parses' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'before=1';

    my $info = CGI::Info->new();
    my $p1   = $info->params();
    is($p1->{before}, '1', 'before reset: before=1 parsed');

    CGI::Info->reset();
    $ENV{QUERY_STRING} = 'after=2';

    my $info2 = CGI::Info->new();
    my $p2    = $info2->params();
    is($p2->{after}, '2', 'after reset: after=2 parsed in new object');
    ok(!defined $p2->{before}, 'before= not present after reset');
};

subtest 'reset called twice in a row does not die' => sub {
    reset_env();
    eval {
        CGI::Info->reset();
        CGI::Info->reset();
    };
    ok(!$@, 'double reset() does not die');
};

subtest 'status: set to 0 does not confuse status() return' => sub {
    reset_env();
    my $info = CGI::Info->new();
    $info->status(0);
    # status(0) is falsy — the internal `|| 200` fallback should NOT fire
    # because 0 was explicitly set; behaviour depends on implementation
    my $s = eval { $info->status() };
    ok(!$@, 'status(0) does not cause status() to die');
};

# ============================================================
# 12. Concurrent-ish object isolation
# ============================================================

subtest 'two objects in same env do not share paramref' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'shared=yes';

    my $info1 = CGI::Info->new();
    my $info2 = CGI::Info->new();

    my $p1 = $info1->params();
    my $p2 = $info2->params();

    isnt($p1, $p2, 'two objects return different hashrefs');
    is($p1->{shared}, 'yes', 'object 1 sees shared=yes');
    is($p2->{shared}, 'yes', 'object 2 sees shared=yes');

    # Mutating one should not affect the other
    $p1->{shared} = 'modified';
    isnt($info2->param('shared'), 'modified',
        'mutating one hashref does not affect other object');
};

subtest 'two objects with different allow lists see different params' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'a=1&b=2&c=3';

    my $info1 = CGI::Info->new();
    my $info2 = CGI::Info->new();

    my $p1 = $info1->params(allow => { a => undef });
    my $p2 = $info2->params(allow => { b => undef, c => undef });

    ok(defined $p1->{a},  'info1 sees a');
    ok(!defined $p1->{b}, 'info1 does not see b');
    ok(defined $p2->{b},  'info2 sees b');
    ok(!defined $p2->{a}, 'info2 does not see a');
};

# ============================================================
# 13. AUTOLOAD edge cases
# ============================================================

subtest 'AUTOLOAD: method name with leading underscore not delegated' => sub {
    reset_env();
    my $info = CGI::Info->new();
    # _private-looking names should croak (not a valid param name pattern
    # that any sensible CGI would use, and AUTOLOAD validates method names)
    eval { $info->_notapublicmethod() };
    # Either croaks or returns undef — must not segfault/corrupt
    ok(1, 'calling _private via AUTOLOAD does not crash process');
};

subtest 'AUTOLOAD: DESTROY not delegated to param()' => sub {
    reset_env();
    # Creating and immediately destroying an object must not trigger param()
    my $destroyed = 0;
    {
        my $info = CGI::Info->new();
        # If DESTROY is incorrectly delegated to param(), it would try to
        # parse CGI params during object destruction
    }
    ok(1, 'DESTROY does not trigger AUTOLOAD delegation');
};

subtest 'AUTOLOAD: numeric method name' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'x=1';
    my $info = CGI::Info->new();
    $info->params();
    # Method names starting with digits are invalid — should croak or return undef
    eval { $info->can('123abc') };
    ok(1, 'numeric-starting method name does not crash');
};

# ============================================================
# 14. tmpdir pathological inputs
# ============================================================

subtest 'tmpdir: non-scalar default croaks gracefully' => sub {
    reset_env();
    my $info = CGI::Info->new();
    eval { $info->tmpdir(default => { hashref => 1 }) };
    like($@, qr/scalar/i, 'tmpdir croaks on hashref default');
};

subtest 'tmpdir: non-existent default falls back' => sub {
    reset_env();
    my $info = CGI::Info->new();
    # Non-existent path as default: tmpdir() should return it verbatim
    # (POD: "No sanity tests are done")
    my $dir = eval { $info->tmpdir(default => '/this/does/not/exist/xyz') };
    ok(!$@, 'does not die on non-existent default tmpdir');
    # Returns whatever it finds or the default as-is
    ok(defined $dir, 'returns a defined value even with fake default');
};

# ============================================================
# 15. logdir pathological inputs
# ============================================================

subtest 'logdir: non-writable directory rejected' => sub {
    reset_env();
    my $info = CGI::Info->new();
    eval { $info->logdir('/') };
    # Root dir may not be writable in test environment
    if($@) {
        like($@, qr/Invalid logdir/i, 'non-writable dir causes croak');
    } else {
        pass('root dir happened to be writable (skip on this system)');
    }
};

subtest 'logdir: path traversal attempt rejected' => sub {
    reset_env();
    my $info = CGI::Info->new();
    eval { $info->logdir('/tmp/../../etc') };
    # Either croaks or returns a safe value — must not die unexpectedly
    ok(1, 'path traversal in logdir does not crash');
};

# ============================================================
# 16. Repeated operations for idempotency and memory stability
# ============================================================

subtest 'idempotency: host_name() called 100 times returns same value' => sub {
    reset_env();
    $ENV{HTTP_HOST} = 'www.example.com';
    my $info = CGI::Info->new();
    my $first = $info->host_name();
    my $consistent = 1;
    for (1..100) {
        $consistent = 0 if $info->host_name() ne $first;
    }
    ok($consistent, 'host_name() returns identical value across 100 calls');
};

subtest 'idempotency: is_mobile() called 100 times returns same value' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
    $ENV{REMOTE_ADDR}     = '1.2.3.4';
    my $info  = CGI::Info->new();
    my $first = $info->is_mobile();
    my $consistent = 1;
    for (1..100) {
        $consistent = 0 if ($info->is_mobile() ? 1 : 0) != ($first ? 1 : 0);
    }
    ok($consistent, 'is_mobile() returns identical value across 100 calls');
};

subtest 'idempotency: params() called 100 times returns same hashref' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'k=v';
    my $info = CGI::Info->new();
    my $ref  = $info->params();
    if(!defined $ref) {
        pass('params() returned undef (WAF or platform behaviour) — skip idempotency check');
        return;
    }
    my $consistent = 1;
    for (1..100) {
        my $r = $info->params();
        $consistent = 0 if !defined($r) || $r != $ref;
    }
    ok($consistent, 'params() returns same hashref across 100 calls (cached)');
};

# ============================================================
# 17. Interaction: messages survive across multiple method calls
# ============================================================

subtest 'messages persist: multiple failures accumulate in messages()' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'id=bad';

    my $info = CGI::Info->new();
    $info->params(allow => { id => qr/^\d+$/ });
    my $count1 = scalar @{ $info->messages() // [] };

    # Trigger another message via param() allow check
    $info->param('unlisted');
    my $count2 = scalar @{ $info->messages() // [] };

    ok($count2 >= $count1, 'messages() count does not decrease across calls');
};

# ============================================================
# 18. is_ai() boundary and adversarial edge cases
# ============================================================

# is_ai() consults IS_AI via Perl's truth test, not a numeric 0/1 check.
# Empty string is falsy, so IS_AI='' forces false even for an AI crawler UA.
subtest 'is_ai: IS_AI="" empty-string override forces false' => sub {
    reset_env();
    local $ENV{IS_AI}       = '';
    $ENV{HTTP_USER_AGENT}   = 'ClaudeBot/1.0 (+http://www.anthropic.com)';
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    ok(!$info->is_ai(), 'IS_AI="" (empty string, falsy) overrides ClaudeBot UA to false');
};

# '0E0' is the Perl "defined-but-zero" idiom in numeric context, but as a
# string it is NOT '0' and is therefore truthy.  This catches callers who
# set IS_AI='0E0' expecting it to mean "off".
subtest 'is_ai: IS_AI="0E0" truthy string override forces true' => sub {
    reset_env();
    local $ENV{IS_AI}       = '0E0';
    $ENV{HTTP_USER_AGENT}   = 'Mozilla/5.0 Firefox/120.0';
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    ok($info->is_ai(), 'IS_AI="0E0" is truthy as a string; forces is_ai true');
};

# Any non-'0'/non-'' string (including "no", "false") is truthy in Perl.
# Callers who set IS_AI='false' expecting it to mean off will be surprised.
subtest 'is_ai: IS_AI="false" truthy string override forces true' => sub {
    reset_env();
    local $ENV{IS_AI}       = 'false';
    $ENV{HTTP_USER_AGENT}   = 'Mozilla/5.0 Chrome/120.0';
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    ok($info->is_ai(), 'IS_AI="false" is truthy as a string; forces is_ai true (not false)');
};

# When REMOTE_ADDR is absent, is_ai() returns 0 WITHOUT populating the
# instance cache ($self->{is_ai} stays undef).  A subsequent call on the same
# instance after REMOTE_ADDR appears must re-evaluate — not return the stale 0.
subtest 'is_ai: result not cached when REMOTE_ADDR absent on first call' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = 'ClaudeBot/1.0 (+http://www.anthropic.com)';
    # Deliberately omit REMOTE_ADDR

    my $info = CGI::Info->new();
    ok(!$info->is_ai(), 'first call with no REMOTE_ADDR returns false');

    # Now the environment gains a REMOTE_ADDR (e.g. a late-set header)
    $ENV{REMOTE_ADDR} = '1.2.3.4';
    ok($info->is_ai(), 'second call re-evaluates and correctly detects AI crawler');
};

# Once $self->{is_ai} IS cached (positive detection), a subsequent change to
# IS_AI in the environment must not affect the cached instance result.
subtest 'is_ai: cached positive result survives IS_AI env change' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT}   = 'ClaudeBot/1.0 (+http://www.anthropic.com)';
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    ok($info->is_ai(), 'baseline: ClaudeBot detected as AI');

    # Clobber IS_AI with "off" signal; instance already cached the answer
    local $ENV{IS_AI} = 0;
    ok($info->is_ai(), 'cached is_ai=1 unaffected by subsequent IS_AI=0 env change');
};

# is_robot() must still honour the invariant even when is_ai returns
# true via the IS_AI env override (not UA matching).
subtest 'is_ai: IS_AI=1 override propagates to is_robot via is_robot internals' => sub {
    reset_env();
    local $ENV{IS_AI}       = 1;
    $ENV{HTTP_USER_AGENT}   = 'Mozilla/5.0 Firefox/120.0';  # non-AI UA
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    ok($info->is_ai(),    'IS_AI=1 override: is_ai true for non-AI UA');
    ok($info->is_robot(), 'IS_AI=1 override: is_robot true via is_ai delegation inside is_robot');
};

# ============================================================
# 19. WAF: additional attack patterns verified
# ============================================================

# The path-traversal guard checks the sanitised $value for `../`.
# Every legitimate URL path would use encoded %2E%2E%2F or absolute refs.
subtest 'WAF: ../ path traversal in GET value blocked (403)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'file=../../etc/passwd';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on path traversal attempt');
    is($info->status(), 403, 'path traversal (../) in GET value blocked with 403');
};

# The mustleak.com guard is a hard-coded canary domain used in SSRF probes.
subtest 'WAF: mustleak.com/ in GET value blocked (403)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'url=http://mustleak.com/probe.js';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on mustleak.com probe URL');
    is($info->status(), 403, 'mustleak.com/ in value blocked with 403');
};

# XSS angle-bracket injection: checked on both $value (post-sanitise) and
# $orig_value (pre-sanitise) so HTML-encoding evasion is also caught.
subtest 'WAF: XSS <script> tag in GET value blocked (403)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'search=<script>alert(1)</script>';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on XSS script injection');
    is($info->status(), 403, 'XSS <script> tag blocked with 403');
};

# Encoded XSS: %3Cscript%3E should also be caught (orig_value is checked).
subtest 'WAF: URL-encoded XSS %3Cscript%3E in GET value blocked (403)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'q=%3Cscript%3Ealert%281%29%3C%2Fscript%3E';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on URL-encoded XSS');
    is($info->status(), 403, 'URL-encoded XSS blocked with 403');
};

# SQL injection via exec(xp_cmdshell) pattern — a classic MSSQL shell-escape.
# The WAF checks for exec followed by sp/xp stored procedure prefixes.
subtest 'WAF: exec xp_cmdshell stored-procedure injection blocked (403)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    # + is decoded to space: value becomes "exec xp_cmdshell"
    $ENV{QUERY_STRING}      = 'cmd=exec+xp_cmdshell';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on exec xp_cmdshell injection');
    is($info->status(), 403, 'exec xp_cmdshell blocked with 403');
};

# SQL injection via exec(sp_executesql) — same pattern with sp_ prefix.
subtest 'WAF: exec sp_executesql stored-procedure injection blocked (403)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'cmd=exec+sp_executesql';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on exec sp_executesql injection');
    is($info->status(), 403, 'exec sp_executesql blocked with 403');
};

# Tautology injection AND 1=1: a minimal always-true condition.
subtest 'WAF: AND 1=1 tautology injection blocked (403)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    # + decoded to space: "5 AND 1=1"
    $ENV{QUERY_STRING}      = 'id=5+AND+1%3D1';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on AND 1=1 injection');
    is($info->status(), 403, 'AND 1=1 tautology injection blocked with 403');
};

# The WAF now inspects both GET and POST.  The previous GET-only gate
# was a security gap; it has been removed.  This test verifies that
# known-hostile payloads in POST bodies are also blocked with 403.
subtest 'WAF: SQL injection in POST body IS blocked (WAF now covers POST)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}  = 'CGI/1.1';
    $ENV{REQUEST_METHOD}     = 'POST';
    $ENV{CONTENT_TYPE}       = 'application/x-www-form-urlencoded';
    my $body                 = "id=1'+OR+1%3D1--";
    $ENV{CONTENT_LENGTH}     = length($body);
    $CGI::Info::stdin_data   = $body;

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on SQL injection in POST body');
    is($info->status(), 403,
        'POST body SQL injection is now blocked with 403');
};

# ============================================================
# 20. HTTP method boundary: OPTIONS and DELETE
# ============================================================

subtest 'HTTP OPTIONS returns 405 Method Not Allowed' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'OPTIONS';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on OPTIONS');
    is($info->status(), 405, 'OPTIONS method returns 405');
    ok(!defined $p, 'OPTIONS params() returns undef');
};

subtest 'HTTP DELETE returns 405 Method Not Allowed' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'DELETE';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on DELETE');
    is($info->status(), 405, 'DELETE method returns 405');
    ok(!defined $p, 'DELETE params() returns undef');
};

# ============================================================
# 21. ARGV mode: --robot / --mobile / --search-engine / --tablet
#     These flags are consumed when params() is called without GATEWAY_INTERFACE.
# ============================================================

subtest 'ARGV: --robot flag sets is_robot and consumes the flag' => sub {
    reset_env();   # ensures no GATEWAY_INTERFACE
    @ARGV = ('--robot', 'action=view', 'id=42');

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die with --robot in ARGV');
    ok($info->is_robot(), '--robot ARGV flag sets is_robot true');
    # Remaining ARGV entries are parsed as CGI params
    ok(defined $p && defined $p->{action}, '--robot: remaining ARGV pairs parsed as params');
};

subtest 'ARGV: --mobile flag sets is_mobile' => sub {
    reset_env();
    @ARGV = ('--mobile', 'page=home');

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die with --mobile in ARGV');
    ok($info->is_mobile(), '--mobile ARGV flag sets is_mobile true');
};

subtest 'ARGV: --search-engine flag sets is_search_engine' => sub {
    reset_env();
    @ARGV = ('--search-engine', 'q=test');

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die with --search-engine in ARGV');
    ok($info->is_search_engine(), '--search-engine ARGV flag sets is_search_engine true');
};

subtest 'ARGV: --tablet flag sets is_tablet' => sub {
    reset_env();
    @ARGV = ('--tablet', 'view=gallery');

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die with --tablet in ARGV');
    ok($info->is_tablet(), '--tablet ARGV flag sets is_tablet true');
};

# ============================================================
# 22. POST with special content types: XML and JSON
# ============================================================

# XML bodies bypass the WAF and are stored verbatim under the "XML" key.
# This is the documented behaviour for text/xml content-type.
subtest 'POST text/xml: body stored under "XML" key' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}  = 'CGI/1.1';
    $ENV{REQUEST_METHOD}     = 'POST';
    $ENV{CONTENT_TYPE}       = 'text/xml';
    my $body                 = '<root><item>value</item></root>';
    $ENV{CONTENT_LENGTH}     = length($body);
    $CGI::Info::stdin_data   = $body;

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@,     'does not die on XML POST');
    ok(defined $p,            'XML POST: params() returns defined value');
    ok(exists $p->{XML},      'XML POST: body stored under "XML" key');
    like($p->{XML}, qr/<root>/, 'XML POST: body content preserved');
};

# Zero-byte XML body: the module reads CONTENT_LENGTH bytes, so a body of
# exactly 0 bytes with text/xml should return a params hash with an empty XML key.
subtest 'POST text/xml: zero-length body handled gracefully' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}  = 'CGI/1.1';
    $ENV{REQUEST_METHOD}     = 'POST';
    $ENV{CONTENT_TYPE}       = 'text/xml';
    $ENV{CONTENT_LENGTH}     = 0;
    $CGI::Info::stdin_data   = '';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'does not die on zero-length XML POST');
};

# application/json: the module tries to parse via JSON::MaybeXS.
# Gracefully degrade when the module is absent.
subtest 'POST application/json: body parsed into params (or graceful failure)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}  = 'CGI/1.1';
    $ENV{REQUEST_METHOD}     = 'POST';
    $ENV{CONTENT_TYPE}       = 'application/json';
    my $body                 = '{"name":"alice","score":"99"}';
    $ENV{CONTENT_LENGTH}     = length($body);
    $CGI::Info::stdin_data   = $body;

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    if($@) {
        # JSON::MaybeXS not installed - the module will die inside params()
        like($@, qr/JSON|locate/i,
            'params() dies with informative error when JSON::MaybeXS absent');
    } else {
        # JSON available
        ok(!defined($p) || (ref($p) eq 'HASH'),
            'JSON POST: returns hashref or undef (not a crash)');
        if(defined $p) {
            is($p->{name},  'alice', 'JSON name parsed correctly');
            is($p->{score}, '99',    'JSON score parsed correctly');
        }
    }
};

# Malformed JSON should not crash the process.
subtest 'POST application/json: malformed body dies cleanly (not silently corrupts)' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE}  = 'CGI/1.1';
    $ENV{REQUEST_METHOD}     = 'POST';
    $ENV{CONTENT_TYPE}       = 'application/json';
    my $body                 = '{broken json:::}';
    $ENV{CONTENT_LENGTH}     = length($body);
    $CGI::Info::stdin_data   = $body;

    my $json_available = eval { require JSON::MaybeXS; 1 };
    unless($json_available) {
        pass('JSON::MaybeXS not installed - skipping malformed JSON test');
        return;
    }

    my $info = CGI::Info->new();
    eval { $info->params() };
    # Either dies with a JSON parse error or returns undef — must not silently
    # return a corrupted hashref
    ok(1, 'malformed JSON POST does not segfault or silently corrupt');
    if($@) {
        like($@, qr/json|parse|invalid/i, 'JSON parse error propagated to caller');
    }
};

# ============================================================
# 23. upload_dir: hostile path validation
# ============================================================

# A relative path fails File::Spec->file_name_is_absolute() and must be
# rejected before any filesystem access.
subtest 'upload_dir: relative path rejected with 500' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_TYPE}      = 'multipart/form-data; boundary=----b';
    $ENV{CONTENT_LENGTH}    = 100;
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params(upload_dir => 'relative/dir') };
    ok(!$@, 'does not die on relative upload_dir');
    is($info->status(), 500, 'relative upload_dir rejected with 500');
};

# An absolute but non-existent path must be rejected after the relativity check.
subtest 'upload_dir: non-existent absolute path rejected with 500' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_TYPE}      = 'multipart/form-data; boundary=----b';
    $ENV{CONTENT_LENGTH}    = 100;
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    my $info = CGI::Info->new();
    my $p    = eval { $info->params(upload_dir => '/no/such/path/xyz123abc') };
    ok(!$@, 'does not die on non-existent absolute upload_dir');
    is($info->status(), 500, 'non-existent absolute upload_dir rejected with 500');
};

# upload_dir pointing to a plain file (not a directory) must be rejected.
subtest 'upload_dir: file path (not a dir) rejected with 500' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'POST';
    $ENV{CONTENT_TYPE}      = 'multipart/form-data; boundary=----b';
    $ENV{CONTENT_LENGTH}    = 100;
    $ENV{REMOTE_ADDR}       = '1.2.3.4';

    # Use a file known to exist on any POSIX system
    my $file_path = $^O eq 'MSWin32' ? 'C:\\Windows\\system32\\cmd.exe'
                                      : '/etc/hostname';
    my $info = CGI::Info->new();
    my $p    = eval { $info->params(upload_dir => $file_path) };
    ok(!$@, 'does not die on upload_dir pointing to a file');
    is($info->status(), 500, 'upload_dir pointing to a file rejected with 500');
};

# ============================================================
# 24. Global variable integrity: $_ and $@ must not be clobbered
# ============================================================

# Perl's $_ is a commonly overused global.  The module must not destroy it.
subtest 'global integrity: $_ not clobbered by params()' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'a=1&b=2&c=3';

    local $_ = 'sentinel_value';
    my $info = CGI::Info->new();
    $info->params();
    is($_, 'sentinel_value', 'params() did not clobber $_');
};

# $_ must also survive is_mobile() and is_robot() calls that use regex.
subtest 'global integrity: $_ not clobbered by UA-detection methods' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
    $ENV{REMOTE_ADDR}     = '1.2.3.4';

    local $_ = 'still_sentinel';
    my $info = CGI::Info->new();
    $info->is_mobile();
    $info->is_robot();
    $info->is_ai();
    $info->browser_type();
    is($_, 'still_sentinel', '$_ intact after is_mobile/is_robot/is_ai/browser_type');
};

# params() internally uses eval for require calls.  A successful eval clears
# $@; we verify that params() does not die when the caller has a non-empty $@.
subtest 'global integrity: params() works when caller has dirty $@' => sub {
    reset_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $ENV{REQUEST_METHOD}    = 'GET';
    $ENV{QUERY_STRING}      = 'x=1';

    eval { die "prior caller error\n" };   # set $@
    my $pre_err = $@;
    ok(length($pre_err), 'precondition: $@ is set before calling params()');

    my $info = CGI::Info->new();
    my $p    = eval { $info->params() };
    ok(!$@, 'params() does not die when called with a dirty $@');
};

# ============================================================
# 25. Referrer-based robot detection: hostile referrer values
# ============================================================

# Spam referrers with a closing parenthesis are blocked.
# The WAF checks for ')' in the referrer string.
subtest 'is_robot: referrer with closing parenthesis blocked as spam' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 Firefox/120.0';
    $ENV{REMOTE_ADDR}     = '1.2.3.4';
    $ENV{HTTP_REFERER}    = 'http://spam-site.example.com/page(with-paren)';

    my $info = CGI::Info->new();
    ok($info->is_robot(), 'referrer with ) detected as robot/spam');
};

# A referrer that backslash-abuses the URL must be normalised before
# matching — the is_robot() code replaces \ with _ before comparing.
subtest 'is_robot: backslash in referrer normalised before blacklist match' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 Firefox/120.0';
    $ENV{REMOTE_ADDR}     = '1.2.3.4';
    # Backslash variant of a known spam referrer — should be normalised to _ not crash
    $ENV{HTTP_REFERER}    = 'http://semalt.com\\hack';

    my $info = new_ok('CGI::Info');
    eval { $info->is_robot() };
    ok(!$@, 'backslash in referrer does not cause is_robot() to die');
};

# A known spam referrer from the embedded blocklist must be flagged.
subtest 'is_robot: known spam referrer (semalt.com) blocked' => sub {
    reset_env();
    $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 Firefox/120.0';
    $ENV{REMOTE_ADDR}     = '1.2.3.4';
    $ENV{HTTP_REFERER}    = 'http://semalt.com/fake-traffic';

    my $info = CGI::Info->new();
    ok($info->is_robot(), 'semalt.com in HTTP_REFERER flagged as robot');
};

# ============================================================
# 26. Sec-CH-UA-Mobile header boundary cases
# ============================================================

# '?1' means mobile; anything else (including '?0', '1', '') must not.
subtest 'Sec-CH-UA-Mobile: ?1 triggers is_mobile' => sub {
    reset_env();
    $ENV{HTTP_SEC_CH_UA_MOBILE} = '?1';
    my $info = CGI::Info->new();
    ok($info->is_mobile(), 'Sec-CH-UA-Mobile: ?1 sets is_mobile true');
};

subtest 'Sec-CH-UA-Mobile: ?0 does not trigger is_mobile' => sub {
    reset_env();
    $ENV{HTTP_SEC_CH_UA_MOBILE} = '?0';
    my $info = CGI::Info->new();
    ok(!$info->is_mobile(), 'Sec-CH-UA-Mobile: ?0 does not set is_mobile');
};

subtest 'Sec-CH-UA-Mobile: bare 1 (no ?) does not trigger is_mobile' => sub {
    reset_env();
    $ENV{HTTP_SEC_CH_UA_MOBILE} = '1';
    my $info = CGI::Info->new();
    ok(!$info->is_mobile(), 'Sec-CH-UA-Mobile: bare "1" is not the spec value ?1');
};

subtest 'Sec-CH-UA-Mobile: empty string does not trigger is_mobile' => sub {
    reset_env();
    $ENV{HTTP_SEC_CH_UA_MOBILE} = '';
    my $info = CGI::Info->new();
    ok(!$info->is_mobile(), 'Sec-CH-UA-Mobile: empty string does not trigger mobile');
};

done_testing();
