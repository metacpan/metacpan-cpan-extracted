#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Crypt::Age;
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

# Ticket #22 regression, the recipient-format half: Header::create's
# rejection of a non-age1 recipient used to interpolate the caller's string
# directly into the croak ("Unsupported recipient format: $recipient"), so
# a caller who swapped recipient and identity got the whole secret key
# echoed into the exception, and from there into whatever logs it. The fix
# rebuilds the message from literals plus the recipient's 0-based array
# index and, when the string matches /^AGE-SECRET-KEY-1/i, a hint that
# classifies against that public format prefix without copying a byte of
# the caller's string.
#
# The bad entry sits at index 1, not 0, so the index actually has to be
# computed rather than being coincidentally right. The decisive assertion
# is the negative one: it searches the message for a slice of the secret
# rather than comparing against the expected text, so it still catches a
# future edit that echoes some other slice of the string.
{
    my ($public)     = Crypt::Age::Keys->generate_keypair;
    my (undef, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    # A non-identity, non-age1 string at the same non-zero index: the base
    # message, with no identity hint.
    my $err_plain = do {
        local $@;
        eval { Crypt::Age::Header->create($file_key, [$public, 'not-an-age-key']) };
        $@;
    };
    like($err_plain,
        qr/^Unsupported recipient format at index 1: expected an age1 recipient\b/,
        'a non-identity recipient at index 1 gets the base message with the correct index');
    unlike($err_plain, qr/got an AGE-SECRET-KEY-1 identity/,
        'and no identity hint, since the string does not look like one');

    # A secret key at the same index: the base message plus the identity
    # hint, and no leaked key material.
    my $err_secret = do {
        local $@;
        eval { Crypt::Age::Header->create($file_key, [$public, $secret]) };
        $@;
    };
    like($err_secret,
        qr/^Unsupported recipient format at index 1: expected an age1 recipient, got an AGE-SECRET-KEY-1 identity/,
        'a secret key at index 1 gets the base message plus the identity hint, with the correct index');

    my $needle = substr($secret, 8, 20);
    is(length($needle), 20, 'fixture: probed substring is 20 bytes long');
    ok(index($err_secret, $needle) == -1,
        'no characteristic slice of the secret key leaks into the message');
}

# Ticket #25 regression: an undef entry in either array used to reach a
# pattern match and emit "Use of uninitialized value" from library code --
# twice from Header::create (the age1 prefix test and the identity hint),
# once per X25519 stanza from unwrap_file_key. The warnings arrived ahead of
# the message that explains the problem, and a caller cannot switch off
# warnings that are enabled inside this distribution.
#
# The decisive assertions below are the is_deeply(\@warnings, []) ones. The
# croak was already correct before the fix and its checks would have passed
# against the old code too; only the warning count actually pins this ticket.
{
    my ($public)  = Crypt::Age::Keys->generate_keypair;
    my ($public2) = Crypt::Age::Keys->generate_keypair;
    my $file_key  = Crypt::Age::Primitives->generate_file_key;

    # undef at a non-zero index, so the reported index has to be computed.
    my @warnings;
    my $err = do {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        local $@;
        eval { Crypt::Age::Header->create($file_key, [$public, undef]) };
        $@;
    };
    is_deeply(\@warnings, [],
        'an undef recipient is rejected without any warning');
    like($err,
        qr/^Unsupported recipient format at index 1: expected an age1 recipient, got undef/,
        'and with the index and ", got undef" in the message shape #22 established');

    # Named through the same ", got ..." slot as the identity hint, so the
    # two classifications stay mutually exclusive rather than accumulating.
    unlike($err, qr/got an AGE-SECRET-KEY-1 identity/,
        'and not also the identity hint, which undef must not reach');

    # Index 0 as well: the message must not merely be right by coincidence
    # for the one position the case above uses.
    my @warnings_first;
    my $err_first = do {
        local $SIG{__WARN__} = sub { push @warnings_first, @_ };
        local $@;
        eval { Crypt::Age::Header->create($file_key, [undef, $public]) };
        $@;
    };
    is_deeply(\@warnings_first, [],
        'an undef recipient at index 0 is rejected without any warning');
    like($err_first,
        qr/^Unsupported recipient format at index 0: expected an age1 recipient, got undef/,
        'and names index 0, so the index is computed and not hardcoded');

    # The identity array is the other half of the ticket. It has the same
    # hole -- a pattern match on undef, once per X25519 stanza -- but not the
    # same contract: an identity that does not match is skipped, not fatal.
    # So the fix there removes the warnings and must leave that behaviour
    # alone. Two recipients, hence two stanzas, so a per-stanza warning would
    # show up as two.
    my ($public3, $secret3) = Crypt::Age::Keys->generate_keypair;
    my $header = Crypt::Age::Header->create($file_key, [$public2, $public3]);
    is(scalar @{$header->stanzas}, 2, 'fixture: header carries two X25519 stanzas');

    my @warnings_id;
    my $unwrapped = do {
        local $SIG{__WARN__} = sub { push @warnings_id, @_ };
        eval { $header->unwrap_file_key([undef, $secret3]) };
    };
    is_deeply(\@warnings_id, [],
        'an undef identity is skipped without any warning');
    is($unwrapped, $file_key,
        'and a later valid identity still unwraps the file key, as before the fix');

    # A list with nothing usable in it still ends at the croak, not at a
    # warning and not at a silent success.
    my @warnings_none;
    my $err_none = do {
        local $SIG{__WARN__} = sub { push @warnings_none, @_ };
        local $@;
        eval { $header->unwrap_file_key([undef, undef]) };
        $@;
    };
    is_deeply(\@warnings_none, [],
        'an all-undef identity list warns not at all');
    like($err_none, qr/^No matching identity found/,
        'and still fails with the unchanged no-match error');
}

# Ticket #30, the third instance of the class #26 fixed in Crypt::Age and #28
# in Crypt::Age::Primitives: parse maps the scalar behind its ScalarRef into an
# in-memory handle, and perl refuses to map one holding a code point above
# 0xFF -- it warned "Strings with code points over 0xFF may not be mapped into
# in-memory file handles", the open then failed, and the croak read "Invalid
# age input: cannot read", which is true but names no cause and suggests no
# fix. A scan before the open replaces that with a message naming both; the
# open is never reached on this path, so the warning is gone too -- asserted,
# not suppressed.
#
# The scan is deliberate where the other three downgrade: the parameter is the
# caller's own scalar behind a ref, not a copy off @_, so this check reads it
# and never writes to it.
{
    my $wide = "age-encryption.org/v1\n\x{100} not bytes";
    my $offset = 0;

    my ($err, $line, @warn);
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        local $@;
        $line = __LINE__ + 1;
        eval { Crypt::Age::Header->parse(\$wide, \$offset) };
        $err = $@;
    }

    ok($err, 'parse with a wide-character data ref dies');
    like($err,
        qr/^data must be a byte string: it holds a code point above 0xFF, read it with :raw rather than decoding it\b/,
        'the message names the parameter, the cause and the fix');
    unlike($err, qr/Invalid age input: cannot read/,
        'parse no longer reports only that it could not read');
    is_deeply(\@warn, [],
        'the check runs before the open, so perl emits no >0xFF warning');
    unlike($err, qr{Crypt/Age/Header\.pm},
        'parse croaks: Header.pm is not blamed as the origin');
    my $where = quotemeta(__FILE__).' line '.$line;
    like($err, qr/$where/,
        'parse reports the caller position in this test file');
    ok(index($err, 'not bytes') == -1,
        'no part of the input appears in the error');

    # The one thing the non-mutating scan buys over a utf8::downgrade through
    # the ref: a rejected $data comes back exactly as the caller had it,
    # internal representation included.
    ok(utf8::is_utf8($wide),
        'the rejected data ref is left flagged -- the check never wrote to it');
    is($wide, "age-encryption.org/v1\n\x{100} not bytes",
        'and its value is untouched');
    is($offset, 0, 'and the offset ref was never advanced');
}

