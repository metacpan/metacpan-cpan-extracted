#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Crypt::Age::Header;
use Crypt::Age::Keys;
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::Age::Stanza::X25519;

# Test header creation
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);

    ok(defined $header, 'header created');
    is(scalar @{$header->stanzas}, 1, 'one stanza');
    ok(defined $header->mac, 'MAC computed');
}

# Test header to_string format
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);
    my $str = $header->to_string;

    like($str, qr/^age-encryption\.org\/v1\n/, 'starts with version');
    like($str, qr/\n-> X25519 /, 'contains X25519 stanza');
    like($str, qr/\n--- [A-Za-z0-9+\/]+\n$/, 'ends with MAC line');
}

# Test header parse and roundtrip
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);
    my $str = $header->to_string;

    my $offset = 0;
    my $parsed = Crypt::Age::Header->parse(\$str, \$offset);

    is(scalar @{$parsed->stanzas}, 1, 'parsed one stanza');
    is($parsed->stanzas->[0]->type, 'X25519', 'stanza type is X25519');
    is($parsed->mac, $header->mac, 'MAC matches');
    is($offset, length($str), 'offset at end of header');
}

# Test MAC verification
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);

    ok($header->verify_mac($file_key), 'MAC verifies with correct key');

    my $wrong_key = Crypt::Age::Primitives->generate_file_key;
    ok(!$header->verify_mac($wrong_key), 'MAC fails with wrong key');
}

# Test file key unwrapping
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);
    my $unwrapped = $header->unwrap_file_key([$secret]);

    is($unwrapped, $file_key, 'unwrapped file key matches');
}

# Test multiple recipients
{
    my ($public1, $secret1) = Crypt::Age::Keys->generate_keypair;
    my ($public2, $secret2) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public1, $public2]);

    is(scalar @{$header->stanzas}, 2, 'two stanzas for two recipients');

    my $unwrapped1 = $header->unwrap_file_key([$secret1]);
    is($unwrapped1, $file_key, 'first recipient can unwrap');

    my $unwrapped2 = $header->unwrap_file_key([$secret2]);
    is($unwrapped2, $file_key, 'second recipient can unwrap');
}

# A stanza body of exactly 64*n base64 characters requires an empty final
# line per the ABNF (final-line = *63base64char LF). PR #2 alone regressed
# this: it parsed the header text with split(/\n/, ...), which silently
# drops a trailing empty element, so the parser ran out of lines before
# seeing the required empty final line and died with "Invalid age stanza #1
# body". The filehandle-based line-by-line read restored correct handling.
# An X25519 body (32 bytes -> 43 base64 chars) never reaches this boundary,
# so this needs an unknown stanza type with a 48-byte body (64 base64
# chars) -- the parser doesn't validate stanza types, only structure.
{
    my $body = join '', map { chr($_ % 251) } 1 .. 48;
    my $body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($body);
    is(length($body_b64), 64, 'fixture: body encodes to exactly 64 base64 chars');

    my $mac64 = Crypt::Age::Stanza::encode_base64_no_padding("\x00" x 32);
    my $str = join("\n",
        'age-encryption.org/v1',
        '-> stanza-test',
        $body_b64,
        '',            # required empty final line for a 64-char-multiple body
        "--- $mac64",
    ) . "\n";

    my $offset = 0;
    my $header = eval { Crypt::Age::Header->parse(\$str, \$offset) };
    is($@, '', 'header with an exact-64-char stanza body parses without dying');
    is(scalar @{$header->stanzas}, 1, 'one stanza parsed');
    is($header->stanzas->[0]->type, 'stanza-test', 'stanza type preserved');
    is(length($header->stanzas->[0]->body), 48, 'body decoded to the full 48 bytes');
    is($offset, length($str), 'offset lands at the end of the header');
}

