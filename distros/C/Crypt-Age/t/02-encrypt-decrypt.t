#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Crypt::Age;
use Crypt::Age::Header;
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::Age::Stanza::X25519;

# Basic roundtrip
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "Hello, World!";

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    ok(defined $encrypted, 'encryption succeeded');
    like($encrypted, qr/^age-encryption\.org\/v1\n/, 'encrypted data has age header');

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, $plaintext, 'roundtrip successful');
}

# Empty plaintext
{
    my ($public, $secret) = Crypt::Age->generate_keypair;

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => "",
        recipients => [$public],
    );

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, "", 'empty plaintext roundtrip');
}

# Large plaintext (multiple chunks)
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "x" x (64 * 1024 * 3 + 1000);  # ~192KB + 1000 bytes

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, $plaintext, 'large plaintext roundtrip');
}

# Binary data
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = join('', map { chr($_) } 0..255) x 10;

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, $plaintext, 'binary data roundtrip');
}

# Multiple recipients
{
    my ($public1, $secret1) = Crypt::Age->generate_keypair;
    my ($public2, $secret2) = Crypt::Age->generate_keypair;
    my $plaintext = "For multiple recipients";

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public1, $public2],
    );

    # Decrypt with first identity
    my $decrypted1 = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret1],
    );
    is($decrypted1, $plaintext, 'decrypt with first recipient');

    # Decrypt with second identity
    my $decrypted2 = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret2],
    );
    is($decrypted2, $plaintext, 'decrypt with second recipient');
}

# Wrong identity should fail
{
    my ($public1, $secret1) = Crypt::Age->generate_keypair;
    my ($public2, $secret2) = Crypt::Age->generate_keypair;

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => "Secret",
        recipients => [$public1],
    );

    eval {
        Crypt::Age->decrypt(
            ciphertext => $encrypted,
            identities => [$secret2],
        );
    };
    like($@, qr/No matching identity/, 'wrong identity fails');
}

# File operations
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "File content test\nWith newlines\n";

    my ($in_fh, $in_file) = tempfile(UNLINK => 1);
    print $in_fh $plaintext;
    close $in_fh;

    my (undef, $enc_file) = tempfile(UNLINK => 1);
    my (undef, $out_file) = tempfile(UNLINK => 1);

    Crypt::Age->encrypt_file(
        input      => $in_file,
        output     => $enc_file,
        recipients => [$public],
    );

    ok(-s $enc_file > 0, 'encrypted file created');

    Crypt::Age->decrypt_file(
        input      => $enc_file,
        output     => $out_file,
        identities => [$secret],
    );

    open my $fh, '<:raw', $out_file;
    my $decrypted = do { local $/; <$fh> };
    close $fh;

    is($decrypted, $plaintext, 'file roundtrip successful');
}

# Filehandle operations
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "File content test\nWith newlines\n";

    my ($in_fh, $in_file) = tempfile(UNLINK => 1);
    print $in_fh $plaintext;
    close $in_fh;

    my $enc_data = '';
    {
        open my $in_fh, '<', $in_file or die "open($in_file): $!";
        open my $out_fh, '>', \$enc_data or die "open() string for output: $!";
        Crypt::Age->encrypt_filehandle(
            input      => $in_fh,
            output     => $out_fh,
            recipients => [$public],
        );
    }
    ok length($enc_data), 'encrypted data generated';

    my $decrypted;
    {
        my ($enc_fh, $enc_file) = tempfile(UNLINK => 1);
        print $enc_fh $enc_data;
        close $enc_fh;
        $enc_fh = undef;
        open $enc_fh, '<', $enc_file or die "open($enc_file): $!";

        my ($out_fh, $out_file) = tempfile(UNLINK => 1);
        Crypt::Age->decrypt_filehandle(
            input      => $enc_fh,
            output     => $out_fh,
            identities => [$secret],
        );
        close $out_fh;
        close $enc_fh;

        open my $fh, '<:raw', $out_file;
        $decrypted = do { local $/; <$fh> };
        close $fh;

    }
    is($decrypted, $plaintext, 'file roundtrip successful');

}

