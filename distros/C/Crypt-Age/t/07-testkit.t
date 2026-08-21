#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Digest::SHA qw(sha256_hex);
use IO::Uncompress::Inflate qw(inflate $InflateError);
use Crypt::Age;

# The upstream age test kit (C2SP/CCTV, age/testdata) as a compatibility proof
# that does not need a real `age`/`rage` binary on PATH. See t/testkit/README.md
# for provenance (source commit, license, update procedure) and the upstream
# age/README.md test file format description this runner implements.
#
# Each vector is a text header of "key: value" lines, a blank line, then an
# age-encrypted file (optionally zlib-compressed). Unknown header keys are
# ignored, per the upstream README -- this runner only ever looks up the keys
# it knows about (expect, payload, identity, passphrase, armored, compressed)
# and never rejects a vector for carrying an extra one (comment, file key).
#
# WHAT IS SKIPPED, AND WHY IT IS DECIDED FROM CONTENT, NOT THE FILENAME
# -----------------------------------------------------------------------
# This distribution implements exactly one recipient type (X25519) and no
# ASCII armor. The upstream README explicitly allows ignoring vectors that
# exercise unimplemented features, so:
#
#   * a vector whose own header says "armored: yes" is skipped -- armor is not
#     implemented at all;
#   * a vector that carries a "passphrase:" key, OR whose actual age-file
#     stanza lines (scanned from the real, decompressed body -- never the
#     vector's filename) name the "scrypt" or "mlkem768x25519" recipient
#     type, is skipped -- neither scrypt/passphrase nor the post-quantum
#     hybrid recipient is implemented.
#
# Deciding this from the filename would be fragile (a future rename or a new
# vector breaks it silently) and, worse, wrong in ways that matter: several
# vectors combine a supported and an unsupported stanza in the same file
# (scrypt_and_x25519, hybrid_and_x25519, hybrid_x25519_arg) specifically to
# test how an implementation must treat that combination, and a name-based
# rule would run some of these for the wrong reason or skip others that this
# distribution's own X25519 path is perfectly able to exercise correctly
# (hybrid_x25519_arg has no non-X25519 stanza at all -- it targets X25519
# argument validation, not the hybrid recipient, and must run).
#
# An unrecognized stanza type that ISN'T scrypt or mlkem768x25519 (the
# testkit's "grease" vectors, and stanza_valid_characters's battery of
# type-name characters) is deliberately NOT a skip reason: the spec requires
# implementations to ignore stanzas of unknown type outright, and
# Crypt::Age::Header already does, so those vectors exercise real, already-
# implemented behaviour and must run.
#
# CLASSIFYING A FAILURE: WHAT OUR PUBLIC API ACTUALLY LETS US TELL APART
# -----------------------------------------------------------------------
# The testkit's `expect` values distinguish five failure classes (header
# failure, no match, HMAC failure, payload failure, armor failure -- armor is
# always skipped here). Crypt::Age's public decrypt/decrypt_filehandle raise
# plain croak() strings, not a typed exception hierarchy, and that -- not any
# choice made in this runner -- is the actual limit on how finely a caller of
# this distribution can ever distinguish these classes. This runner does not
# reach into Crypt::Age::Header or ::Primitives to get a better answer than a
# real caller has; it classifies the same croak text a real caller sees:
#
#   * no die at all                                        -> "success"
#   * "No matching identity found"                         -> "no_match_or_hmac"
#       Header::unwrap_file_key raises this exact message whether no stanza
#       could be unwrapped at all (spec: "no match") or a stanza *did* unwrap
#       but the header MAC then failed to verify (spec: "HMAC failure") --
#       both loop iterations just fall through to the same croak. This
#       runner accepts either expect value for this bucket and does not
#       pretend to a distinction the API does not draw.
#   * "Payload authentication failed at chunk N"            -> "payload"
#       Accepts only expect = "payload failure".
#   * "end of file reached before getting nonce"            -> "nonce"
#       Raised by Crypt::Age::_decrypt_fh after a successful header parse and
#       identity match, once it tries to read the 16-byte payload nonce and
#       finds fewer bytes (stream_no_nonce, stream_short_nonce). Structurally
#       this happens on our reader's payload-reading side of the header/
#       payload boundary, but the testkit's own generators classify both
#       vectors as "header failure". This runner accepts either expect value
#       for this one specific message rather than forcing an answer neither
#       the spec's own test data nor our API cleanly supports.
#   * anything else                                         -> "header"
#       Every other die -- a syntax error from Header::parse_from_fh, a
#       Crypt::Age::Stanza::X25519 BUILD validation failure, an X25519 low-
#       order-point rejection, a malformed base64 body -- happens before or
#       during header interpretation and before any payload byte is touched.
#       Accepts only expect = "header failure".
#
# For every vector that carries a `payload` hash (success and payload-failure
# vectors), this runner also checks that hash against SHA-256 of exactly the
# bytes Crypt::Age wrote to the *output filehandle*, not the bytes it
# ultimately returned -- decrypt_filehandle's output scalar keeps whatever was
# printed even if a later chunk makes the whole call die, which is exactly
# the partial-release check the upstream README requires ("**All** the
# plaintext that would have been released to the application... must match
# this hash, even if decryption eventually fails"). decrypt_file cannot do
# this (it has no access to a live output handle once its die unwinds), which
# is why this runner uses decrypt_filehandle throughout.
#
# KNOWN, NAMED FAILURES -- NOT FIXED HERE, NOT SILENCED HERE
# -----------------------------------------------------------------------
# As of this writing the following vectors fail against this distribution's
# actual behaviour. Per house rules this file does not weaken an assertion,
# add a TODO marker, or skip them to turn the suite green -- they are asserted
# like every other vector and are expected to show up red until fixed in
# lib/, which is out of scope for a test-writer change. Each is filed as its
# own karr ticket; see the handoff note on ticket #2 for the ticket numbers.
#
#   * stanza_invalid_character (expect: header failure) -- Header::parse_from_fh's
#     stanza start-line regex accepts any non-whitespace byte as an argument
#     character, including bytes outside the spec's printable-ASCII (VCHAR)
#     range. The vector's non-X25519 stanza carries a non-ASCII argument and
#     is silently ignored as an unknown-type stanza instead of invalidating
#     the header. Distinct from karr #5 (X25519-specific argument
#     validation): this is a general stanza-argument character-set gap that
#     applies to every stanza type, recognized or not.
#
#   * stream_last_chunk_empty, stream_no_final_full, stream_no_final_two_chunks_full,
#     stream_trailing_garbage_short, stream_trailing_garbage_long,
#     stream_two_final_chunks, stream_two_final_chunks_full,
#     stream_two_final_chunks_second (all expect: payload failure) --
#     Crypt::Age::Primitives::decrypt_payload_fh decides a chunk is final
#     purely from `$is_final = eof($ifh)` measured immediately after reading
#     up to one chunk's worth of bytes, with no lookahead and no check that
#     the filehandle is exhausted once a final chunk has been accepted. Two
#     distinct symptoms follow from that one root cause: (a) a chunk that
#     reads as exactly a full 64 KiB+tag and happens to end the file is
#     always treated as final, even when it was encrypted with the
#     *non-final* nonce and more (or no) data was meant to follow, so a
#     legitimately-releasable full chunk is rejected outright with zero
#     bytes released instead of the partial release the spec requires; and
#     (b) once some chunk IS accepted as final, the loop simply stops without
#     checking for leftover unread bytes, so a spurious empty final chunk or
#     outright trailing garbage after a genuine final chunk both pass
#     silently instead of being rejected. This never surfaces from any
#     encrypt/decrypt round trip through this library's own writer (which
#     always marks its true last chunk final and never appends anything
#     after), which is exactly why the existing unit and interop suites
#     never caught it.