# The header MAC must verify against the literal bytes that were read, not a
# re-serialization of the parsed stanzas (regression for commit 116444e):
# parse_from_fh passed the captured bytes under the constructor key 'bytes'
# while the attribute is '_bytes', so Moo silently dropped them and _bytes
# fell back to its lazy builder, which re-serializes the stanzas via
# Stanza::to_string instead of returning what was actually on the wire.
#
# This only shows up for a header our own writer cannot reproduce
# byte-for-byte: an extra unknown-type stanza whose body is exactly 64 base64
# characters, which requires an empty final line that Stanza::to_string
# omits (known gap, karr #3) -- the re-serialization comes out one byte
# short of the literal bytes. The MAC's correctness is not under test here
# (it's a fixed placeholder); only whether _bytes reflects the wire, so this
# needs no binary -- it's a literal-byte assertion per se.
{
    my ($public) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $stanza   = Crypt::Age::Stanza::X25519->wrap($file_key, $public);

    my $grease_body = join '', map { chr($_ % 251) } 1 .. 48;
    my $grease_body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($grease_body);

    my $head_no_mac = join("\n",
        'age-encryption.org/v1',
        $stanza->to_string,
        '-> grease-test',
        $grease_body_b64,
        '',
        '---',
    );
    my $mac64 = Crypt::Age::Stanza::encode_base64_no_padding("\x00" x 32);
    my $str = "$head_no_mac $mac64\n";

    my $offset = 0;
    my $header = Crypt::Age::Header->parse(\$str, \$offset);

    is($header->_bytes, $head_no_mac,
        'captured header bytes match the literal input, not a re-serialization');
    is($offset, length($str), 'offset lands at the end of the crafted header');
}

# verify_mac must not compare the MAC byte-by-byte with an early return on the
# first mismatch (karr #7). Timing is not measurable in a test suite and
# nothing below tries, so be clear about what this can and cannot show: the
# accept/reject assertions hold for a plain string eq too and would not catch a
# revert. They pin the contract around the comparison -- a MAC that differs in
# exactly one byte is rejected whether that byte is the first or the last, and
# a MAC of the wrong length or none at all is rejected without dying.
#
# The one assertion with teeth is the warning check: eq on an undef MAC emits
# "Use of uninitialized value", slow_eq does not.
{
    my ($public) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $header = Crypt::Age::Header->create($file_key, [$public]);
    my $good   = $header->mac;

    is(length($good), 32, 'fixture: MAC is 32 bytes');
    ok($header->verify_mac($file_key), 'valid MAC verifies');

    for my $pos (0, 31) {
        my $tampered = $good;
        substr($tampered, $pos, 1) = chr(ord(substr($good, $pos, 1)) ^ 0x01);
        $header->mac($tampered);
        my $ok = eval { $header->verify_mac($file_key) };
        is($@, '', "MAC differing only in byte $pos does not die");
        ok(!$ok, "MAC differing only in byte $pos is rejected");
    }

    for my $bad (substr($good, 0, 31), $good . "\x00", '') {
        $header->mac($bad);
        my $len = length($bad);
        my $ok = eval { $header->verify_mac($file_key) };
        is($@, '', "MAC of length $len does not die");
        ok(!$ok, "MAC of length $len is rejected");
    }

    $header->mac(undef);
    my @warnings;
    my $ok = do {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { $header->verify_mac($file_key) };
    };
    is($@, '', 'missing MAC does not die');
    ok(!$ok, 'missing MAC is rejected');
    is_deeply(\@warnings, [], 'missing MAC is rejected without warning');

    $header->mac($good);
    ok($header->verify_mac($file_key), 'restored MAC verifies again');
}