# Truncated files. On main (commit a830d60, before PR #3) a payload-less
# file -- a valid header and nonce followed by zero payload bytes -- decrypted
# silently to the empty string (karr #6): decrypt_payload's substr-arithmetic
# loop never ran for zero remaining bytes. The spec requires signaling an
# error when EOF is reached without a final chunk. PR #3's read()/eof()-based
# payload path croaks instead, incidentally via AEAD tag verification on an
# empty/short tag. The other two cases (short nonce, payload shorter than the
# tag) are adjacent truncation shapes for the same read/eof path; both already
# raised an error before PR #3 too, so they are safety-net coverage rather
# than a red/green regression, but are cheap to pin down alongside karr #6.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "x" x 128;

    my $full = Crypt::Age->encrypt(plaintext => $plaintext, recipients => [$public]);

    my $offset = 0;
    Crypt::Age::Header->parse(\$full, \$offset);   # locate the header/payload boundary
    my $header = substr($full, 0, $offset);
    my $nonce  = substr($full, $offset, 16);
    is(length($nonce), 16, 'fixture: full nonce is 16 bytes');

    # (a) header + full nonce, zero payload bytes at all (karr #6).
    {
        my $ct = $header . $nonce;
        my $got = eval { Crypt::Age->decrypt(ciphertext => $ct, identities => [$secret]) };
        ok(!defined $got, 'payload-less file does not silently decrypt');
        ok($@, 'payload-less file raises an error');
    }

    # (b) nonce truncated to 8 bytes, nothing following.
    {
        my $ct = $header . substr($nonce, 0, 8);
        my $got = eval { Crypt::Age->decrypt(ciphertext => $ct, identities => [$secret]) };
        ok(!defined $got, 'truncated 8-byte nonce does not decrypt');
        ok($@, 'truncated nonce raises an error');
    }

    # (c) payload present but shorter than the 16-byte AEAD tag.
    {
        my $ct = $header . $nonce . substr($full, $offset + 16, 5);
        my $got = eval { Crypt::Age->decrypt(ciphertext => $ct, identities => [$secret]) };
        ok(!defined $got, 'payload shorter than the tag size does not decrypt');
        ok($@, 'short payload raises an error');
    }
}

# Error handling
{
    eval { Crypt::Age->encrypt(recipients => ['age1abc']) };
    like($@, qr/plaintext required/, 'encrypt requires plaintext');

    eval { Crypt::Age->encrypt(plaintext => 'x') };
    like($@, qr/recipients required/, 'encrypt requires recipients');

    eval { Crypt::Age->encrypt(plaintext => 'x', recipients => []) };
    like($@, qr/at least one recipient/, 'encrypt requires non-empty recipients');

    eval { Crypt::Age->decrypt(identities => ['AGE-SECRET-KEY-1ABC']) };
    like($@, qr/ciphertext required/, 'decrypt requires ciphertext');
}