my $VECTORS_DIR = "$FindBin::Bin/testkit/vectors";

opendir(my $dh, $VECTORS_DIR) or die "cannot open $VECTORS_DIR: $!";
my @names = sort grep { -f "$VECTORS_DIR/$_" } readdir $dh;
closedir $dh;

plan skip_all => "no vectors found under $VECTORS_DIR (see t/testkit/README.md)"
    unless @names;

# Reads one vector file. Returns (\%header_kv, $body_bytes). Header values are
# arrayrefs since a key (identity, passphrase) can repeat.
sub read_vector {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "open $path: $!";
    local $/;
    my $data = <$fh>;
    close $fh;

    my $idx = index($data, "\n\n");
    die "no header/body separator" if $idx < 0;

    my %kv;
    for my $line (split /\n/, substr($data, 0, $idx)) {
        next unless $line =~ /\A([^:]+): (.*)\z/;
        push @{ $kv{$1} }, $2;
    }
    return (\%kv, substr($data, $idx + 2));
}

sub maybe_inflate {
    my ($kv, $body) = @_;
    return $body unless grep { $_ eq 'zlib' } @{ $kv->{compressed} // [] };
    my $out;
    inflate(\$body => \$out) or die "zlib inflate failed: $InflateError";
    return $out;
}

# Stanza type tokens ("-> TYPE ...") from the age header portion of the body
# only (up to the "--- " MAC line), never the payload -- this stays cheap
# even for the multi-megabyte decompressed vectors the upstream README warns
# about, and never risks a false match against binary ciphertext.
sub stanza_types {
    my ($body) = @_;
    my $mac_idx = index($body, "\n---");
    my $head = $mac_idx >= 0 ? substr($body, 0, $mac_idx) : $body;
    return map { lc $_ } ($head =~ /^-> (\S+)/mg);
}

sub classify_outcome {
    my ($died, $message) = @_;
    return 'success' unless $died;
    return 'no_match_or_hmac' if $message =~ /^No matching identity found\b/;
    return 'payload'          if $message =~ /^Payload authentication failed at chunk \d+\b/;
    return 'nonce'             if $message =~ /^end of file reached before getting nonce\b/;
    return 'header';
}

my %ACCEPTS = (
    success           => { 'success' => 1 },
    header            => { 'header failure' => 1 },
    no_match_or_hmac  => { 'no match' => 1, 'HMAC failure' => 1 },
    payload           => { 'payload failure' => 1 },
    nonce             => { 'header failure' => 1, 'payload failure' => 1 },
);

my $run = 0;
my $pass = 0;
my %skip_count;
my %fail_reason;

for my $name (@names) {
    my ($kv, $raw_body) = read_vector("$VECTORS_DIR/$name");
    my $expect = $kv->{expect}[0];
    if (!defined $expect) {
        fail("$name: vector has no 'expect' header key");
        next;
    }

    if (grep { $_ eq 'yes' } @{ $kv->{armored} // [] }) {
        SKIP: { skip "ASCII armor not implemented ($name)", 1; }
        $skip_count{armor}++;
        next;
    }

    my $body = eval { maybe_inflate($kv, $raw_body) };
    if (!defined $body) {
        fail("$name: $@");
        next;
    }

    my @types = stanza_types($body);
    my $has_passphrase       = @{ $kv->{passphrase} // [] } ? 1 : 0;
    my $has_unsupported_type = grep { $_ eq 'scrypt' || $_ eq 'mlkem768x25519' } @types;

    if ($has_passphrase || $has_unsupported_type) {
        SKIP: { skip "scrypt/hybrid recipient not implemented ($name)", 1; }
        $skip_count{'unsupported-recipient'}++;
        next;
    }

    $run++;

    my @identities  = @{ $kv->{identity} // [] };
    my $payload_hex = $kv->{payload}[0];

    open my $ifh, '<:raw', \$body or die "open scalar fh: $!";
    my $output = '';
    open my $ofh, '>:raw', \$output or die "open scalar fh: $!";

    my $died = !eval {
        Crypt::Age->decrypt_filehandle(input => $ifh, output => $ofh, identities => \@identities);
        1;
    };
    my $message;
    if ($died) {
        ($message = $@) =~ s/\n\z//;
    }

    my $outcome  = classify_outcome($died, $message);
    my $accepted = $ACCEPTS{$outcome}{$expect} ? 1 : 0;

    my $hash_ok = 1;
    my $got_hex;
    if (defined $payload_hex) {
        $got_hex  = sha256_hex($output);
        $hash_ok = ($got_hex eq $payload_hex);
    }

    subtest $name => sub {
        ok($accepted, "expect '$expect' (outcome: $outcome)")
            or diag($died ? "died: $message" : 'decrypt_filehandle returned normally');
        if (defined $payload_hex) {
            is($got_hex, $payload_hex, 'released plaintext matches the payload hash');
        }
    };

    if ($accepted && $hash_ok) {
        $pass++;
    } else {
        $fail_reason{$name} = "expect='$expect' outcome=$outcome"
            . (defined $payload_hex && !$hash_ok ? ' payload-hash-mismatch' : '');
    }
}

my $skipped = 0;
$skipped += $_ for values %skip_count;

is($run + $skipped, scalar(@names),
    'every vector was either run or skipped for a recorded reason (none fell through uncounted)');

diag('');
diag("age test kit tally: " . scalar(@names) . " vectors total");
diag("  run:     $run (" . ($run - keys %fail_reason) . " pass, " . (scalar keys %fail_reason) . " fail)");
diag("  skipped: $skipped");
diag("    armor not implemented:              " . ($skip_count{armor} // 0));
diag("    scrypt/hybrid recipient unsupported: " . ($skip_count{'unsupported-recipient'} // 0));
if (%fail_reason) {
    diag('  known-failing vectors (see the header comment in this file for diagnosis):');
    diag("    $_: $fail_reason{$_}") for sort keys %fail_reason;
}

done_testing;