# Ticket #31, the argument shapes parse never checked. Its first parameter is
# documented as a ScalarRef and used to go straight to open, which is a
# filesystem open for everything that is not one: a plain string named a file,
# undef warned about the caller's mistake from inside Header.pm, and any other
# ref croaked "Invalid age input: cannot read", naming neither cause nor fix.
# All three now fail one type check before the open. This replaces #30's block
# over the same three shapes -- that one recorded the behaviour of the day so
# the wide-character scan could be shown not to disturb it, which was a
# characterization, never a claim that it was right.
my $ref_msg = 'data must be a ScalarRef: this method opens it, and a plain '
    .'string is a filename, pass \$data rather than $data';

{
    for my $case (['a plain string', "age-encryption.org/v1\nnot-a-ref"],
                  ['undef', undef],
                  ['an ARRAY ref', [1, 2]]) {
        my ($what, $arg) = @$case;
        my $offset = 0;

        my ($err, $line, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            $line = __LINE__ + 1;
            eval { Crypt::Age::Header->parse($arg, \$offset) };
            $err = $@;
        }

        like($err, qr/^\Q$ref_msg\E\b/,
            "$what is rejected by type, naming the parameter and the fix");
        unlike($err, qr/Invalid age input: cannot read/,
            "$what no longer arrives as a failed read");
        unlike($err, qr/not-a-ref/,
            "$what leaves no caller input in the message");
        is_deeply(\@warn, [],
            "$what reaches no open, so nothing warns out of Header.pm");
        unlike($err, qr{Crypt/Age/Header\.pm},
            "$what croaks: Header.pm is not blamed as the origin");
        my $where = quotemeta(__FILE__).' line '.$line;
        like($err, qr/$where/,
            "$what reports the caller position in this test file");
        is($offset, 0, "$what left the offset ref untouched");
    }
}

# Ticket #31, the half that is not cosmetics. Before the type check a plain
# string was a filename, so parse opened and read that file: given a path to a
# readable age header it returned a Crypt::Age::Header built from the file's
# bytes and advanced the caller's $offset past them. The fixture below is a
# real, readable file holding a header this parser accepts, which is what makes
# the assertion falsifiable -- without the check parse succeeds here.
{
    my ($public) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $header_bytes = Crypt::Age::Header->create($file_key, [$public])->to_string;

    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode($fh, ':raw');
    print $fh $header_bytes;
    close $fh;
    ok(-r $path, 'fixture: the file exists and is readable');

    my $offset = 0;
    my $parsed = eval { Crypt::Age::Header->parse($path, \$offset) };
    my $err = $@;

    is($parsed, undef,
        'a plain string naming a readable file does not open and parse it');
    like($err, qr/^\Q$ref_msg\E\b/, 'it is a type error instead');
    ok(index($err, $path) == -1,
        'and the path the caller passed is not echoed into the error');
    is($offset, 0, 'the offset ref was not advanced past that file');

    # Counter-proof that the fixture really is parseable, so the assertion
    # above measures the type check and not an unreadable file.
    my $data = $header_bytes;
    my $data_offset = 0;
    my $ok = Crypt::Age::Header->parse(\$data, \$data_offset);
    is(scalar @{$ok->stanzas}, 1,
        'the same bytes behind a ScalarRef still parse');
    is($data_offset, length($header_bytes),
        'and advance the offset to the end of the header');
}