# c2sp.org/age, X25519 recipient type: the identity implementation "MUST
# otherwise reject any stanza that has more or less than two arguments, or
# where the second argument is not a canonical base64 encoding of a 32-byte
# value", and "MUST check that the body length is exactly 32 bytes before
# attempting to decrypt it, to mitigate partitioning oracle attacks" (karr #5).
# The spec counts the type itself as the first of those two arguments, so it is
# exactly one argument after the type here.
#
# These are header failures, not "this identity does not match". The rejection
# therefore has to land while the header is parsed, before any identity is
# consulted -- otherwise a header carrying a malformed X25519 stanza could
# still decrypt through some other stanza beside it, and whether it did would
# depend on the order the stanzas happened to be tried in.
#
# Measured on HEAD before the fix: every one of the six cases below got past
# Header::parse.
#   two arguments  -> unwrap_file_key returned the correct file key. The extra
#                     argument was ignored in silence.
#   no argument    -> died inside CryptX with "FATAL: undefined key", after six
#                     "Use of uninitialized value" warnings from the decoder.
#   argument != 32 -> died inside CryptX with "FATAL: invalid key". Incidental:
#                     that is import_key_raw's own length check, not ours, and
#                     it says nothing about the age format.
#   body != 32     -> croaked inside the eval in Stanza::X25519::unwrap, came
#                     back as undef, and Header::unwrap_file_key reported "No
#                     matching identity found" -- precisely the "no match" the
#                     spec says a malformed stanza must not be turned into.
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $good     = Crypt::Age::Stanza::X25519->wrap($file_key, $public);
    my $good_arg = $good->args->[0];
    my $good_body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($good->body);

    is(length($good->body), 32, 'fixture: a wrapped file key is 32 bytes');
    is(length(Crypt::Age::Stanza::decode_base64_no_padding($good_arg)), 32,
        'fixture: the ephemeral share is 32 bytes');

    # A one-stanza header carrying a real MAC over its own bytes, so that a
    # case which is NOT rejected runs all the way to an unwrapped file key. A
    # placeholder MAC would make "accepted" indistinguishable from "accepted
    # and then failed MAC verification".
    my $build = sub {
        my ($arg_line, $body_b64) = @_;
        my $head_no_mac = join("\n",
            'age-encryption.org/v1', $arg_line, $body_b64, '---');
        my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $head_no_mac);
        return $head_no_mac . ' '
            . Crypt::Age::Stanza::encode_base64_no_padding($mac) . "\n";
    };

    my @rejected = (
        ['no argument',
            '-> X25519',
            $good_body_b64],
        ['two arguments',
            "-> X25519 $good_arg $good_arg",
            $good_body_b64],
        ['an argument decoding to 31 bytes',
            '-> X25519 ' . Crypt::Age::Stanza::encode_base64_no_padding("\x01" x 31),
            $good_body_b64],
        ['an argument decoding to 33 bytes',
            '-> X25519 ' . Crypt::Age::Stanza::encode_base64_no_padding("\x01" x 33),
            $good_body_b64],
        ['a 31-byte body',
            "-> X25519 $good_arg",
            Crypt::Age::Stanza::encode_base64_no_padding("\x02" x 31)],
        ['a 33-byte body',
            "-> X25519 $good_arg",
            Crypt::Age::Stanza::encode_base64_no_padding("\x02" x 33)],
    );

    for my $case (@rejected) {
        my ($name, $arg_line, $body_b64) = @$case;

        my $str = $build->($arg_line, $body_b64);
        my $offset = 0;
        my @warnings;
        my $header = do {
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            eval { Crypt::Age::Header->parse(\$str, \$offset) };
        };
        my $err = $@;

        ok(!defined $header, "an X25519 stanza with $name is rejected at parse time");
        like($err, qr/Invalid X25519 stanza/,
            "rejecting $name names the age-format rule, not a CryptX internal");
        is_deeply(\@warnings, [],
            "rejecting $name emits no warnings");

        # The argument and the body are key material -- an error must name the
        # reason, never the value.
        my (undef, undef, @arg_values) = split / /, $arg_line;
        for my $value (@arg_values, $body_b64) {
            unlike($err, qr/\Q$value\E/,
                "rejecting $name does not quote the stanza contents back");
        }
    }

    # Must keep working: a well-formed X25519 stanza.
    {
        my $str = $build->("-> X25519 $good_arg", $good_body_b64);
        my $offset = 0;
        my $header = eval { Crypt::Age::Header->parse(\$str, \$offset) };
        is($@, '', 'a well-formed X25519 stanza still parses');
        is($header->stanzas->[0]->type, 'X25519', 'and is built as an X25519 stanza');
        is($header->unwrap_file_key([$secret]), $file_key,
            'and still yields the file key');
    }

    # Must keep working: an unrecognized stanza type beside a valid X25519 one.
    # "Implementations MUST ignore unrecognized stanzas" -- the validation above
    # is scoped by class, not by inspecting every stanza in the header, and this
    # grease stanza is shaped to break every single X25519 rule if it were:
    # two arguments, neither of them a 32-byte value, and a 10-byte body.
    {
        my $grease_b64 = Crypt::Age::Stanza::encode_base64_no_padding("\x03" x 10);
        my $head_no_mac = join("\n",
            'age-encryption.org/v1',
            $good->to_string,
            '-> grease-test one two',
            $grease_b64,
            '---',
        );
        my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $head_no_mac);
        my $str = $head_no_mac . ' '
            . Crypt::Age::Stanza::encode_base64_no_padding($mac) . "\n";

        my $offset = 0;
        my $header = eval { Crypt::Age::Header->parse(\$str, \$offset) };
        is($@, '', 'an unrecognized stanza type is not rejected');
        is(scalar @{$header->stanzas}, 2, 'both stanzas parsed');
        ok(!$header->stanzas->[1]->isa('Crypt::Age::Stanza::X25519'),
            'the unrecognized stanza is not built as an X25519 stanza');
        is($header->unwrap_file_key([$secret]), $file_key,
            'the file key still unwraps from the X25519 stanza beside it');
    }
}