# Ticket #19 regression: Header::create dispatches recipients with
# /^age1/i, matching the /^AGE-SECRET-KEY-1/i already used on the identity
# side. Before the fix the recipient dispatch had no /i, so
# Crypt::Age->encrypt(recipients => [uc($public)]) died with "Unsupported
# recipient format" even though Keys::decode_public_key(uc($public)) alone
# accepted the same string -- the read side kept the promise, the write
# side did not.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "Ticket #19 regression fixture";

    # (1) an all-uppercase AGE1... recipient encrypts and round-trips with
    # the matching identity.
    my $encrypted = eval {
        Crypt::Age->encrypt(plaintext => $plaintext, recipients => [uc($public)]);
    };
    is($@, '', 'an all-uppercase AGE1... recipient encrypts without dying');
    my $decrypted = Crypt::Age->decrypt(ciphertext => $encrypted, identities => [$secret]);
    is($decrypted, $plaintext,
        'ciphertext for an uppercase recipient decrypts with the matching identity');

    # (2) a mixed-case recipient is rejected, but specifically by the
    # bech32 mixed-case guard, not by the "Unsupported recipient format"
    # branch. That distinction is the regression: it shows the string
    # passed the /^age1/i prefix test and was only then rejected inside
    # decode_public_key -- a test that only checked "dies somehow" would
    # not catch the prefix test itself going missing.
    my $mixed = 'Age1' . substr($public, 4);
    ok($mixed =~ /^age1/i && $mixed ne lc($mixed) && $mixed ne uc($mixed),
        'fixture: mixed-case recipient matches the prefix case-insensitively and is genuinely mixed case')
        or die 'fixture assumption broken -- generated public key data has no lowercase letter to mix';

    eval { Crypt::Age->encrypt(plaintext => $plaintext, recipients => [$mixed]) };
    like($@, qr/Invalid bech32: mixed case/,
        'a mixed-case recipient dies with the bech32 mixed-case guard');
    unlike($@, qr/Unsupported recipient format/,
        'and not with the encrypt-side "Unsupported recipient format" rejection');

    # (3) an all-lowercase identity still decrypts -- the /i on the
    # identity side predates #19 and must stay untouched by it.
    my $encrypted2 = Crypt::Age->encrypt(plaintext => $plaintext, recipients => [$public]);
    my $decrypted2 = Crypt::Age->decrypt(ciphertext => $encrypted2, identities => [lc($secret)]);
    is($decrypted2, $plaintext, 'an all-lowercase identity still decrypts');
}

# Ticket #22 regression, the version-line half: parse_from_fh's version
# check used to interpolate the first line straight into the croak
# ("Invalid age version: $version_line"). That is unbounded when the input
# has no newline at all: parse_from_fh reads under `local $/ = "\n"`, so
# with no newline to stop at, <$fh> reads to EOF and the *entire* input
# becomes "the first line". Feed decrypt a plaintext string with no
# trailing newline that cannot possibly be a real age header, and confirm
# none of it survives into the error.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $not_an_age_file = 'this is definitely not an age header and has no newline at all';
    ok(index($not_an_age_file, "\n") == -1, 'fixture: input contains no newline');

    my $err = do {
        local $@;
        eval { Crypt::Age->decrypt(ciphertext => $not_an_age_file, identities => [$secret]) };
        $@;
    };

    ok($err, 'decrypting a no-newline non-age input dies');
    like($err,
        qr/^Invalid age version: expected the literal age-encryption\.org\/v1 version line/,
        'the message names the expected literal version line');
    ok(index($err, $not_an_age_file) == -1,
        'none of the input content appears in the error');
}