# Ticket #32, the same defect class as #31 one argument further in. parse's
# second parameter is an out-parameter -- it seeks to the offset the ref holds
# and writes the new one back through it -- but nothing checked its shape, so
# every wrong one reached a raw dereference: a plain string died with perl's
# "Can't use string (\"...\") as a SCALAR ref while \"strict refs\" in use",
# quoting the caller's own string and blaming a line in Header.pm, undef died
# with "Can't use an undefined value as a SCALAR reference", and another kind
# of ref with "Not a SCALAR reference". A caller who passes the two arguments
# the other way round puts a whole ciphertext where that quoted string comes
# from, which is why the message below carries the requirement and its reason
# and no part of the argument.
my $offset_msg = 'offset must be a ScalarRef: this method writes the new '
    .'offset back through it, pass \$offset rather than $offset';

{
    # A real, parseable header as the first argument, so nothing before the
    # offset check can account for the failure: without the check this call
    # gets past the open and dies at the seek.
    my ($public) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $data = Crypt::Age::Header->create($file_key, [$public])->to_string;

    my $marker = 'CALLER-INPUT-MUST-NOT-LEAK-HERE';

    for my $case (['a plain string', $marker],
                  ['undef', undef],
                  ['an ARRAY ref', [1, 2]]) {
        my ($what, $arg) = @$case;

        my ($err, $line, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            $line = __LINE__ + 1;
            eval { Crypt::Age::Header->parse(\$data, $arg) };
            $err = $@;
        }

        like($err, qr/^\Q$offset_msg\E\b/,
            "$what is rejected by type, naming the parameter and the fix");
        unlike($err, qr/strict refs/,
            "$what no longer arrives as perl's own dereference error");
        ok(index($err, $marker) == -1,
            "$what leaves no caller input in the message");
        is_deeply(\@warn, [],
            "$what reaches no dereference, so nothing warns out of Header.pm");
        unlike($err, qr{Crypt/Age/Header\.pm},
            "$what croaks: Header.pm is not blamed as the origin");
        my $where = quotemeta(__FILE__).' line '.$line;
        like($err, qr/$where/,
            "$what reports the caller position in this test file");
    }

    # Both argument shapes are settled before anything looks at the data, so a
    # call that is malformed in its second argument is reported as that, not as
    # a complaint about the first one's contents. This is the documented order.
    my $wide = "age-encryption.org/v1\n\x{100} not bytes";
    my $err_order = do {
        local $@;
        eval { Crypt::Age::Header->parse(\$wide, $marker) };
        $@;
    };
    like($err_order, qr/^\Q$offset_msg\E\b/,
        'the offset shape is checked before the data is scanned for bytes');

    # Counter-proof that the loop above measures the type check: the same call
    # with a ScalarRef offset parses and reports where the payload starts.
    my $offset = 0;
    my $parsed = Crypt::Age::Header->parse(\$data, \$offset);
    is(scalar @{$parsed->stanzas}, 1,
        'a ScalarRef offset still parses the header');
    is($offset, length($data),
        'and the new offset is written back through it');
}

# Ticket #30 counter-proof: the check may reject only what perl cannot map. A
# header stored upgraded whose code points all fit in a byte is bytes, and it
# is what rules out utf8::is_utf8 as the test -- that would answer true here
# and refuse a header perl maps happily.
#
# It also records the limit of the non-mutating scan, so that nobody documents
# more than it does: on this path perl's own open downgrades the referenced
# scalar in place, so the caller's $str comes back unflagged. The scan does not
# prevent that and never could -- it only keeps the rejection path above clean.
{
    my ($public) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $str = Crypt::Age::Header->create($file_key, [$public])->to_string;

    utf8::upgrade($str);
    ok(utf8::is_utf8($str), 'fixture: the header string really is stored upgraded');

    my $offset = 0;
    my $parsed = eval { Crypt::Age::Header->parse(\$str, \$offset) };
    is($@, '', 'an upgraded header within Latin-1 is bytes and still parses');
    is(scalar @{$parsed->stanzas}, 1, 'and yields its stanza');
    is($offset, length($str), 'and the offset still lands at the end of the header');

    ok(!utf8::is_utf8($str),
        "perl's in-memory open downgraded the caller's scalar, not our check");
}

# Ticket #33, the same series one step further in: the argument shapes are both
# right and the content is missing. parse(\my $undef, \my $offset) passes #31's
# ScalarRef check (it really is one) and #32's offset check, and then used to
# emit ten "Use of uninitialized value" warnings out of Header.pm before
# croaking -- one from the byte-string scan, seven from reading an in-memory
# handle opened on an undefined scalar, and two from the version line that
# readline handed back as undef. Every one of them carried a Header.pm line
# number for a mistake made one frame up, and a caller can act on none of them.
#
# The undefined referent gets its own croak rather than being normalized to the
# empty string and left to the version-line croak: "there is nothing behind the
# ref you gave me" and "these bytes are not an age file" are different mistakes
# with different fixes, and this series has consistently named the cause instead
# of burying it under a more general message.
my $undef_msg = 'data must refer to a defined scalar: this method reads the '
    .'age file out of it, assign the bytes before passing \$data';

{
    my ($err, $line, @warn);
    my $offset = 0;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        local $@;
        my $undef;
        $line = __LINE__ + 1;
        eval { Crypt::Age::Header->parse(\$undef, \$offset) };
        $err = $@;
    }

    is_deeply(\@warn, [],
        'a ScalarRef to an undefined scalar warns nothing out of Header.pm');
    like($err, qr/^\Q$undef_msg\E\b/,
        'it is refused by its own croak, naming the cause and the fix');
    unlike($err, qr/Invalid age version/,
        'and not folded into the "not an age file" croak, which is a different mistake');
    like($err, qr/^\Q$undef_msg\E at /,
        'nothing is interpolated between the message and the croak position');
    unlike($err, qr{Crypt/Age/Header\.pm},
        'it croaks: Header.pm is not blamed as the origin');
    my $where = quotemeta(__FILE__).' line '.$line;
    like($err, qr/$where/,
        'the croak reports the caller position in this test file');
    is($offset, 0, 'the offset ref was left untouched');
}

