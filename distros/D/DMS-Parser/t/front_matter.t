#!/usr/bin/env perl
# SPEC §Front-matter-only decode — tests for
# DMS::Parser::decode_front_matter($src). Mirrors the contract:
#   - No FM at all → undef
#   - Empty FM (`+++\n+++\n`) → defined but empty hashref
#   - FM with user keys → hashref with those keys
#   - `_dms_tier: 1` → die ("not supported")
#   - Unknown reserved key → die ("unknown reserved key: ...")
#   - Unterminated FM → die ("unterminated front matter ...")
#   - Body errors do NOT surface (FM-only stops at the closing `+++`)
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use DMS::Parser;

# Strip the lite-mode order sidecar to compare key sets simply.
sub user_keys {
    my $h = shift;
    return [ sort grep { $_ ne "\0_keys" } keys %$h ];
}

# 1. No front matter → undef.
{
    my $fm = DMS::Parser::decode_front_matter("port: 8080\n");
    is($fm, undef, 'no FM: returns undef');

    $fm = DMS::Parser::decode_front_matter("");
    is($fm, undef, 'empty source: returns undef');

    # Trivia only (comments, blank lines) without a `+++`: still undef.
    $fm = DMS::Parser::decode_front_matter("# just a comment\n\n");
    is($fm, undef, 'trivia-only source: returns undef');
}

# 2. Empty FM (`+++\n+++\n`) → defined empty hashref.
{
    my $fm = DMS::Parser::decode_front_matter("+++\n+++\nport: 8080\n");
    ok(defined $fm, 'empty FM: defined');
    is(ref($fm), 'HASH', 'empty FM: hashref');
    is_deeply(user_keys($fm), [], 'empty FM: zero user keys');
}

# 3. FM with user keys.
{
    my $src = qq{+++
app_name: "myservice"
doc_version: "1.2.3"
+++
body: 1
};
    my $fm = DMS::Parser::decode_front_matter($src);
    ok(defined $fm, 'user-keys FM: defined');
    is_deeply(user_keys($fm), ['app_name', 'doc_version'], 'user-keys FM: keys');
    is($fm->{app_name},    'myservice', 'user-keys FM: app_name value');
    is($fm->{doc_version}, '1.2.3',     'user-keys FM: doc_version value');
}

# 4. `_dms_tier: 1` → die.
{
    my $src = "+++\n_dms_tier: 1\n+++\n";
    eval { DMS::Parser::decode_front_matter($src); };
    my $err = $@;
    ok($err, '_dms_tier: 1 raises');
    like($err, qr/_dms_tier/, '_dms_tier: 1 error mentions key');
    like($err, qr/not supported|tier/i, '_dms_tier: 1 error mentions tier');
}

# 5. Unknown reserved key → die.
{
    my $src = qq{+++
_my_app_version: "1.0"
+++
};
    eval { DMS::Parser::decode_front_matter($src); };
    my $err = $@;
    ok($err, 'unknown reserved key raises');
    like($err, qr/unknown reserved key/, 'unknown reserved error message');
    like($err, qr/_my_app_version/, 'unknown reserved error names key');
}

# 6. Unterminated FM → die.
{
    my $src = "+++\nauthor: \"x\"\n";   # no closing +++
    eval { DMS::Parser::decode_front_matter($src); };
    my $err = $@;
    ok($err, 'unterminated FM raises');
    like($err, qr/unterminated front matter/, 'unterminated FM error message');
}

# 7. Bad body but valid FM → succeeds (FM-only stops before body).
{
    # Body has an unterminated heredoc — full decode would die, but FM
    # parse stops at the closing `+++` and never tokenizes the body.
    my $src = qq{+++
author: "x"
+++
broken: """END
  no closing label ever
};
    my $fm;
    my $ok = eval { $fm = DMS::Parser::decode_front_matter($src); 1 };
    ok($ok, 'bad body, valid FM: no exception')
        or diag("error: $@");
    ok(defined $fm, 'bad body, valid FM: FM hashref defined');
    is($fm->{author}, 'x', 'bad body, valid FM: author key intact');
}

# 8. `_dms_tier: 0` is allowed and consumed (no user keys leak it).
{
    my $src = qq{+++
_dms_tier: 0
api_version: "v1"
+++
body: 1
};
    my $fm = DMS::Parser::decode_front_matter($src);
    ok(defined $fm, '_dms_tier: 0 accepted');
    is_deeply(user_keys($fm), ['api_version'],
        '_dms_tier: 0 consumed; not surfaced as user key');
    is($fm->{api_version}, 'v1', 'user key alongside _dms_tier preserved');
}

# 9. `_dms_tier` as wrong type → die ("must be a non-negative integer").
{
    my $src = qq{+++
_dms_tier: "0"
+++
};
    eval { DMS::Parser::decode_front_matter($src); };
    my $err = $@;
    ok($err, '_dms_tier wrong type raises');
    like($err, qr/_dms_tier must be a non-negative integer/,
        '_dms_tier wrong-type error message');
}

done_testing;