# Ticket #26, carrying the #24 regression: the string API takes bytes. Perl
# refuses to map a string holding a code point above 0xFF into an in-memory
# handle, so handing encrypt/decrypt a character (decoded) string used to fail
# at the *input* open. #24 made that open croak instead of die, which put the
# blame on the caller -- those location assertions are kept below, they are
# the point of the block. #26 replaces what the caller is told: EINVAL from an
# in-memory open ("open on input string: Invalid argument") names no cause and
# suggests no fix, so encrypt/decrypt now run perl's own downgrade test first
# and say what is wrong. The open is no longer reached on this path, so perl's
# "code points over 0xFF" warning is gone too -- asserted, not suppressed.
#
# The output-side opens (on a lexical the method owns, written through :raw)
# have no caller-reachable failure and are deliberately not covered here.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $wide = "\x{100} not bytes";

    my ($enc_err, $enc_line, @enc_warn);
    {
        local $SIG{__WARN__} = sub { push @enc_warn, $_[0] };
        local $@;
        $enc_line = __LINE__ + 1;
        eval { Crypt::Age->encrypt(plaintext => $wide, recipients => [$public]) };
        $enc_err = $@;
    }

    ok($enc_err, 'encrypt with a wide-character plaintext dies');
    like($enc_err,
        qr/^plaintext must be a byte string: it holds a code point above 0xFF, encode it before passing it in\b/,
        'the message names the cause and the fix, not EINVAL');
    unlike($enc_err, qr/Invalid argument/,
        'encrypt no longer passes perl\'s EINVAL through');
    is_deeply(\@enc_warn, [],
        'the check runs before the open, so perl emits no >0xFF warning');
    unlike($enc_err, qr{Crypt/Age\.pm},
        'encrypt croaks: Crypt/Age.pm is not blamed as the origin');
    my $enc_where = quotemeta(__FILE__).' line '.$enc_line;
    like($enc_err, qr/$enc_where/,
        'encrypt reports the caller position in this test file');
    ok(index($enc_err, 'not bytes') == -1,
        'no part of the plaintext appears in the error');

    my ($dec_err, $dec_line, @dec_warn);
    {
        local $SIG{__WARN__} = sub { push @dec_warn, $_[0] };
        local $@;
        $dec_line = __LINE__ + 1;
        eval { Crypt::Age->decrypt(ciphertext => $wide, identities => [$secret]) };
        $dec_err = $@;
    }

    ok($dec_err, 'decrypt with a wide-character ciphertext dies');
    like($dec_err,
        qr/^ciphertext must be a byte string: it holds a code point above 0xFF, read it with :raw rather than decoding it\b/,
        'the message names the cause and the fix, not EINVAL');
    unlike($dec_err, qr/Invalid argument/,
        'decrypt no longer passes perl\'s EINVAL through');
    is_deeply(\@dec_warn, [],
        'the check runs before the open, so perl emits no >0xFF warning');
    unlike($dec_err, qr{Crypt/Age\.pm},
        'decrypt croaks: Crypt/Age.pm is not blamed as the origin');
    my $dec_where = quotemeta(__FILE__).' line '.$dec_line;
    like($dec_err, qr/$dec_where/,
        'decrypt reports the caller position in this test file');
}

# Ticket #26 counter-proof: the check must reject only what perl cannot map,
# and nothing else. The three cases below all have to keep working, and the
# second is the one that rules out utf8::is_utf8 as the test -- it reports the
# internal representation, so an upgraded string answers true while holding
# nothing above 0xFF, and using it here would reject perfectly good data.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;

    my %case = (
        'every byte 0x00-0xFF'      => join('', map { chr } 0 .. 255),
        'upgraded, all <= 0xFF'     => do { my $s = "caf\x{e9} \x{ff}"; utf8::upgrade($s); $s },
        'upgraded, pure ASCII'      => do { my $s = 'plain ascii'; utf8::upgrade($s); $s },
    );

    for my $name (sort keys %case) {
        my $plaintext = $case{$name};
        my $before    = $plaintext;
        my $flagged   = utf8::is_utf8($plaintext) ? 1 : 0;

        my @warn;
        my $round = do {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            Crypt::Age->decrypt(
                ciphertext => Crypt::Age->encrypt(
                    plaintext  => $plaintext,
                    recipients => [$public],
                ),
                identities => [$secret],
            );
        };

        is($round, $before, "$name: round-trips unchanged");
        ok(!utf8::is_utf8($round), "$name: decrypt returns a byte string");
        is_deeply(\@warn, [], "$name: no warnings on the way through");

        # encrypt downgrades its own copy, never the caller's scalar: %args and
        # the lexical are both copies, and the value would survive either way,
        # but a refactor that took \$args{plaintext} directly would show here.
        is($plaintext, $before, "$name: the caller's string keeps its value");
        is(utf8::is_utf8($plaintext) ? 1 : 0, $flagged,
            "$name: the caller's string keeps its representation");
    }
}

