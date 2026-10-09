#!perl
use strict;
use warnings;
use English qw( -no_match_vars );

# WHAT IS IN THE DATABASE, AND WHAT HAPPENS WHEN IT IS NOT WHAT WE EXPECT.
#
# Two things no other test file can establish, both about the stored envelope
# rather than about the code that happens to be running.
#
# 1. THE FORMAT IS STABLE. Every other test seals a payload and opens it again
#    in the same process, so it re-encodes with the same code it decodes with
#    and a change to the layout cancels itself out. The envelopes below were
#    written by an earlier release and are pasted in as bytes: nothing here can
#    regenerate them, so if the header grows a field, the iv or tag length
#    moves, the key id stops being honoured or the serialiser changes shape,
#    this file fails and every live session in every deployment would have
#    failed with it. That is the one defect class that is invisible to a round
#    trip and catastrophic in production.
#
# 2. A MALFORMED PAYLOAD IS NOT AN ERROR. `_decrypt` is reached with whatever
#    is in the column, and the column is reachable by anyone with UPDATE. The
#    contract is that it returns nothing -- Dancer2 then starts a fresh session
#    -- and that it never throws, because an exception on the session path is a
#    500 on every request for the user holding that cookie. Asserted over the
#    truncations, bit flips and junk that a corrupt or hostile row looks like.
#
# Deliberately DATABASE-FREE: both claims are about bytes, so they are checked
# everywhere rather than only where PostgreSQL is reachable.

use Test2::V1 qw( -utf8 -x ), -include => [ [ 'Test2::Tools::Subtest', 'subtest_streamed' ] ];

use Carp        qw( croak );
use Crypt::PRNG qw( random_bytes );

use FindBin qw( $Bin );    ## no critic (Community::DiscouragedModules) -- how a test finds t/lib; the warning is for applications
use lib "$Bin/lib";
use Dancer2::Session::Pg ();

# The session id is part of the AAD, so it is as much a part of these fixtures
# as the key is. Changing either invalidates every blob below.
my $SESSION_ID = 'golden-session-1';
my $OTHER_ID   = 'golden-session-2';

my $EXPECTED = { user => 'alice', admin => 0, scopes => [ 'read', 'write' ], count => 3 };

# WRITTEN BY AN EARLIER RELEASE. Do not regenerate these to make a failing test
# pass -- that is the test working. A deliberate format change means a new
# FORMAT_VERSION and a reader for the old one, and these stay as the fixture for
# version 1. One cipher each, at a DIFFERENT slot id, so the key id byte is
# pinned as well as the cipher id byte.
my @GOLDEN = (
    {
        alg       => 'AES-128-GCM',
        slot      => 0,
        cipher_id => 1,
        key       => '0123456789abcdef0123456789abcdef',
        blob      => '0101000fd0c7ff5caeb7005f818e2d355452f3b930ef667d63185927373d50f7'
          . 'b34c02e44b1f1da4bf002b22cf05b009557455023ee4322ac712d170a58cdc0b'
          . '652023ae0f5bfa8614d57f78c774de0330b9c9048627f17c0e29a5faf6',
    },
    {
        alg       => 'AES-192-GCM',
        slot      => 1,
        cipher_id => 2,
        key       => '0123456789abcdef0123456789abcdef0123456789abcdef',
        blob      => '010201770a4ad6beffb2c741eeca4fde1ec3fa1917f0083836b45d57b1bc004e'
          . '6d49f4bf7f8183055bc4ac35d2046f8f4000e62e4c31d161a86035172633512f'
          . '22b1e096de8ee7269b7f15b979de216e9c64911c9330d7952187dce1fe',
    },
    {
        alg       => 'AES-256-GCM',
        slot      => 7,
        cipher_id => 3,
        key       => '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        blob      => '010307200064ccac425613b1e33ecda336be1ca48b797d259e2648b743b37b87'
          . 'fa87c4d0b3bcd972b4a1d62d93e4c07156224d7fedcd99e861e67a6fc398169f'
          . '49f6454c8d15734a8d66ce5fbee339cfe126a0d172b6114cb6038ad4ce',
    },
    {
        alg       => 'ChaCha20-Poly1305',
        slot      => 42,
        cipher_id => 4,
        key       => 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210',
        blob      => '01042a5fbcfea4e7c5c75d5360a8835912a95b7f1c8232f8a0550b8578980eaba'
          . 'dba4de871197453312e249ebff2c441c63cc2e583fb3c818cfaf2b9717feeb69'
          . '86d105f79352348ba207547d18d43f8b2e7658ecd9b1cb7c7af363b14',
    },
);