# The neighbour path, which the fix above must not take over: an empty $data is
# a legitimate "not an age file" and keeps the plain version-line croak. It was
# not warning-free before this ticket either -- two of the ten above are shared
# with it, raised by chomp and eq on the undef that readline returns at end of
# input -- so this assertion is the record that the two paths now differ in
# their message and agree in warning nothing.
{
    my ($err, @warn);
    my $offset = 0;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        local $@;
        my $data = '';
        eval { Crypt::Age::Header->parse(\$data, \$offset) };
        $err = $@;
    }

    is_deeply(\@warn, [],
        'an empty $data warns nothing out of Header.pm either');
    like($err,
        qr/^Invalid age version: expected the literal age-encryption\.org\/v1 version line at /,
        'and still gets the plain version-line croak, with nothing interpolated');
    unlike($err, qr/\Q$undef_msg\E/,
        'empty bytes are data that arrived, not a ref to nothing');
}

# Same absence one frame down, at the line the fix actually sits on: a handle
# already at end of input has no version line to read, and reports that without
# warning first. parse_from_fh is public, and Crypt::Age::decrypt reaches it
# directly rather than through parse, so this is the path an empty ciphertext
# takes through the string API.
{
    my $empty = '';
    open my $fh, '<:raw', \$empty or die "open: $!";

    my ($err, @warn);
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        local $@;
        eval { Crypt::Age::Header->parse_from_fh($fh) };
        $err = $@;
    }

    is_deeply(\@warn, [],
        'parse_from_fh on a handle at end of input warns nothing');
    like($err, qr/^Invalid age version: expected the literal /,
        'and reports the missing version line');
}

# Ticket #34, the same series in the other pair of public methods -- and the one
# entry in it that leaks a secret. create and unwrap_file_key both dereferenced
# their list parameter without checking it, so a caller who passed a bare string
# instead of an ArrayRef got perl's own message, which quotes the first 32
# characters of the offending string:
#
#     Can't use string ("AGE-SECRET-KEY-1FAKEFAKEFAKEFAKE"...) as an ARRAY ref
#
# For unwrap_file_key that string is an B<identity>, so the exception carried
# secret key material into whatever log caught it, written from inside this
# module where the caller can no longer redact it. For create the string is a
# public key and so not a secret, but it is the identical defect one call away,
# and the swap of recipient and identity -- both are plain strings -- is exactly
# how a secret reaches create too. That swap is covered below on both methods.
#
# The markers here are 26 and 23 characters on purpose, and the real-key cases
# assert on a 31-character prefix rather than the whole string. Perl truncates
# the quoted string at 32, so anything longer never appears in the message even
# in the red state, and a "nothing leaked" assertion built on it passes without
# being able to fail. Every key here is fabricated or freshly generated.
my $recipients_msg = 'recipients must be an ArrayRef: this method wraps the '
    .'file key once per entry, pass [$recipient] rather than $recipient';
my $identities_msg = 'identities must be an ArrayRef: this method tries each '
    .'entry in turn, pass [$identity] rather than $identity';

{
    my ($public) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $marker = 'age1LEAKMARKERRECIPIENT';

    for my $case (['a bare recipient string', $marker],
                  ['undef',                   undef],
                  ['a HASH ref',              { $marker => 1 }]) {
        my ($what, $arg) = @$case;

        my ($err, $line, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            $line = __LINE__ + 1;
            eval { Crypt::Age::Header->create($file_key, $arg) };
            $err = $@;
        }

        like($err, qr/^\Q$recipients_msg\E\b/,
            "$what is rejected by type, naming the parameter and the fix");
        unlike($err, qr/strict refs|ARRAY reference/,
            "$what no longer arrives as perl's own dereference error");
        ok(index($err, $marker) == -1,
            "$what leaves no caller input in the message");
        is_deeply(\@warn, [],
            "$what reaches no dereference, so nothing warns out of Header.pm");
        unlike($err, qr{Crypt/Age/Header\.pm},
            "$what croaks: Header.pm is not blamed as the origin");
        my $where = quotemeta(__FILE__).' line '.$line;
        like($err, qr/$where/,
            "$what reports the caller position in this test file");
    }

    # The swap: a caller who passes an identity where the recipient belongs
    # puts a secret key into this parameter, bare. The assertion is on the
    # first 31 characters rather than the whole key, because the whole key is
    # 62 and perl would only ever have quoted 32 of them -- an index() on the
    # full string cannot fail and would prove nothing.
    #
    # Every assertion in this sub-block is an index() inside ok(), never a
    # like()/unlike() on $err and never is_deeply on the warnings. Those print
    # the value they were given when they fail, so a red state here would put
    # the same 32 characters of a real key into the test output that the bug
    # puts into the caller's log -- measured, not assumed: the first run of
    # this block did exactly that. ok() prints its name and nothing else.
    my ($public2, $secret) = Crypt::Age::Keys->generate_keypair;
    {
        my ($err, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            eval { Crypt::Age::Header->create($file_key, $secret) };
            $err = $@;
        }

        ok(index($err, $recipients_msg) == 0,
            'a bare identity in place of the recipient list is a type error');
        ok(index($err, substr($secret, 0, 31)) == -1,
            'and no part of that secret key reaches the message');
        ok(index($err, 'AGE-SECRET-KEY-1') == -1,
            'not even the identity prefix');
        is(scalar @warn, 0, 'and nothing warns out of Header.pm');
    }

    # Counter-proof that the cases above measure the type check and not a
    # recipient this method could not have used anyway.
    my $header = Crypt::Age::Header->create($file_key, [$public]);
    is(scalar @{$header->stanzas}, 1,
        'the same recipient inside an ArrayRef still produces its stanza');
}

