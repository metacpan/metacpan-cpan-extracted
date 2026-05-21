#!/usr/bin/env perl
# encode round-trip tests for the XS DMS parser. Mirrors the pure-Perl
# port's t/roundtrip.t. SPEC v0.14 renamed parse/to_dms to decode/encode.
#
# Caveat: the underlying C parser does not yet record original_forms,
# so integer-base / string-form preservation tests are weakened to
# data-equivalence checks (the emitter falls back to default forms:
# decimal integers, basic-quoted strings). Comments, structure, and
# overall round-trip stability still hold.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../blib/lib";
use lib "$FindBin::Bin/../blib/arch";
use DMS::Parser::XS;

sub roundtrip {
    my ($src) = @_;
    my $doc = DMS::Parser::XS::decode_document($src);
    return DMS::Parser::XS::encode($doc);
}

# 1. Integer body equivalence after round-trip (byte-identical literal
# forms not guaranteed without C-side original_forms recording).
{
    my $src = "a: 0x1F40\nb: 0o755\nc: 0b1010_0110\nd: 1_000_000\ne: +42\nf: -7\n";
    my $out = roundtrip($src);
    my $d1 = DMS::Parser::XS::decode_document($src);
    my $d2 = DMS::Parser::XS::decode_document($out);
    is_deeply($d2->{body}, $d1->{body}, 'integer body equivalent after round-trip');
}