sub engine_for {
    my ($case) = @_;

    return Dancer2::Session::Pg->new(

        # A coderef rather than a handle, so construction cannot be tempted to
        # look at it. Nothing in this file reaches the database.
        dbh             => sub { croak 'this test never touches a database' },
        dbtable         => 'sessions',
        encryption_keys => { $case->{'slot'} => { key => $case->{'key'}, alg => $case->{'alg'}, active => 1 } },
    );
}

T2->subtest_streamed(
    'a payload sealed by an earlier release still opens' => sub {
        for my $case (@GOLDEN) {
            my $alg    = $case->{'alg'};
            my $engine = engine_for($case);
            my $blob   = pack 'H*', $case->{'blob'};

            # The header first and by hand, because a layout change should say
            # so rather than arrive as a decryption that mysteriously failed.
            my ( $version, $cipher_id, $key_id ) = unpack 'C3', $blob;
            T2->is( $version,   1,                    "$alg: the stored format version is still 1" );
            T2->is( $cipher_id, $case->{'cipher_id'}, "$alg: the cipher id byte is unchanged" );
            T2->is( $key_id,    $case->{'slot'},      "$alg: the key id byte is still the slot it was written with" );

            T2->is( $engine->_decrypt( $SESSION_ID, $blob ), $EXPECTED, "$alg: and the payload comes back exactly as it went in" );

            # The AAD is part of the format too: these bytes are bound to one
            # session id and must stay unusable under another.
            T2->is( scalar $engine->_decrypt( $OTHER_ID, $blob ), undef, "$alg: under a different session id it opens nothing" );
        }
    }
);

T2->subtest_streamed(
    'a malformed payload yields nothing and throws nothing' => sub {
        my $case   = $GOLDEN[2];          # AES-256-GCM, the default
        my $engine = engine_for($case);
        my $real   = pack 'H*', $case->{'blob'};
        my $header = substr $real, 0, 3;

        my @inputs = ( undef, q{} );

        # Every truncation of a real payload except the whole of it, which is
        # the one input that is supposed to work.
        push @inputs, substr $real, 0, $_ for 1 .. length($real) - 1;

        # Junk of every plausible length, including lengths that reach each
        # boundary the parser cares about.
        push @inputs, random_bytes($_) for 0 .. 64;

        # A VALID header with a junk body, which is what gets past the version,
        # cipher and key-id checks and all the way to the cipher itself.
        push @inputs, $header . random_bytes($_) for 0 .. 128;

        # One bit flipped at every byte: version, cipher id, key id, iv, tag and
        # ciphertext in turn.
        my $length = length $real;
        for my $at ( 0 .. $length - 1 ) {
            my $bent    = $real;
            my $flipped = ( ord substr $bent, $at, 1 ) ^ 1;
            substr $bent, $at, 1, chr $flipped;
            push @inputs, $bent;
        }

        my @warnings;
        local $SIG{'__WARN__'} = sub { push @warnings, $_[0] };

        my ( $threw, $opened ) = ( 0, 0 );
        for my $input (@inputs) {
            my $got = eval { scalar $engine->_decrypt( $SESSION_ID, $input ) };
            $threw++  if $EVAL_ERROR;
            $opened++ if defined $got;
        }

        T2->is( $threw, 0, sprintf '%d malformed payloads and not one of them threw', scalar @inputs );
        T2->is( $opened, 0, 'and not one of them produced a session' );

        # An uninitialized-value warning in the parse path is a branch nobody
        # thought about, reached by input an attacker chooses.
        T2->is( [@warnings], [], 'and nothing warned on the way through' );

        # The engine is still usable afterwards: none of that left state behind.
        T2->is( $engine->_decrypt( $SESSION_ID, $real ), $EXPECTED, 'and a good payload still opens after all of it' );
    }
);

T2->done_testing;