# Ticket #27: the LIMITATIONS section of Crypt::Age quotes the recipient
# rejection. #25 gave that message two suffixes filling one "what arrived
# instead" slot, and the quote kept only the base form. A POD that quotes an
# error message is worth exactly its accuracy, so pin both ends: what the code
# emits, and what the section claims it emits. The messages are taken through
# the public API here because that is the surface the section documents;
# t/03-header.t pins the same three at Crypt::Age::Header->create.
{
    my ($public)        = Crypt::Age->generate_keypair;
    my (undef, $secret) = Crypt::Age->generate_keypair;

    my $base = 'Unsupported recipient format at index N: expected an age1 recipient';

    my %case = (
        'an unrelated string' => ['not-a-recipient', ''],
        'a secret key'        => [$secret,           ', got an AGE-SECRET-KEY-1 identity'],
        'an undef entry'      => [undef,             ', got undef'],
    );

    for my $name (sort keys %case) {
        my ($bad, $suffix) = @{$case{$name}};

        my $err = do {
            local $@;
            eval {
                Crypt::Age->encrypt(
                    plaintext  => 'x',
                    recipients => [$public, $bad],
                );
            };
            $@;
        };

        # The whole message, not a prefix of it: anchoring on croak's " at FILE
        # line N." tail is what makes the empty-suffix case a counter-proof --
        # a suffix leaking into it would no longer match.
        (my $expect = $base.$suffix) =~ s/\bindex N\b/index 1/;
        like($err, qr/^\Q$expect\E(?: at |\z)/,
            "$name: encrypt reports exactly the documented message");
    }

    # Read the module that was actually loaded, not a path guessed from cwd.
    my $flat = do {
        open my $fh, '<:raw', $INC{'Crypt/Age.pm'}
            or die "cannot read the loaded Crypt::Age: $!";
        local $/;
        my $source = <$fh>;
        $source =~ s/\s+/ /g;    # the POD wraps; the quoted message does not
        $source;
    };

    for my $quoted ($base, map { $case{$_}[1] } grep { length $case{$_}[1] } keys %case) {
        ok(index($flat, $quoted) >= 0,
            'Crypt::Age POD quotes "'.$quoted.'"');
    }
}