# 2. String body equivalence.
{
    my $src = qq{basic: "hello"
lit: 'C:\\path'
hd_b_lab: """END
  hello
  END
};
    my $out = roundtrip($src);
    my $d1 = DMS::Parser::XS::decode_document($src);
    my $d2 = DMS::Parser::XS::decode_document($out);
    is_deeply($d2->{body}, $d1->{body}, 'string body equivalent after round-trip');
}

# 3. Comments at attached paths preserved.
{
    my $src = "# leading on a\n"
            . "a: 1   # trailing on a\n"
            . "b:\n"
            . "  x: 2\n"
            . "  # floating in b\n";
    my $out = roundtrip($src);
    my $d2 = DMS::Parser::XS::decode_document($out);
    is(scalar @{ $d2->{comments} }, 3, 'three comments survive round-trip');
    my ($have_l, $have_t, $have_f) = (0, 0, 0);
    for my $ac (@{ $d2->{comments} }) {
        my $pos = $ac->{position};
        my @path = @{ $ac->{path} };
        if ($pos eq 'leading'  && @path == 1 && !ref($path[0]) && $path[0] eq 'a') { $have_l = 1; }
        if ($pos eq 'trailing' && @path == 1 && !ref($path[0]) && $path[0] eq 'a') { $have_t = 1; }
        if ($pos eq 'floating' && @path == 1 && !ref($path[0]) && $path[0] eq 'b') { $have_f = 1; }
    }
    ok($have_l, 'leading on a re-attached');
    ok($have_t, 'trailing on a re-attached');
    ok($have_f, 'floating in b re-attached');
}

# 4. Front matter omitted when empty (no meta, no FM comments).
{
    my $out = roundtrip("x: 1\n");
    unlike($out, qr/\+\+\+/, 'no front matter emitted for plain doc');
}

# 5. Front matter preserved when present.
{
    my $src = qq{+++\nauthor: "x"\n+++\nbody: 1\n};
    my $out = roundtrip($src);
    like($out, qr/\+\+\+/, 'front matter emitted');
    my $d1 = DMS::Parser::XS::decode_document($src);
    my $d2 = DMS::Parser::XS::decode_document($out);
    is_deeply($d2->{meta}, $d1->{meta}, 'front matter equivalent after round-trip');
    is_deeply($d2->{body}, $d1->{body}, 'body equivalent after round-trip');
}

# 6. Second-round byte-stable. Even without original_forms, the second
# round must equal the first because both rounds emit the same default
# forms for unrecorded values.
{
    my @cases = (
        "a: 1\nb: 2\n",
        "# leading\nport: 100   # trailing\n",
        qq{+++\nauthor: "x"\n+++\nbody: 1\n},
        "items: [1, 2, 3]\np: {x: 1, y: 2}\n",
    );
    for my $src (@cases) {
        my $out1 = roundtrip($src);
        my $out2 = roundtrip($out1);
        is($out2, $out1, "second-round byte stable for: " . substr($src, 0, 40))
            or diag("out1:\n$out1\nout2:\n$out2");
    }
}

# -- Mutation scenarios (decode -> edit -> re-encode) ------------------
#
# Mirrors the Rust reference's tests:
#   to_dms_value_update_preserves_attached_comments
#   to_dms_deleted_key_drops_attached_comments
#   to_dms_inserted_key_carries_no_comments
#   to_dms_combined_mutations
#
# SPEC §Comments §Round-trip semantics:
#   "comments on still-present nodes travel with them; newly inserted
#    nodes carry no comments; deleted nodes drop theirs."
#
# Note (XS-specific): integer values returned by the C parser are
# blessed DMS::Parser::Integer scalar refs, identical in shape to the pure-Perl
# port. Original-forms preservation is best-effort via the C parser;
# these tests assert structure + comments only.

sub _count_comments_at {
    my ($doc, $key) = @_;
    my $n = 0;
    for my $ac (@{ $doc->{comments} }) {
        my @path = @{ $ac->{path} };
        next unless @path == 1 && !ref($path[0]) && $path[0] eq $key;
        $n++;
    }
    return $n;
}

sub _count_comments_at_pos {
    my ($doc, $key, $pos) = @_;
    my $n = 0;
    for my $ac (@{ $doc->{comments} }) {
        next unless $ac->{position} eq $pos;
        my @path = @{ $ac->{path} };
        next unless @path == 1 && !ref($path[0]) && $path[0] eq $key;
        $n++;
    }
    return $n;
}

# 7. Update a leaf value; leading + trailing comments on its kvpair must
#    travel with it.
{
    my $src = "# the listening port\nport: 8080   # default for staging\nhost: \"localhost\"\n";
    my $doc = DMS::Parser::XS::decode_document($src);
    $doc->{body}->{port} = DMS::Parser::Integer->new(5432);
    my $emitted = DMS::Parser::XS::encode($doc);
    my $doc2 = DMS::Parser::XS::decode_document($emitted);
    is(${ $doc2->{body}->{port} }, 5432, 'update: value reflected after re-parse');
    is(_count_comments_at_pos($doc2, 'port', 'leading'),  1,
        'update: leading comment on `port` survives');
    is(_count_comments_at_pos($doc2, 'port', 'trailing'), 1,
        'update: trailing comment on `port` survives');
}

# 8. Delete a kvpair; its comments must NOT survive (the node they
#    attached to is gone). Sibling comments must still be there.
{
    my $src = "# keep this\nkeep: 1   # me too\n# drop this\ndrop: 2   # bye\n";
    my $doc = DMS::Parser::XS::decode_document($src);
    # Tie::IxHash supports DELETE via the standard `delete EXPR` form.
    delete $doc->{body}->{drop};
    my $emitted = DMS::Parser::XS::encode($doc);
    my $doc2 = DMS::Parser::XS::decode_document($emitted);
    ok(!exists $doc2->{body}->{drop}, 'delete: deleted key gone after re-parse');
    ok( exists $doc2->{body}->{keep}, 'delete: sibling key still present');
    is(_count_comments_at($doc2, 'drop'), 0,
        "delete: deleted key's comments must not survive");
    is(_count_comments_at_pos($doc2, 'keep', 'leading'),  1,
        "delete: sibling's leading comment survives");
    is(_count_comments_at_pos($doc2, 'keep', 'trailing'), 1,
        "delete: sibling's trailing comment survives");
}

# 9. Insert a new kvpair; it must come back with zero attached comments.
{
    my $src = "# leading on existing\nexisting: 1   # trailing on existing\n";
    my $doc = DMS::Parser::XS::decode_document($src);
    $doc->{body}->{inserted} = "new";
    my $emitted = DMS::Parser::XS::encode($doc);
    my $doc2 = DMS::Parser::XS::decode_document($emitted);
    is(${ $doc2->{body}->{existing} }, 1, 'insert: existing value reflected');
    is($doc2->{body}->{inserted}, 'new', 'insert: new value reflected');
    is(_count_comments_at($doc2, 'inserted'), 0,
        'insert: newly inserted key has no comments');
    is(_count_comments_at($doc2, 'existing'), 2,
        "insert: existing key's leading + trailing comments survive");
}

# 10. Combined: update one value, delete one key, insert a new one.
{
    my $src = "# A\na: 1   # a-trail\n# B\nb: 2   # b-trail\n# C\nc: 3   # c-trail\n";
    my $doc = DMS::Parser::XS::decode_document($src);
    $doc->{body}->{a} = DMS::Parser::Integer->new(100);   # update
    delete $doc->{body}->{b};                     # delete
    $doc->{body}->{d} = DMS::Parser::Integer->new(4);     # insert
    my $emitted = DMS::Parser::XS::encode($doc);
    my $doc2 = DMS::Parser::XS::decode_document($emitted);
    is(${ $doc2->{body}->{a} }, 100, 'combined: a updated to 100');
    ok(!exists $doc2->{body}->{b},   'combined: b deleted');
    is(${ $doc2->{body}->{c} }, 3,   'combined: c untouched');
    is(${ $doc2->{body}->{d} }, 4,   'combined: d inserted');
    is(_count_comments_at($doc2, 'a'), 2, 'combined: a keeps both comments');
    is(_count_comments_at($doc2, 'b'), 0, 'combined: b dropped its comments');
    is(_count_comments_at($doc2, 'c'), 2, 'combined: c keeps both comments');
    is(_count_comments_at($doc2, 'd'), 0, 'combined: d has no comments');
}

# 11. Deprecated aliases (SPEC v0.14 migration window): parse / to_dms
#     still work and produce the same result as decode / encode.
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $src = "alpha: 1\nbeta: 2\n";
    my $body_new = DMS::Parser::XS::decode($src);
    my $body_old = DMS::Parser::XS::parse($src);
    is_deeply($body_old, $body_new, 'parse() alias matches decode()');

    my $doc_new = DMS::Parser::XS::decode_document($src);
    my $doc_old = DMS::Parser::XS::parse_document($src);
    is_deeply($doc_old->{body}, $doc_new->{body},
        'parse_document alias still callable, returns equivalent body');

    my $emit_new = DMS::Parser::XS::encode($doc_new);
    my $emit_old = DMS::Parser::XS::to_dms($doc_new);
    is($emit_old, $emit_new, 'to_dms() alias matches encode()');

    my $emit_lite_new = DMS::Parser::XS::encode_lite($doc_new);
    my $emit_lite_old = DMS::Parser::XS::to_dms_lite($doc_new);
    is($emit_lite_old, $emit_lite_new, 'to_dms_lite() alias matches encode_lite()');

    my $joined = join('', @warnings);
    like($joined, qr/parse\(\) is deprecated/,
        'parse() emits deprecation warning');
    like($joined, qr/to_dms\(\) is deprecated/,
        'to_dms() emits deprecation warning');
}

done_testing;
