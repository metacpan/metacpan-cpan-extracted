use strict;
use warnings;
use Test::More;
use Encode qw( encode_utf8 decode FB_CROAK LEAVE_SRC );
use Path::Tiny qw( path );

use App::karr::Encoding qw(
    to_octets to_octets_for_env
    from_octets from_octets_from_env
);

# Ticket #167: %ENV is a byte boundary karr did not own. A non-ASCII prompt
# assigned at Foundation/Runner.pm:63 emitted "Wide character in setenv" on
# foundation's stderr — the bytes the child received were correct UTF-8
# either way, so this is a warning, not a data bug. The fix routes both
# sides of the crossing through App::karr::Encoding: to_octets_for_env on
# the way out, from_octets_from_env on the way back in.

my $NON_ASCII = "Caf\x{e9} \x{2014} na\x{ef}ve prompt \x{1f914}";

subtest 'to_octets_for_env is the character-to-octet edge for %ENV' => sub {
    # The function is documented as the ENV-crossing edge, not a new codec.
    # Behavioural equivalence to to_octets is the property — name carries the
    # intent at the call site.
    is( to_octets_for_env($NON_ASCII), to_octets($NON_ASCII),
        'to_octets_for_env and to_octets agree on a non-ASCII input' );
    is( to_octets_for_encoded($NON_ASCII), encode_utf8($NON_ASCII),
        'to_octets_for_env returns the canonical UTF-8 octets' );
    is( to_octets_for_env(undef), undef, 'undef passes through' );
    is( to_octets_for_env(''), '', 'empty string passes through' );
};

subtest 'from_octets_from_env is the octet-to-character edge for %ENV' => sub {
    is( from_octets_from_env(encode_utf8($NON_ASCII)), $NON_ASCII,
        'from_octets_from_env decodes the same UTF-8 octets back to characters' );
    is( from_octets_from_env(undef), undef, 'undef passes through' );

    # A non-UTF-8 byte string: from_octets' "return unchanged" rule applies
    # here too — passing the bytes through silently turns a wrong-bytes-in,
    # same-wrong-bytes-out into a wrong-bytes-in, mojibake-out.
    my $raw = "\xff\xfe\xfd";
    is( from_octets_from_env($raw), $raw,
        'non-UTF-8 bytes are returned unchanged' );
};

# The symptom the ticket describes: assigning a character string to %ENV
# emits "Wide character in setenv" on STDERR. Wrap the assignment in a
# $SIG{__WARN__} trap and assert that the helper's call site stays silent.
subtest 'assigning through to_octets_for_env does not warn' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    local $ENV{KARR_TEST_PROMPT} = to_octets_for_env($NON_ASCII);

    my @wide = grep { /Wide character/ } @warnings;
    is( scalar @wide, 0, 'no "Wide character in setenv" warning' )
        or diag "warnings emitted: @warnings";

    # The bytes stored in %ENV are the encoded form, not the characters —
    # that is what the child process receives.
    is( $ENV{KARR_TEST_PROMPT}, encode_utf8($NON_ASCII),
        '%ENV holds the singly-encoded UTF-8 octets' );
    ok( defined eval { decode( 'UTF-8', $ENV{KARR_TEST_PROMPT}, FB_CROAK | LEAVE_SRC ) },
        'the stored bytes are valid UTF-8' );
    isnt( $ENV{KARR_TEST_PROMPT}, encode_utf8(encode_utf8($NON_ASCII)),
        'no double encoding' );
};

# Round-trip the whole crossing: characters → encode → store → read → decode →
# characters. This is the read side the ticket asked to settle. In karr's
# own code no Perl reader of KARR_REPO / KARR_ROLE / PROMPT exists today
# (the shell expands them), so a read site has to be fabricated to exercise
# the helper; the helper itself is what the rule gap asked for.
subtest 'round-trip through %ENV yields the original characters' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    # Write side, the way Foundation/Runner.pm now does it.
    local $ENV{KARR_TEST_ROUNDTRIP} = to_octets_for_env($NON_ASCII);

    # Read side, as a Perl process would do it.
    my $back = from_octets_from_env( $ENV{KARR_TEST_ROUNDTRIP} );

    is( scalar( grep { /Wide character/ } @warnings ), 0,
        'no warning on the round-trip' );
    is( $back, $NON_ASCII,
        'characters survive characters -> octets -> %ENV -> octets -> characters' );
    is( length($back), length($NON_ASCII),
        'character length matches (no byte inflation)' );
};

# The point of the helper is that the assignment at Foundation/Runner.pm
# stops being an ad hoc encoding. Pin the three writes — the ticket calls
# them out by name — to the helper, the way t/70 pins enable_std_utf8 /
# decode_argv in bin/karr and bin/karr-foundation: a future refactor that
# drops the wrap would also drop the property, and a grep catches it.
subtest 'Foundation/Runner wraps the three ENV writes through the helper' => sub {
    my $src = path('lib/App/karr/Foundation/Runner.pm')->slurp_utf8;
    like( $src, qr/^use\s+App::karr::Encoding\s+qw\(\s*to_octets_for_env\s*\)/m,
        'Runner imports to_octets_for_env' );
    like( $src, qr/^\s*local \$ENV\{KARR_REPO\} = to_octets_for_env\(/m,
        'KARR_REPO is written through to_octets_for_env' );
    like( $src, qr/^\s*local \$ENV\{KARR_ROLE\} = to_octets_for_env\(/m,
        'KARR_ROLE is written through to_octets_for_env' );
    like( $src, qr/^\s*local \$ENV\{PROMPT\}    = to_octets_for_env\(/m,
        'PROMPT is written through to_octets_for_env' );
};

# The Encoding module documents the edge. Pin the doc addition so a future
# edit that drops the entry also drops the rule, the way t/70 does for
# enable_std_utf8.
subtest 'Encoding.pm documents %ENV as an edge it owns' => sub {
    my $src = path('lib/App/karr/Encoding.pm')->slurp_utf8;
    like( $src, qr/%ENV.*to_octets_for_env/s,
        'the %ENV edge lists to_octets_for_env in DESCRIPTION' );
    like( $src, qr/=(?:func|head2)\s+to_octets_for_env\b/,
        'to_octets_for_env has a documented block' );
    like( $src, qr/=(?:func|head2)\s+from_octets_from_env\b/,
        'from_octets_from_env has a documented block' );
    like( $src, qr/^  to_octets_for_env$/m, 'to_octets_for_env is in @EXPORT_OK' );
    like( $src, qr/^  from_octets_from_env$/m, 'from_octets_from_env is in @EXPORT_OK' );
};

# Stable identifier for the assert above: keep the accessor's spelling
# consistent regardless of where this test moves.
sub to_octets_for_encoded {
    return encode_utf8($_[0]);
}

done_testing;