# Ticket #37: Crypt::Age and Crypt::Age::Header used to answer the same caller
# mistake in two different wordings -- "recipients must be an array ref" here
# against "recipients must be an ArrayRef: ..." one layer down -- and a caller
# who hit one and searched for the other found nothing. The guards here are the
# ones that always fire: _encrypt_fh and _decrypt_fh check the shape before
# handing the list to create and unwrap_file_key, so Header's messages are
# unreachable through the public API and these two are what callers actually
# see. Nothing about the checks moved; only their text.
#
# undef is deliberately not among the shapes below. On every public path the
# "recipients required" / "identities required" defined-or guard catches it one
# statement earlier, so it never reaches these croaks -- pre-existing behaviour
# this ticket does not touch, and asserting the ArrayRef message for it would
# assert something false.
#
# The markers are 23 and 26 characters. Perl truncates the string it quotes in
# "Can't use string (...) as an ARRAY ref" at 32, so a longer marker could not
# appear even with both guards gone, and a "nothing leaked" assertion built on
# it would pass without being able to fail.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $ciphertext = Crypt::Age->encrypt(
        plaintext  => 'ticket #37 fixture',
        recipients => [$public],
    );

    my $recipients_msg = 'recipients must be an ArrayRef: this method encrypts '
        .'to every entry, pass [$recipient] rather than $recipient';
    my $identities_msg = 'identities must be an ArrayRef: this method decrypts '
        .'with whichever entry matches, pass [$identity] rather than $identity';

    my $rcpt_marker = 'age1LEAKMARKERRECIPIENT';
    my $idnt_marker = 'AGE-SECRET-KEY-1LEAKMARKER';

    # croak reports the frame that called encrypt/decrypt, which is the
    # closure below and not the eval that runs it. Each closure therefore
    # records its own line, on the same physical line as the call, so the
    # position assertion stays exact when this block is edited.
    my $call_line;
    my @cases = (
        {   side   => 'encrypt',
            msg    => $recipients_msg,
            marker => $rcpt_marker,
            call   => sub {
                $call_line = __LINE__; Crypt::Age->encrypt(plaintext => 'x', recipients => $_[0]);
            },
            shapes => [ ['a bare recipient string', $rcpt_marker],
                        ['a HASH ref',              { $rcpt_marker => 1 }],
                        ['a SCALAR ref',            \$rcpt_marker] ],
        },
        {   side   => 'decrypt',
            msg    => $identities_msg,
            marker => $idnt_marker,
            call   => sub {
                $call_line = __LINE__; Crypt::Age->decrypt(ciphertext => $ciphertext, identities => $_[0]);
            },
            shapes => [ ['a bare identity string', $idnt_marker],
                        ['a HASH ref',             { $idnt_marker => 1 }],
                        ['a SCALAR ref',           \$idnt_marker] ],
        },
    );

    for my $case (@cases) {
        my ($side, $msg, $marker) = @{$case}{qw( side msg marker )};

        for my $shape (@{$case->{shapes}}) {
            my ($what, $arg) = @$shape;

            my ($err, @warn);
            {
                local $SIG{__WARN__} = sub { push @warn, $_[0] };
                local $@;
                undef $call_line;
                eval { $case->{call}->($arg) };
                $err = $@;
            }

            # The whole message up to croak's " at FILE line N." tail, not a
            # prefix: a wording that drifts back towards Header's, or picks up
            # an interpolated suffix, stops matching here.
            like($err, qr/^\Q$msg\E(?: at |\z)/,
                "$side: $what is rejected with exactly the documented message");
            unlike($err, qr/strict refs|ARRAY reference/,
                "$side: $what no longer arrives as perl's own dereference error");
            ok(index($err, $marker) == -1,
                "$side: $what leaves no caller input in the message");
            is_deeply(\@warn, [],
                "$side: $what reaches no dereference, so nothing warns");
            unlike($err, qr{Crypt/Age\.pm},
                "$side: $what croaks -- Crypt/Age.pm is not blamed as the origin");
            my $where = quotemeta(__FILE__).' line '.$call_line;
            like($err, qr/$where/,
                "$side: $what reports the caller position in this test file");
        }
    }

    # And the POD claims what the code emits, the same pin ticket #27 put on
    # the recipient rejection above. Read the module that was actually loaded,
    # not a path guessed from cwd.
    my $flat = do {
        open my $pod_fh, '<:raw', $INC{'Crypt/Age.pm'}
            or die "cannot read the loaded Crypt::Age: $!";
        local $/;
        my $source = <$pod_fh>;
        $source =~ s/\s+/ /g;    # the POD wraps; the quoted message does not
        $source;
    };

    for my $quoted ($recipients_msg, $identities_msg) {
        ok(index($flat, $quoted) >= 0,
            'Crypt::Age POD quotes "'.$quoted.'"');
    }
}