{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $header = Crypt::Age::Header->create($file_key, [$public]);

    my $marker = 'AGE-SECRET-KEY-1LEAKMARKER';

    for my $case (['a bare identity string', $marker],
                  ['undef',                  undef],
                  ['a HASH ref',             { $marker => 1 }]) {
        my ($what, $arg) = @$case;

        my ($err, $line, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            $line = __LINE__ + 1;
            eval { $header->unwrap_file_key($arg) };
            $err = $@;
        }

        like($err, qr/^\Q$identities_msg\E\b/,
            "$what is rejected by type, naming the parameter and the fix");
        unlike($err, qr/strict refs|ARRAY reference/,
            "$what no longer arrives as perl's own dereference error");
        ok(index($err, $marker) == -1,
            "$what leaves no key material in the message");
        ok(index($err, 'LEAKMARKER') == -1,
            "$what leaves no fragment of it either");
        unlike($err, qr/AGE-SECRET-KEY-1/i,
            "$what does not even name the identity prefix");
        is_deeply(\@warn, [],
            "$what reaches no dereference, so nothing warns out of Header.pm");
        unlike($err, qr{Crypt/Age/Header\.pm},
            "$what croaks: Header.pm is not blamed as the origin");
        my $where = quotemeta(__FILE__).' line '.$line;
        like($err, qr/$where/,
            "$what reports the caller position in this test file");
    }

    # The real thing, which is the likeliest way to reach this at all: one
    # identity, passed bare because a single identity does not look like a
    # list. Asserted on 31 characters, for the reason given above.
    # Assertions by index() inside ok() again, for the reason written out over
    # the same shape in the create block above: this is the one call in the
    # distribution whose wrong argument is a whole secret key, so nothing here
    # may print $err.
    {
        my ($err, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            eval { $header->unwrap_file_key($secret) };
            $err = $@;
        }

        ok(index($err, $identities_msg) == 0,
            'a bare, valid identity is a type error, not a silent success');
        ok(index($err, substr($secret, 0, 31)) == -1,
            'and no part of that secret key reaches the message');
        ok(index($err, 'AGE-SECRET-KEY-1') == -1,
            'not even the identity prefix');
        is(scalar @warn, 0, 'and nothing warns out of Header.pm');
    }

    # Counter-proof that the cases above measure the type check and not a
    # header that could not be unwrapped in the first place.
    is($header->unwrap_file_key([$secret]), $file_key,
        'the same identity inside an ArrayRef still unwraps the file key');
}

# Ticket #36, the last of this series. create checked the shape of its
# recipients list, above, but never its length. An empty ArrayRef passed every
# check and returned a header with no stanzas at all -- a version line and a
# MAC over it -- which wraps the file key for nobody. The spec's grammar is
# "header = v1-line 1*stanza end", one or more, so that is not a useless
# header, it is not a header. Measured on a file built from one: rage 0.12.1
# refuses it outright as "Unknown age format", age 1.2.1 parses it and then
# reports "no identity matched any of the recipients". Both are right, and both
# say so long after the file key -- which exists only inside that file -- was
# the last way back to the plaintext.
my $recipients_empty_msg = 'recipients must not be empty: this method wraps '
    .'the file key once per entry, so a header with no stanzas can never be '
    .'unwrapped, pass at least one recipient';

{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my ($err, $line, @warn);
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        local $@;
        $line = __LINE__ + 1;
        eval { Crypt::Age::Header->create($file_key, []) };
        $err = $@;
    }

    # The whole message up to croak's " at FILE line N." tail, not a prefix:
    # a wording that drifts, or picks up an interpolated suffix, stops
    # matching here.
    like($err, qr/^\Q$recipients_empty_msg\E(?: at |\z)/,
        'an empty recipients list is refused with exactly the documented message');
    is_deeply(\@warn, [], 'and nothing warns on the way');
    unlike($err, qr{Crypt/Age/Header\.pm},
        'it croaks: Header.pm is not blamed as the origin');
    my $where = quotemeta(__FILE__).' line '.$line;
    like($err, qr/$where/, 'and it reports the caller position in this test file');

    # The claim the assertion above replaces. Before the fix this call
    # returned a Crypt::Age::Header with zero stanzas, and it was that object
    # -- not an exception -- that made the file it started unrecoverable, so
    # the regression to guard against is a silent success, not a wrong text.
    my $built = eval { Crypt::Age::Header->create($file_key, []) };
    is($built, undef, 'and no header object is returned for an empty list');

    # The shape check fires first for anything that is not an ArrayRef, so the
    # two messages answer two different mistakes and cannot be confused.
    eval { Crypt::Age::Header->create($file_key, {}) };
    like($@, qr/^\Q$recipients_msg\E\b/,
        'a non-ArrayRef is still answered by the shape check, not the emptiness one');

    # Counter-proof that the block measures the emptiness check and not a
    # create that stopped working.
    my $header = Crypt::Age::Header->create($file_key, [$public]);
    is(scalar @{$header->stanzas}, 1,
        'a single-entry list still produces exactly one stanza');
    is($header->unwrap_file_key([$secret]), $file_key,
        'and the header it builds still unwraps');

    # unwrap_file_key, measured rather than assumed while fixing #36, and left
    # alone because it is not the same defect: an empty identity list is
    # already fatal there, so nothing is silently accepted and nothing is
    # lost. Pinned here so that stays true -- if this ever returns instead of
    # dying, the read side has grown the defect the write side just lost.
    my $unwrapped = eval { $header->unwrap_file_key([]) };
    is($unwrapped, undef, 'an empty identities list unwraps nothing');
    like($@, qr/No matching identity found/,
        'and is fatal already, which is why unwrap_file_key is not part of this fix');
}