# c2sp.org/age, "ABNF definition of file header" (karr #14):
#
#     arg-line = "-> " argument *(SP argument) LF
#     argument = 1*VCHAR
#
# VCHAR is RFC 5234's %x21-7E. There is no separate rule for the stanza type
# -- the type is the first argument and carries the same character set. The
# test kit's stanza_valid_characters vector sweeps the whole 0x21-0x7e range
# across type and argument tokens and expects success; stanza_invalid_character
# puts the two UTF-8 bytes of "e-grave" in the argument of an unrecognized
# "stanza" type and expects a header failure.
#
# That pairing is the whole point of this block, and it is why the check
# cannot live in a stanza class: the character set belongs to the header's
# grammar, not to a recipient type. A byte outside it invalidates the WHOLE
# header even though the stanza carrying it is of an unknown type that the
# format would otherwise require us to ignore. The rejection therefore has to
# happen before the type dispatch.
#
# Measured on HEAD before the fix: the start-line regex spelled the argument
# character set as \S+, which admits every non-whitespace byte. All four
# rejection cases below parsed cleanly, the offending stanza was built as a
# plain Crypt::Age::Stanza, ignored as an unknown type, and unwrap_file_key
# then returned the correct file key from the valid X25519 stanza beside it --
# i.e. the header was not merely parsed but fully accepted.
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $x25519   = Crypt::Age::Stanza::X25519->wrap($file_key, $public);
    my $grease_b64 = Crypt::Age::Stanza::encode_base64_no_padding("\x03" x 10);

    # A header carrying a real MAC over its own literal bytes, so that a case
    # which is NOT rejected runs all the way through to an unwrapped file key.
    # With a placeholder MAC "accepted" would be indistinguishable from
    # "accepted, then failed MAC verification".
    my $build = sub {
        my ($grease_arg_line) = @_;
        my $head_no_mac = join("\n",
            'age-encryption.org/v1',
            $x25519->to_string,
            $grease_arg_line,
            $grease_b64,
            '---',
        );
        my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $head_no_mac);
        return $head_no_mac . ' '
            . Crypt::Age::Stanza::encode_base64_no_padding($mac) . "\n";
    };

    my @rejected = (
        # Exactly the stanza_invalid_character vector's shape: unrecognized
        # type, non-ASCII byte in the argument.
        ['a non-ASCII byte in an unrecognized stanza type\'s argument',
            "-> stanza \xc3\xa8"],
        # 0x7f (DEL) sits one past the top of VCHAR, 0x01 well below it.
        ['a control character (0x01) in an argument',
            "-> grease-test one\x01two"],
        ['a DEL byte (0x7f) in an argument',
            "-> grease-test one\x7ftwo"],
        # The type is just the first argument, so it is restricted too.
        ['a non-ASCII byte in the stanza type itself',
            "-> gr\xc3\xa8ase one"],
    );

    for my $case (@rejected) {
        my ($name, $grease_arg_line) = @$case;

        my $str = $build->($grease_arg_line);
        my $offset = 0;
        my @warnings;
        my $header = do {
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            eval { Crypt::Age::Header->parse(\$str, \$offset) };
        };
        my $err = $@;

        ok(!defined $header, "$name is rejected at parse time");
        like($err, qr/Invalid age stanza #2 start line/,
            "rejecting $name names the offending stanza and the format rule");
        is_deeply(\@warnings, [], "rejecting $name emits no warnings");

        # Stanza arguments are key material -- an error names the reason,
        # never the value.
        unlike($err, qr/\Q$grease_arg_line\E/,
            "rejecting $name does not quote the stanza line back");
    }

    # The counter-test, and the reason the check above must not be broader
    # than the ABNF: the full printable-ASCII battery, laid out the way
    # stanza_valid_characters does it -- every byte from 0x21 to 0x7e, split
    # into space-separated argument tokens, the first of which is the type.
    # If the character set is tightened past VCHAR this is what goes red.
    {
        my @chars = map { chr } 0x21 .. 0x7e;
        is(scalar @chars, 94, 'fixture: 94 printable ASCII characters');

        my @tokens;
        push @tokens, join('', splice(@chars, 0, 8)) while @chars;
        my $grease_arg_line = '-> ' . join(' ', @tokens);
        is(length(join('', @tokens)), 94,
            'fixture: every printable ASCII byte appears in the arg line');

        my $str = $build->($grease_arg_line);
        my $offset = 0;
        my $header = eval { Crypt::Age::Header->parse(\$str, \$offset) };

        is($@, '', 'a stanza using the full printable-ASCII set is accepted');
        is(scalar @{$header->stanzas}, 2, 'both stanzas parsed');
        is($header->stanzas->[1]->type, $tokens[0],
            'the type is the first argument, punctuation and all');
        is_deeply($header->stanzas->[1]->args, [@tokens[1 .. $#tokens]],
            'the remaining arguments survive verbatim');
        ok(!$header->stanzas->[1]->isa('Crypt::Age::Stanza::X25519'),
            'the unrecognized stanza is not built as an X25519 stanza');
        is($header->unwrap_file_key([$secret]), $file_key,
            'and the file key still unwraps from the X25519 stanza beside it');
    }

    # An empty argument is not an argument: argument = 1*VCHAR. This already
    # held before the fix (\S+ cannot match nothing either) and must keep
    # holding -- the test kit's stanza_empty_argument vector depends on it.
    {
        my $str = $build->('-> stanza  argument');
        my $offset = 0;
        my $header = eval { Crypt::Age::Header->parse(\$str, \$offset) };
        ok(!defined $header, 'an empty stanza argument is still rejected');
        like($@, qr/Invalid age stanza #2 start line/,
            'and reports it as a bad stanza start line');
    }
}

done_testing;