# Ticket #36 at this layer. The emptiness guards in _encrypt_fh and _decrypt_fh
# predate the message form the distribution settled on across #31-#34 and #37,
# and #36 adds the matching guard one layer down in Header::create. Leaving
# these two on "at least one recipient required" would have rebuilt, for the
# empty-list case, exactly the divergence #37 had just removed for the shape
# case -- so all three move together and the empty list now reads one way
# whichever layer catches it.
#
# What moved is the text. Both guards accept and reject exactly what they
# accepted and rejected before, and both still fire before any file key is
# generated or any header is parsed.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $ciphertext = Crypt::Age->encrypt(
        plaintext  => 'ticket #36 fixture',
        recipients => [$public],
    );

    my $recipients_empty_msg = 'recipients must not be empty: this method '
        .'encrypts to every entry, so with none the result can never be '
        .'decrypted, pass at least one recipient';
    my $identities_empty_msg = 'identities must not be empty: this method '
        .'decrypts with whichever entry matches, so with none there is '
        .'nothing that could match, pass at least one identity';

    # _encrypt_fh and _decrypt_fh hold the only copy of each guard, so every
    # public entry point below has to arrive at the same message. croak
    # reports the frame that called the public method, which is the closure
    # and not the eval running it, so each closure records its own line on the
    # same physical line as the call.
    my $call_line;
    my @cases = (
        {   what => 'encrypt',
            msg  => $recipients_empty_msg,
            call => sub {
                $call_line = __LINE__; Crypt::Age->encrypt(plaintext => 'x', recipients => []);
            },
        },
        {   what => 'encrypt_filehandle',
            msg  => $recipients_empty_msg,
            call => sub {
                my $in = 'x'; my $out = '';
                open my $ifh, '<:raw', \$in  or die $!;
                open my $ofh, '>:raw', \$out or die $!;
                $call_line = __LINE__; Crypt::Age->encrypt_filehandle(input => $ifh, output => $ofh, recipients => []);
            },
        },
        {   what => 'decrypt',
            msg  => $identities_empty_msg,
            call => sub {
                $call_line = __LINE__; Crypt::Age->decrypt(ciphertext => $ciphertext, identities => []);
            },
        },
        {   what => 'decrypt_filehandle',
            msg  => $identities_empty_msg,
            call => sub {
                my $out = '';
                open my $ifh, '<:raw', \$ciphertext or die $!;
                open my $ofh, '>:raw', \$out       or die $!;
                $call_line = __LINE__; Crypt::Age->decrypt_filehandle(input => $ifh, output => $ofh, identities => []);
            },
        },
    );

    for my $case (@cases) {
        my ($what, $msg) = @{$case}{qw( what msg )};

        my ($err, @warn);
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            undef $call_line;
            eval { $case->{call}->() };
            $err = $@;
        }

        like($err, qr/^\Q$msg\E(?: at |\z)/,
            "$what: an empty list is rejected with exactly the documented message");
        is_deeply(\@warn, [], "$what: and nothing warns on the way");
        unlike($err, qr{Crypt/Age\.pm},
            "$what: it croaks -- Crypt/Age.pm is not blamed as the origin");
        my $where = quotemeta(__FILE__).' line '.$call_line;
        like($err, qr/$where/,
            "$what: and it reports the caller position in this test file");
    }

    # The guard fires before anything is written, so an empty list costs the
    # caller nothing beyond the exception -- no header, no nonce, no partial
    # file. This is what makes it a rejection rather than a truncation.
    {
        my $in = 'x'; my $out = 'sentinel';
        open my $ifh, '<:raw', \$in  or die $!;
        open my $ofh, '>:raw', \$out or die $!;
        eval { Crypt::Age->encrypt_filehandle(input => $ifh, output => $ofh, recipients => []) };
        is($out, '', 'encrypt_filehandle writes no byte before refusing an empty list');
    }

    # Counter-proof that the block measures the emptiness guards and not an
    # API that stopped working.
    is(Crypt::Age->decrypt(ciphertext => $ciphertext, identities => [$secret]),
        'ticket #36 fixture', 'a single-entry list still round-trips');

    # And the POD claims what the code emits, the same pin #27 and #37 put on
    # their messages. Read the module that was actually loaded, not a path
    # guessed from cwd.
    my $flat = do {
        open my $pod_fh, '<:raw', $INC{'Crypt/Age.pm'}
            or die "cannot read the loaded Crypt::Age: $!";
        local $/;
        my $source = <$pod_fh>;
        $source =~ s/\s+/ /g;    # the POD wraps; the quoted message does not
        $source;
    };

    for my $quoted ($recipients_empty_msg, $identities_empty_msg) {
        ok(index($flat, $quoted) >= 0,
            'Crypt::Age POD quotes "'.$quoted.'"');
    }
}