# Ticket #39, the read-side counterpart to #36. The spec's header grammar is
# "header = v1-line 1*stanza end" (c2sp.org/age, "ABNF definition of file
# header") -- one or more stanzas, never zero -- and the prose above the ABNF
# says it again: "followed by one or more recipient stanzas". #36 made
# Header::create refuse to BUILD such a header on the write side; nothing
# enforced the same clause on the read side. A version line followed directly
# by the "---" MAC footer passed every check in parse_from_fh and returned a
# Header with an empty stanza list and a MAC that even verifies (it is a
# well-formed MAC over a header the grammar forbids) -- so the file only
# failed later, at unwrap_file_key, with "No matching identity found", naming
# the caller's keys as the cause of a file that is addressed to nobody at all.
#
# Measured on such a file: rage 0.12.1 refuses it at parse time as "Unknown
# age format"; age 1.2.1 parses it and reports "no identity matched any of the
# recipients". This implementation was the most permissive of the three; the
# guard added in parse_from_fh now refuses at the point the grammar is
# actually violated, with a message naming that cause, nothing else.
#
# The guard sits after the "no valid header MAC line" croak on purpose, so a
# TRUNCATED header -- a version line and nothing else -- keeps reporting that
# the handle ran out rather than being folded into the stanza-less message.
# That boundary is asserted below too, since it is the reason the guard lives
# where it does and not earlier in the function.
my $no_stanza_msg = 'age header must carry at least one recipient stanza: '
    .'the file key is wrapped once per stanza, so a header with none can '
    .'never be unwrapped by anyone, decrypt a file encrypted to at least one '
    .'recipient';

{
    my $mac64 = Crypt::Age::Stanza::encode_base64_no_padding("\x00" x 32);
    my $no_stanza_header = "age-encryption.org/v1\n--- $mac64\n";

    # parse_from_fh: the entry point the guard actually lives in.
    {
        open my $fh, '<:raw', \$no_stanza_header or die "open: $!";

        my ($err, $line, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            $line = __LINE__ + 1;
            eval { Crypt::Age::Header->parse_from_fh($fh) };
            $err = $@;
        }

        # Anchored end to end (only croak's own " at FILE line N." suffix may
        # follow), so nothing from the file's content -- and nothing else --
        # is interpolated into the documented message.
        like($err, qr/^\Q$no_stanza_msg\E(?: at |\z)/,
            'parse_from_fh refuses a complete, stanza-less header with exactly the documented message');
        is_deeply(\@warn, [], 'and nothing warns on the way');
        unlike($err, qr{Crypt/Age/Header\.pm},
            'it croaks: Header.pm is not blamed as the origin');
        my $where = quotemeta(__FILE__).' line '.$line;
        like($err, qr/$where/, 'and it reports the caller position in this test file');
    }

    # parse: the \$data/\$offset wrapper. It has no guard of its own here --
    # this checks that it inherits parse_from_fh's, not that it duplicates it.
    {
        my $offset = 0;
        my ($err, $line, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            $line = __LINE__ + 1;
            eval { Crypt::Age::Header->parse(\$no_stanza_header, \$offset) };
            $err = $@;
        }

        like($err, qr/^\Q$no_stanza_msg\E(?: at |\z)/,
            'parse refuses the same header with the same message');
        is_deeply(\@warn, [], 'and nothing warns on the way');
        my $where = quotemeta(__FILE__).' line '.$line;
        like($err, qr/$where/, 'reported through parse, the caller position is still this test file');
        is($offset, 0, 'and the offset ref is left untouched');
    }
}

# The truncated header: a version line and nothing after it. This must keep
# reporting "Invalid age file, no valid header MAC line" -- its cause is that
# the handle ran out, a different defect from a complete header that simply
# carries no stanzas. This is the split the guard's placement (after the
# MAC-line croak, not before it) exists to preserve.
{
    my $truncated = "age-encryption.org/v1\n";

    my $offset = 0;
    my $err = do {
        local $@;
        eval { Crypt::Age::Header->parse(\$truncated, \$offset) };
        $@;
    };

    like($err, qr/^Invalid age file, no valid header MAC line\b/,
        'a truncated header (version line only) still reports the MAC-line failure');
    unlike($err, qr/\Q$no_stanza_msg\E/,
        'and not the stanza-less message, even though it too parsed zero stanzas');
}

# Counter-proof: a regular one-stanza header still parses through both entry
# points, so the two blocks above measure the new guard and not a parser that
# stopped accepting valid headers.
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $header_text = Crypt::Age::Header->create($file_key, [$public])->to_string;

    my $offset = 0;
    my $parsed = Crypt::Age::Header->parse(\$header_text, \$offset);
    is(scalar @{$parsed->stanzas}, 1, 'a normal one-stanza header still parses via parse');
    is($parsed->unwrap_file_key([$secret]), $file_key,
        'and still unwraps the file key');

    open my $fh, '<:raw', \$header_text or die "open: $!";
    my $parsed_fh = Crypt::Age::Header->parse_from_fh($fh);
    is(scalar @{$parsed_fh->stanzas}, 1, 'and still parses via parse_from_fh directly');
}