# CVE-2026-85783 / karr #45: max_stanzas is Crypt::Age::Header's cap on how
# many recipient stanzas a header may carry (default 128; t/03-header.t pins
# the cap itself, the exact boundary, and the determinism of its rejection).
# decrypt, decrypt_file and decrypt_filehandle all take the same option and
# must actually forward it to Header::parse_from_fh rather than quietly
# keeping their own default -- that forwarding, at all three entry points, is
# what this block pins.
{
    # A "fake" X25519 stanza, built via ->new rather than ->wrap: BUILD's
    # cheap length checks are all that is needed for the parser to count it
    # as a real X25519 stanza, so 128 of them cost no scalar multiplication
    # at all. Only the one real stanza -- last in the header -- does.
    my $fake_x25519_stanza = sub {
        my ($i) = @_;
        my $arg  = Crypt::Age::Stanza::encode_base64_no_padding(chr(($i * 7 + 1) % 251) x 32);
        my $body = chr(($i * 13 + 2) % 251) x 32;
        return Crypt::Age::Stanza::X25519->new(args => [$arg], body => $body);
    };

    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $file_key    = Crypt::Age::Primitives->generate_file_key;
    my $real_stanza = Crypt::Age::Stanza::X25519->wrap($file_key, $public);

    my @lines = ('age-encryption.org/v1');
    push @lines, $fake_x25519_stanza->($_)->to_string for 1 .. 128;
    push @lines, $real_stanza->to_string;
    my $head_no_mac = join("\n", @lines, '---');
    my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $head_no_mac);
    my $header_text = $head_no_mac.' '.Crypt::Age::Stanza::encode_base64_no_padding($mac)."\n";

    my $plaintext    = 'max_stanzas propagation check';
    my $nonce        = Crypt::Age::Primitives->generate_payload_nonce;
    my $payload_key  = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);
    my $payload      = Crypt::Age::Primitives->encrypt_payload($payload_key, $plaintext);
    my $ciphertext   = "$header_text$nonce$payload";

    # decrypt
    my $rejected = eval {
        Crypt::Age->decrypt(ciphertext => $ciphertext, identities => [$secret]);
    };
    ok(!defined $rejected, 'decrypt refuses a 129-stanza file by default');
    like($@, qr/\bmax_stanzas\b/, 'decrypt: the default refusal names max_stanzas');

    my $decrypted = Crypt::Age->decrypt(
        ciphertext  => $ciphertext,
        identities  => [$secret],
        max_stanzas => 129,
    );
    is($decrypted, $plaintext, 'decrypt with max_stanzas => 129 recovers the plaintext');

    # decrypt_file
    my ($enc_fh, $enc_file) = tempfile(UNLINK => 1);
    binmode $enc_fh, ':raw';
    print $enc_fh $ciphertext;
    close $enc_fh;

    my (undef, $out_default) = tempfile(UNLINK => 1);
    my $file_rejected = eval {
        Crypt::Age->decrypt_file(input => $enc_file, output => $out_default, identities => [$secret]);
    };
    ok(!defined $file_rejected, 'decrypt_file refuses the same file by default');
    like($@, qr/\bmax_stanzas\b/, 'decrypt_file: the default refusal names max_stanzas');

    my (undef, $out_raised) = tempfile(UNLINK => 1);
    Crypt::Age->decrypt_file(
        input       => $enc_file,
        output      => $out_raised,
        identities  => [$secret],
        max_stanzas => 129,
    );
    open my $out_fh, '<:raw', $out_raised or die "open($out_raised): $!";
    my $file_plaintext = do { local $/; <$out_fh> };
    close $out_fh;
    is($file_plaintext, $plaintext, 'decrypt_file with max_stanzas => 129 recovers the plaintext');

    # decrypt_filehandle
    open my $ifh, '<:raw', \$ciphertext or die $!;
    my $handle_out = '';
    open my $ofh, '>:raw', \$handle_out or die $!;
    my $handle_rejected = eval {
        Crypt::Age->decrypt_filehandle(input => $ifh, output => $ofh, identities => [$secret]);
    };
    ok(!defined $handle_rejected, 'decrypt_filehandle refuses the same bytes by default');
    like($@, qr/\bmax_stanzas\b/, 'decrypt_filehandle: the default refusal names max_stanzas');

    open $ifh, '<:raw', \$ciphertext or die $!;
    $handle_out = '';
    open $ofh, '>:raw', \$handle_out or die $!;
    Crypt::Age->decrypt_filehandle(
        input       => $ifh,
        output      => $ofh,
        identities  => [$secret],
        max_stanzas => 129,
    );
    is($handle_out, $plaintext, 'decrypt_filehandle with max_stanzas => 129 recovers the plaintext');
}

done_testing;