# CVE-2026-85783 / karr #45: unwrap_file_key tries every identity against
# every stanza, and each attempt costs an X25519 scalar multiplication, an
# HKDF and a ChaCha20-Poly1305 open -- before any of the header can be
# authenticated, since the header MAC key is itself derived from the file key
# that unwrap_file_key is trying to recover. The stanza count was unbounded,
# so an attacker-controlled header with N stanzas bought N scalar
# multiplications per identity tried: measured on 0.003, ~3.9 ms per stanza,
# linear -- 4000 stanzas (382 KB) cost 15.7 s CPU before the header was even
# rejected. parse_from_fh now caps the stanza count via max_stanzas (default
# 128) and enforces it while still reading the header: at the start line of
# the first stanza over the limit, before that stanza's body, before any
# later stanza, and therefore before unwrap_file_key ever runs.
#
# A "fake" X25519 stanza below is built via ->new rather than ->wrap:
# BUILD's checks (one argument decoding to 32 bytes; a 32-byte body) are the
# only thing that has to hold for the parser to count it as a real X25519
# stanza, and neither check costs a scalar multiplication. That is what keeps
# these fixtures cheap regardless of how many stanzas they carry -- the cost
# this ticket is about lives entirely in unwrap_file_key, not in parsing, and
# these tests are built to demonstrate that unwrap_file_key never even runs.
{
    my $fake_x25519_stanza = sub {
        my ($i) = @_;
        my $arg  = Crypt::Age::Stanza::encode_base64_no_padding(chr(($i * 7 + 1) % 251) x 32);
        my $body = chr(($i * 13 + 2) % 251) x 32;
        return Crypt::Age::Stanza::X25519->new(args => [$arg], body => $body);
    };

    # Builds header text out of $fake_count fake stanzas followed by an
    # optional real one, MAC included. Without a file_key the MAC is a
    # placeholder -- fine for every case below that expects parse_from_fh to
    # fail before the MAC line is ever reached, which is every case that
    # does not pass one.
    my $build_capped_header = sub {
        my (%args) = @_;
        my @lines = ('age-encryption.org/v1');
        push @lines, $fake_x25519_stanza->($_)->to_string for 1 .. $args{fake_count};
        push @lines, $args{real_stanza}->to_string if $args{real_stanza};
        my $head_no_mac = join("\n", @lines, '---');
        my $mac = $args{file_key}
            ? Crypt::Age::Primitives->compute_header_mac($args{file_key}, $head_no_mac)
            : ("\x00" x 32);
        return $head_no_mac . ' ' . Crypt::Age::Stanza::encode_base64_no_padding($mac) . "\n";
    };

    # 1. The attack is refused: a header shaped like the CPANSec PoC --
    # version line, then one "-> X25519 <argument>" plus a body line per
    # stanza, then the MAC footer -- sized for a test suite rather than for
    # the report's own 4000-stanza reproduction. The boundary being pinned
    # here does not depend on scale, so 200 stanzas demonstrates it exactly
    # as well as 4000 does, without the 382 KB or the CPU time.
    {
        my $header_text = $build_capped_header->(fake_count => 200);
        open my $fh, '<:raw', \$header_text or die "open: $!";

        my @warn;
        my $header = do {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            eval { Crypt::Age::Header->parse_from_fh($fh) };
        };
        my $err = $@;

        ok(!defined $header, 'a 200-stanza header is refused by default');
        like($err, qr/\bmax_stanzas\b/, 'the message names max_stanzas');
        like($err, qr/\b128\b/, 'and the configured limit, 128 by default');
        is_deeply(\@warn, [], 'and nothing warns on the way');

        # Header content is attacker-controlled input. A short, recognizable
        # fragment -- not the whole 43-character argument -- of the specific
        # stanza that tripped the limit (the 129th, first over the default
        # cap) must not appear in the error. Deliberately a fragment and not
        # the whole value: Perl's own "Can't use string (...) as an ARRAY
        # ref" truncates an interpolated string at 32 characters, so a "does
        # the WHOLE value appear" assertion cannot fail even when part of it
        # actually leaked (see the strict-refs 32-character truncation note).
        my $offending_arg = $fake_x25519_stanza->(129)->args->[0];
        my $fragment = substr($offending_arg, 0, 16);
        unlike($err, qr/\Q$fragment\E/,
            'and no fragment of the offending stanza leaks into it');
    }

    # 2. The boundary is exact: 128 is accepted, 129 is not. The counts here
    # are hardcoded rather than read off Header's own DEFAULT_MAX_STANZAS --
    # deliberately: this is the test meant to go red the moment somebody
    # moves the default, not one that quietly tracks it.
    {
        my $at_cap   = $build_capped_header->(fake_count => 128);
        my $over_cap = $build_capped_header->(fake_count => 129);

        open my $fh1, '<:raw', \$at_cap or die "open: $!";
        my $header1 = eval { Crypt::Age::Header->parse_from_fh($fh1) };
        is($@, '', '128 stanzas parse without dying');
        is(scalar @{$header1->stanzas}, 128, 'and all 128 are present');

        open my $fh2, '<:raw', \$over_cap or die "open: $!";
        my $header2 = eval { Crypt::Age::Header->parse_from_fh($fh2) };
        ok(!defined $header2, '129 stanzas are refused');
        like($@, qr/\bmax_stanzas\b/, 'with a message naming max_stanzas');
        like($@, qr/\b128\b/, 'and the limit it exceeded');
    }

    # 3. The rejection happens in the parser, before any identity is
    # consulted and before the rest of the header is read -- the actual
    # point of the fix: unwrap_file_key's per-(identity, stanza) scalar
    # multiplication must never run on an over-limit header, not merely run
    # faster. Two independent, timing-free ways to show that, since wall
    # clock comparisons are flaky on CI and would not even show the right
    # thing (the fix is about work skipped entirely, not work done faster).
    #
    # a) A spy stands in for Stanza::X25519::unwrap and ::identity_keys --
    # the two per-attempt operations that do the actual scalar
    # multiplications (see the diff for this ticket) -- and must see zero
    # calls, even though the header below carries a stanza a genuinely
    # matching identity IS supplied for. An uncapped implementation would
    # call it; calling it at all is exactly the regression this guards.
    {
        my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
        my $file_key = Crypt::Age::Primitives->generate_file_key;
        my $real_stanza = Crypt::Age::Stanza::X25519->wrap($file_key, $public);

        my $header_text = $build_capped_header->(
            fake_count  => 128,
            real_stanza => $real_stanza,
            file_key    => $file_key,
        );

        my ($unwrap_calls, $identity_keys_calls) = (0, 0);
        {
            no warnings 'redefine';
            local *Crypt::Age::Stanza::X25519::unwrap = sub {
                $unwrap_calls++;
                die "spy: unwrap must not run once max_stanzas rejects the header\n";
            };
            local *Crypt::Age::Stanza::X25519::identity_keys = sub {
                $identity_keys_calls++;
                die "spy: identity_keys must not run once max_stanzas rejects the header\n";
            };

            # No payload needed: the rejection happens while parsing the
            # header, before _decrypt_fh ever gets to the nonce.
            eval {
                Crypt::Age->decrypt(ciphertext => $header_text, identities => [$secret]);
            };
        }
        my $err = $@;

        ok(length $err, 'decrypt of a 129-stanza header dies');
        like($err, qr/\bmax_stanzas\b/, 'refused for the stanza count, not a spy trip');
        is($unwrap_calls, 0, 'Stanza::X25519::unwrap is never called');
        is($identity_keys_calls, 0, 'Stanza::X25519::identity_keys is never called');

        # The identity is never even looked at before this croak fires, but
        # pin it anyway: a short, middle fragment (never the whole value --
        # again the 32-character truncation trap) of the real secret key
        # supplied to this same decrypt call must not appear in the error.
        my $secret_fragment = substr($secret, 20, 16);
        unlike($err, qr/\Q$secret_fragment\E/,
            'and no fragment of the identity leaks into it either');
    }

    # b) The 129th stanza's own start line is garbage that matches neither
    # the arg-line grammar nor the MAC footer, and nothing at all follows it
    # -- not a body line, not a MAC line, end of input. If the parser read
    # that far and tried to make sense of it, the error would name a
    # different failure (a bad start line, or a handle that ran out looking
    # for the MAC); getting the stanza-count message instead proves neither
    # of those code paths ran.
    {
        my @lines = ('age-encryption.org/v1');
        push @lines, $fake_x25519_stanza->($_)->to_string for 1 .. 128;
        push @lines, 'this is not a stanza line at all, nor the MAC footer';
        my $header_text = join("\n", @lines) . "\n";

        open my $fh, '<:raw', \$header_text or die "open: $!";
        my @warn;
        my $header = do {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            eval { Crypt::Age::Header->parse_from_fh($fh) };
        };
        my $err = $@;

        ok(!defined $header, 'a garbage 129th line still gets the header refused');
        like($err, qr/\bmax_stanzas\b/, 'refused for the stanza count');
        unlike($err, qr/Invalid age stanza/,
            'not because the garbage failed the arg-line grammar -- it was never checked');
        unlike($err, qr/no valid header MAC line/,
            'not because the handle ran out looking for the MAC -- it was never looked for');
        is_deeply(\@warn, [], 'and nothing warns on the way');
    }

    # 4. max_stanzas actually raises the limit, at both Header entry points.
    # (Crypt::Age->decrypt / decrypt_file / decrypt_filehandle forwarding the
    # option through to here is pinned in t/02-encrypt-decrypt.t.)
    {
        my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
        my $file_key = Crypt::Age::Primitives->generate_file_key;
        my $real_stanza = Crypt::Age::Stanza::X25519->wrap($file_key, $public);
        my $header_text = $build_capped_header->(
            fake_count  => 128,
            real_stanza => $real_stanza,
            file_key    => $file_key,
        );

        open my $fh, '<:raw', \$header_text or die "open: $!";
        my $rejected = eval { Crypt::Age::Header->parse_from_fh($fh) };
        ok(!defined $rejected, 'the default still refuses this same 129-stanza header');

        open my $fh2, '<:raw', \$header_text or die "open: $!";
        my $header = eval { Crypt::Age::Header->parse_from_fh($fh2, max_stanzas => 129) };
        is($@, '', 'max_stanzas => 129 accepts the same 129-stanza header');
        is(scalar @{$header->stanzas}, 129, 'and all 129 stanzas are present');
        is($header->unwrap_file_key([$secret]), $file_key,
            'and the real stanza -- last in the header -- still unwraps correctly');

        # The \$data/\$offset wrapper threads the option through too.
        my $offset = 0;
        my $via_parse = eval {
            Crypt::Age::Header->parse(\$header_text, \$offset, max_stanzas => 129);
        };
        is($@, '', 'parse($data, $offset, max_stanzas => 129) accepts it as well');
        is(scalar @{$via_parse->stanzas}, 129, 'with all 129 stanzas');
    }

    # max_stanzas itself must be a positive integer -- the documented failure
    # modes for the option, checked against a tiny header since none of these
    # cases are about the stanza count.
    {
        my $header_text = $build_capped_header->(fake_count => 6);

        for my $case (
            [0,     'max_stanzas => 0'],
            [-1,    'max_stanzas => -1'],
            [undef, 'max_stanzas => undef'],
            ['abc', "max_stanzas => 'abc'"],
        ) {
            my ($value, $label) = @$case;
            open my $fh, '<:raw', \$header_text or die "open: $!";
            my $header = eval { Crypt::Age::Header->parse_from_fh($fh, max_stanzas => $value) };
            ok(!defined $header, "$label is refused");
            like($@, qr/max_stanzas must be a positive integer/, "$label names the reason");
        }

        # The positional-argument mistake: parse_from_fh($fh, 300) is an odd
        # number of trailing elements, not a limit -- refused before it can
        # silently fall back to the default and reject a legitimate
        # 300-recipient file while telling the caller nothing about why.
        open my $fh, '<:raw', \$header_text or die "open: $!";
        my $header = eval { Crypt::Age::Header->parse_from_fh($fh, 300) };
        ok(!defined $header, 'a bare positional limit is refused');
        like($@, qr/named options/, 'and told to use max_stanzas => $n instead');
    }
}

done_testing;
