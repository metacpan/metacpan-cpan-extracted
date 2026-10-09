#!perl
use strict;
use warnings;
use English qw( -no_match_vars );

# Several packages, on purpose: the toy ciphers exist to prove cipher_self_check
# rejects them, and splitting them into files would scatter the thing being
# demonstrated. $data likewise follows the SessionFactory contract.
## no critic (Modules::ProhibitMultiplePackages, Bangs::ProhibitVagueNames)

# Everything about Dancer2::Session::Pg that does NOT need a database.
#
# This file exists because t/session_pg.t skips entirely where there is no
# PostgreSQL cluster the test user may create databases on -- which is most CPAN
# smokers. A distribution whose whole suite can skip reports "pass" from a
# machine that exercised nothing. These tests run everywhere.
#
# The engine is built with a `dbh` that is a coderef nobody calls, so nothing
# here opens a connection.

use Test2::V1 qw( -utf8 -x ), -include => [ [ 'Test2::Tools::Subtest', 'subtest_streamed' ] ];

use Dancer2::Session::Pg                           ();
use Dancer2::Session::Pg::Cipher::AESGCM           ();
use Dancer2::Session::Pg::Cipher::ChaCha20Poly1305 ();

my $KEY32 = 'a' x 64;    # hex, so 32 bytes

# A payload is sealed AGAINST its session id, so every _encrypt and _decrypt
# needs one. Where the id is incidental to what is being tested, this is it.
use constant SID => 'sess-under-test';

# One active slot holding one key and one cipher, which is what most of these
# tests want. `key` and `alg` here are scaffolding, not API: the engine itself
# takes only encryption_keys, and spelling the whole structure out at every call
# site would bury what each test is actually about.
sub engine {
    my (%args) = @_;
    my $key    = defined $args{'key'} ? delete $args{'key'} : $KEY32;
    my $alg    = delete $args{'alg'} || 'AES-256-GCM';
    my $slots  = delete $args{'encryption_keys'}
      || { 0 => { key => $key, alg => $alg, active => 1 } };
    delete $args{'key'};

    return Dancer2::Session::Pg->new(
        dbh             => sub { die "the database was reached and should not have been\n" },
        dbtable         => 'sessions',
        encryption_keys => $slots,
        %args,
    );
}

# A slot, for the tests that build rings by hand.
sub slot {
    my ( $key, $alg, $active ) = @_;
    return {
        key => $key,
        alg => ( defined $alg ? $alg : 'AES-256-GCM' ),
        ( $active ? ( active => 1 ) : () ),
    };
}

my %EXPECTED = (
    'AES-128-GCM'       => { id => 1, key => 16 },
    'AES-192-GCM'       => { id => 2, key => 24 },
    'AES-256-GCM'       => { id => 3, key => 32 },
    'ChaCha20-Poly1305' => { id => 4, key => 32 },
);

# Declared at file scope rather than inside the subtest that uses them: a
# `package` statement inside a closure reads like a nested namespace and is not.
{
    # A toy cipher that is honest about what it is: no encryption at all, but it
    # authenticates, so it must PASS. Each subclass breaks one clause of the
    # contract, and the self check has to catch every one.
    package Test::Cipher::Base;
    use Moo;

    # The tag covers the payload AND the additional data, which is what an AEAD
    # mode does and what the engine's binding of a payload to its session id
    # depends on.
    sub _tag {
        my ( $payload, $aad ) = @_;
        return sprintf '%016d', unpack '%32C*', $payload . ( defined $aad ? $aad : q{} );
    }

    # A toy TRANSFORM, so these fixtures are not themselves what
    # cipher_self_check now refuses: a cipher that returns the plaintext as its
    # ciphertext would store sessions in the clear, however sound its tag. XOR
    # is not encryption and is not pretending to be -- it is the smallest thing
    # that makes the ciphertext differ from the plaintext and reverses cleanly.
    sub _hide {
        my ($bytes) = @_;
        return pack 'C*', map { $_ ^ 0x5A } unpack 'C*', $bytes;
    }
    sub cipher_id   { return 200 }                                                                           # the third-party range
    sub cipher_name { return 'Test' }
    sub key_bytes   { return 32 }
    sub iv_bytes    { return 12 }
    sub tag_bytes   { return 16 }
    sub seal        { my ( $s, $k, $i, $p, $aad ) = @_; my $c = _hide($p); return ( $c, _tag( $c, $aad ) ) }

    sub unseal {                                                                                             ## no critic (Subroutines::ProhibitManyArgs) -- six is the AEAD contract in Dancer2::Session::Pg::Cipher
        my ( $s, $k, $i, $c, $t, $aad ) = @_;
        return () if !defined $t || $t ne _tag( $c, $aad );
        return _hide($c);
    }
    with 'Dancer2::Session::Pg::Cipher';

    # Ignores the tag. Round trips perfectly, and returns MODIFIED PLAINTEXT for
    # modified input -- the "admin":0 -> "admin":1 attack, and the reason the
    # self check refuses ANY defined result rather than only the original one.
    package Test::Cipher::NoTagCheck;
    use Moo;
    extends 'Test::Cipher::Base';

    sub unseal {    ## no critic (Subroutines::ProhibitManyArgs) -- six is the AEAD contract in Dancer2::Session::Pg::Cipher
        my ( $s, $k, $i, $c, $t, $aad ) = @_;
        return Test::Cipher::Base::_hide($c);    ## no critic (Subroutines::ProtectPrivateSubs) -- the toy cipher reuses the base transform on purpose
    }

    # Authenticates the payload properly and DROPS THE ADDITIONAL DATA. The
    # dangerous one: every round trip works, nothing looks wrong, and the
    # engine's binding of a payload to its session id silently does not exist --
    # so an administrator's sealed row would open under an attacker's id again.
    package Test::Cipher::IgnoresAad;
    use Moo;
    extends 'Test::Cipher::Base';

    sub seal {
        my ( $s, $k, $i, $p, $aad ) = @_;
        my $c = Test::Cipher::Base::_hide($p);          ## no critic (Subroutines::ProtectPrivateSubs) -- the toy cipher reuses the base transform on purpose
        return ( $c, Test::Cipher::Base::_tag($c) );    ## no critic (Subroutines::ProtectPrivateSubs) -- and the base tag, deliberately without the aad
    }

    sub unseal {                                        ## no critic (Subroutines::ProhibitManyArgs) -- six is the AEAD contract in Dancer2::Session::Pg::Cipher
        my ( $s, $k, $i, $c, $t, $aad ) = @_;
        return ()
          if !defined $t || $t ne Test::Cipher::Base::_tag($c);    ## no critic (Subroutines::ProtectPrivateSubs) -- the format and the crypto live here, so they are tested directly
        return Test::Cipher::Base::_hide($c);                      ## no critic (Subroutines::ProtectPrivateSubs) -- the toy cipher reuses the base transform on purpose
    }

    package Test::Cipher::ShortTag;                                # lies about tag_bytes
    use Moo;
    extends 'Test::Cipher::Base';
    sub tag_bytes { return 32 }

    package Test::Cipher::BadRoundTrip;                            # cannot read its own writes
    use Moo;
    extends 'Test::Cipher::Base';
    sub unseal { return 'something else' }

    package Test::Cipher::ZeroId;                                  # an id that cannot be stored
    use Moo;
    extends 'Test::Cipher::Base';
    sub cipher_id { return 0 }

    # AUTHENTICATES PERFECTLY AND DOES NOT ENCRYPT. Real tag over the payload,
    # refuses every forgery, honours the additional data, round trips -- and
    # hands back the plaintext as its ciphertext, so sessions would sit in the
    # database in the clear. Until cipher_self_check compared the two, this
    # passed every check it made.
    package Test::Cipher::NeverEncrypts;
    use Moo;
    extends 'Test::Cipher::Base';
    sub cipher_id   { return 201 }
    sub cipher_name { return 'NeverEncrypts' }
    sub seal        { my ( $s, $k, $i, $p, $aad ) = @_; return ( $p, Test::Cipher::Base::_tag( $p, $aad ) ) }    ## no critic (Subroutines::ProtectPrivateSubs) -- the toy cipher reuses the base tag

    sub unseal {                                                                                                 ## no critic (Subroutines::ProhibitManyArgs) -- six is the AEAD contract in Dancer2::Session::Pg::Cipher
        my ( $s, $k, $i, $c, $t, $aad ) = @_;
        return () if !defined $t || $t ne Test::Cipher::Base::_tag( $c, $aad );                                  ## no critic (Subroutines::ProtectPrivateSubs) -- as above
        return $c;
    }

    # Correct in every way except that it squats on an id the core has reserved
    # but not yet used, which would collide with a future built-in.
    package Test::Cipher::SquatsOnUnusedCoreId;
    use Moo;
    extends 'Test::Cipher::Base';
    sub cipher_id   { return 5 }
    sub cipher_name { return 'SquatsOnUnusedCoreId' }

    # Claims AES-256-GCM's id while being a different format entirely. The
    # accident the reserved-id check exists to catch.
    package Test::Cipher::StealsAesId;
    use Moo;
    extends 'Test::Cipher::Base';
    sub cipher_id   { return 3 }
    sub cipher_name { return 'StealsAesId' }

    # Claims AES-256-GCM's id and IS AES-256-GCM, by delegation -- the
    # legitimate case: a replacement implementation that can read every row the
    # original wrote. This one must be ACCEPTED.
    package Test::Cipher::RealAesDropIn;
    use Moo;
    use Dancer2::Session::Pg::Cipher::AESGCM ();
    has _inner => ( is => 'lazy', builder => sub { Dancer2::Session::Pg::Cipher::AESGCM->new( key_bytes => 32 ) } );
    sub cipher_id   { return 3 }
    sub cipher_name { return 'RealAesDropIn' }
    sub key_bytes   { return 32 }
    sub iv_bytes    { return 12 }
    sub tag_bytes   { return 16 }
    sub seal        { my ( $self, @a ) = @_; return $self->_inner->seal(@a) }
    sub unseal      { my ( $self, @a ) = @_; return $self->_inner->unseal(@a) }
    with 'Dancer2::Session::Pg::Cipher';

    # Two correct ciphers in the third-party range that happen to pick the
    # same id. Nothing reserved is involved: this is the collision the ENGINE
    # catches when it builds the ring, not the one the role catches per cipher.
    package Test::Cipher::ThirdPartyTwoHundred;
    use Moo;
    extends 'Test::Cipher::Base';
    sub cipher_id   { return 200 }
    sub cipher_name { return 'ThirdPartyTwoHundred' }

    package Test::Cipher::AlsoTwoHundred;
    use Moo;
    extends 'Test::Cipher::Base';
    sub cipher_id   { return 200 }
    sub cipher_name { return 'AlsoTwoHundred' }
}

T2->subtest_streamed(
    'the built-in ciphers describe themselves consistently' => sub {
        T2->is( [ Dancer2::Session::Pg->algorithms ], [ sort keys %EXPECTED ], 'algorithms() lists exactly what is documented' );

        for my $name ( sort keys %EXPECTED ) {
            my $cipher = Dancer2::Session::Pg::_resolve_cipher($name);    ## no critic (Subroutines::ProtectPrivateSubs) -- the format and the crypto live here, so they are tested directly

            T2->is( $cipher->cipher_name, $name, "$name resolves to a cipher that agrees on its name" );
            T2->is(
                $cipher->cipher_id,
                $EXPECTED{$name}{'id'},
                "$name has stored id $EXPECTED{$name}{'id'} -- CHANGING THIS BREAKS EXISTING ROWS"
            );
            T2->is( $cipher->key_bytes, $EXPECTED{$name}{'key'}, "$name takes the documented key length" );
            T2->ok( $cipher->cipher_self_check, "$name passes its own self check" );
        }
    }
);

T2->subtest_streamed(
    'cipher_self_check is not decorative' => sub {
        T2->ok( Test::Cipher::Base->new->cipher_self_check, 'a toy cipher that authenticates passes the self check' );

        my %must_fail = (
            'Test::Cipher::NoTagCheck'   => qr/ciphertext[ ]had[ ]been[ ]altered/msx,
            'Test::Cipher::ShortTag'     => qr/tag_bytes/msx,
            'Test::Cipher::BadRoundTrip' => qr/did[ ]not[ ]return/msx,
            'Test::Cipher::ZeroId'       => qr/positive[ ]integer/msx,
            'Test::Cipher::IgnoresAad'   => qr/IGNORED[ ]the[ ]additional/msx,
        );

        for my $class ( sort keys %must_fail ) {
            my $ok = eval { $class->new->cipher_self_check; 1 };
            T2->ok( !$ok, "$class is refused by cipher_self_check" );
            T2->like( $EVAL_ERROR, $must_fail{$class}, 'and the message says which way it failed' );
        }
    }
);

T2->subtest_streamed(
    'the stored envelope' => sub {

        # iv || tag || ciphertext was the old layout and carried no identification,
        # so a row could only be read by the cipher that happened to be configured.
        # The three header bytes are what make a cipher replaceable.
        my $engine = engine();
        my $blob   = $engine->_encrypt( SID, { hello => q{world} } );
        my ( $version, $cipher_id, $key_id ) = unpack 'C3', $blob;

        T2->is( $version,   1, 'the payload declares format version 1' );
        T2->is( $cipher_id, 3, 'and the cipher that wrote it (AES-256-GCM is 3)' );
        T2->is( $key_id,    0, 'and a key id, reserved and zero' );

        T2->is( $engine->_decrypt( SID, $blob ), { hello => q{world} }, 'which round trips' );
        T2->ok( index( $blob, 'world' ) < 0, 'and the plaintext is not in the bytes' );

        # 3 header + 12 iv + 16 tag = 31 bytes before any ciphertext at all.
        T2->ok( length($blob) > 31, 'the header, iv and tag are all present' );
    }
);

# The vulnerability this binding exists to close, as a test rather than a
# paragraph. Before the session id went in as additional authenticated data, the
# tag covered the payload and nothing else, so a sealed payload was PORTABLE
# BETWEEN ROWS: somebody with UPDATE on the sessions table and no encryption key
# at all could copy an administrator's session_data into their own row and their
# own cookie would open it.
T2->subtest_streamed(
    'a payload is sealed against the session id it belongs to' => sub {
        my $engine = engine();
        my $admin  = { admin => 1, name => 'root' };

        my $sealed_for_admin = $engine->_encrypt( 'admin-session', $admin );

        T2->is( $engine->_decrypt( 'admin-session', $sealed_for_admin ), $admin, 'it opens under the id it was sealed for' );
        T2->is( scalar $engine->_decrypt( 'attacker-session', $sealed_for_admin ),
            undef, 'and NOT under any other id -- the payload cannot be moved between rows' );

        # The same key, the same cipher, the same bytes: only the id differs. So the
        # refusal is the binding and not some incidental difference.
        T2->is( scalar engine()->_decrypt( 'attacker-session', $sealed_for_admin ),
            undef, 'not even for a second engine with identical configuration' );

        # An empty or undefined id must not collapse to "no binding at all".
        my $sealed_for_empty = $engine->_encrypt( q{}, $admin );
        T2->is( scalar $engine->_decrypt( 'admin-session', $sealed_for_empty ),
            undef, 'an empty id is a binding too, not a wildcard' );
    }
);

T2->subtest_streamed(
    'every built-in cipher round trips through a slot' => sub {

        # Replacing a cipher is a SLOT operation, not an `alg` operation: a row is
        # read through the slot it names, and that slot says which cipher sealed it.
        # The rotation itself is covered by the keyring subtest below; this is the
        # per-cipher coverage at the engine level.
        my $data = { token => 'SECRET', n => 7 };

        for my $name ( sort keys %EXPECTED ) {
            my $key    = 'e' x ( 2 * $EXPECTED{$name}{'key'} );
            my $engine = engine( encryption_keys => { 0 => slot( $key, $name, 1 ) } );
            my $blob   = $engine->_encrypt( SID, $data );

            T2->is( ( unpack 'C3', $blob )[1],       $EXPECTED{$name}{'id'}, "$name stamps its own cipher id on the row" );
            T2->is( $engine->_decrypt( SID, $blob ), $data,                  "and $name round trips" );
            T2->ok( index( $blob, 'SECRET' ) < 0, "and $name leaves nothing readable" );
        }
    }
);

T2->subtest_streamed(
    q{a cipher of one's own, through every accepted form} => sub {
        my $data = { v => 'plugged in' };
        my %form = (
            'a class name'      => 'Test::Cipher::Base',
            'a class with args' => ['Test::Cipher::Base'],
            'an object'         => Test::Cipher::Base->new,
        );

        for my $form ( sort keys %form ) {
            my $engine = engine( alg => $form{$form} );
            my $blob   = $engine->_encrypt( SID, $data );
            T2->is( ( unpack 'C3', $blob )[1],       200,   "alg accepts $form, and its id is stored" );
            T2->is( $engine->_decrypt( SID, $blob ), $data, 'and the payload round trips through it' );
        }

        # Retired, readable, no longer written. There is no `read_algs` attribute
        # for this any more: a cipher you can still read but no longer write IS the
        # other slot, which is the whole point of pairing a key with its cipher.
        my $old = engine( alg => 'Test::Cipher::Base' )->_encrypt( SID, $data );

        my $retired = engine(
            encryption_keys => {
                0 => slot( $KEY32, 'Test::Cipher::Base' ),    # kept, read only
                1 => slot( $KEY32, 'AES-256-GCM', 1 ),        # active
            }
        );
        T2->is( $retired->_decrypt( SID, $old ), $data, 'a retired slot reads a third-party cipher that is no longer written' );
        T2->is( ( unpack 'C3', $retired->_encrypt( SID, $data ) )[1], 3, 'while new rows are written with the active slot cipher' );

        T2->is( scalar engine( alg => q{AES-256-GCM} )->_decrypt( SID, $old ),
            undef, 'and once the slot is dropped that row is simply unreadable' );
    }
);

T2->subtest_streamed(
    'an unreadable row fails closed, and says so once' => sub {
        my $engine   = engine();
        my @reported = ();
        my $watched  = Dancer2::Session::Pg->new(
            dbh             => sub { die "no\n" },
            dbtable         => 'sessions',
            encryption_keys => { 0 => slot( $KEY32, undef, 1 ) },
            log_cb          => sub { push @reported, [@_]; return 1 },
        );

        my $blob = $engine->_encrypt( SID, { admin => 0 } );

        T2->is( scalar $engine->_decrypt( SID, undef ), undef, 'undef is not a session' );
        T2->is( scalar $engine->_decrypt( SID, q{} ),   undef, 'nor is an empty payload' );
        T2->is( scalar $engine->_decrypt( SID, 'ab' ),  undef, 'nor is one shorter than the header' );

        my $future = $blob;
        substr $future, 0, 1, chr 99;
        T2->is( scalar $watched->_decrypt( SID, $future ), undef, 'an unknown format version is refused' );

        my $unknown = $blob;
        substr $unknown, 1, 1, chr 250;
        T2->is( scalar $watched->_decrypt( SID, $unknown ), undef, 'an unreadable cipher id is refused' );

        my $other_key = $blob;
        substr $other_key, 2, 1, chr 9;
        T2->is( scalar $watched->_decrypt( SID, $other_key ), undef, 'an unconfigured key id is refused' );

        my $altered = $blob;
        my $flipped = ( ord substr $altered, -1 ) ^ 0xFF;
        substr $altered, -1, 1, chr $flipped;
        T2->is( scalar $watched->_decrypt( SID, $altered ), undef, 'an altered payload does not decrypt' );

        T2->is( scalar engine( key => q{b} x 64 )->_decrypt( SID, $blob ), undef, 'the wrong key yields nothing, not garbage' );

        # Four distinct reasons, each reported once -- not once per request, which is
        # how a log stops being readable when somebody is poking at cookies.
        T2->is( scalar @reported, 4,         'each distinct reason is reported exactly once' );
        T2->is( $reported[0][0],  'warning', 'at the level Dancer2 expects' );
        T2->like( $reported[0][1], qr/could[ ]not[ ]be[ ]read/msx, 'through log_cb' );

        $watched->_decrypt( SID, $altered ) for 1 .. 3;
        T2->is( scalar @reported, 4, 'and repeating the same failure adds nothing to the log' );
    }
);

T2->subtest_streamed(
    'the principal, with no database in sight' => sub {
        my $plain = engine();
        T2->is( $plain->principal_column,     'principal_id', 'the column has a documented default' );
        T2->is( scalar $plain->principal_key, undef,          'and principal_key is off by default' );

        my $named = engine( principal_key => 'account_id', principal_column => 'account_id' );
        T2->is( $named->_principal_of( { account_id => 4711 } ), 4711,  'a named key is copied' );
        T2->is( scalar $named->_principal_of( {} ),              undef, 'a missing one gives undef' );
        T2->is( scalar $named->_principal_of( { account_id => { id => 1 } } ),
            undef, 'and a reference is skipped -- only a scalar is worth indexing' );

        my $computed = engine( principal_key => sub { return $_[0]->{'user'}{'id'} } );
        T2->is( $computed->_principal_of( { user => { id => 'PRL-9' } } ),
            'PRL-9', 'a coderef can reach an identity spread over several keys' );
        T2->is( scalar $computed->_principal_of( { user => {} } ), undef, 'and gives undef when it finds nothing' );
    }
);

# principal_key pointing at a structure leaves the column NULL, which makes
# destroy_for_principal unable to find the session -- an account suspension that
# silently does not take effect. It was silent; now it is reported, once, and
# WITHOUT the value, which is session content and the reason this module
# encrypts in the first place.
T2->subtest_streamed(
    'a principal that is not a value is reported, not swallowed' => sub {
        my @logged;
        my $engine = Dancer2::Session::Pg->new(
            dbh             => sub { die "no\n" },
            dbtable         => 'sessions',
            encryption_keys => { 0 => slot( $KEY32, undef, 1 ) },
            principal_key   => 'identity',
            log_cb          => sub { push @logged, [@_]; return 1 },
        );

        T2->is( scalar $engine->_principal_of( { identity => { id => 7, token => 'SECRET' } } ),
            undef, 'a reference still yields no principal' );

        T2->is( scalar @logged, 1,         'and it is reported' );
        T2->is( $logged[0][0],  'warning', 'at warning level' );
        T2->like( $logged[0][1], qr/destroy_for_principal/msx, 'naming the consequence rather than just the symptom' );
        T2->like( $logged[0][1], qr/HASH[ ]reference/msx,      'and what it got' );
        T2->ok( index( $logged[0][1], 'SECRET' ) < 0,
            'but NOT the value -- that is session content, and some of it is credentials' );

        $engine->_principal_of( { identity => { id => $_ } } ) for 1 .. 5;
        T2->is( scalar @logged, 1, 'reported once per engine, not once per request' );
    }
);

# The warning that a supplied handle is in manual-commit mode, which the module
# issues because a session write joining somebody else's transaction is real in
# the process and absent from the database until they commit. It needs no
# THE CODEREF FORM, which is the one the documentation recommends for
# Dancer2::Plugin::Database and DBIx::Class -- and which was silent, because
# BUILD cannot call a coderef (doing so would open a connection at construction,
# the very thing the coderef form avoids) and nothing checked it later. Same
# handle, same risk, no warning.
T2->subtest_streamed(
    'manual-commit mode warns for a CODEREF handle too' => sub {
        my $handle = bless { AutoCommit => 0, RaiseError => 1 }, 'Test::Handle';

        my @warnings;
        my @logged;
        local $SIG{'__WARN__'} = sub { push @warnings, $_[0] };

        my $engine = Dancer2::Session::Pg->new(
            dbh             => sub { $handle },
            dbtable         => 'sessions',
            log_cb          => sub { push @logged, "$_[0]: $_[1]" },
            encryption_keys => { 0 => slot( $KEY32, undef, 1 ) },
        );

        T2->is( scalar @warnings, 0, 'nothing at construction -- the coderef is deliberately not called there' );

        $engine->_dbh;
        T2->is( scalar @warnings, 1, 'but the first access warns' );
        T2->like( $warnings[0], qr/AutoCommit[ ]off/msx, 'saying what the state is' );
        T2->is( scalar( grep { m/AutoCommit[ ]off/msx } @logged ), 1, 'and it reaches log_cb as well' );

        # Once per worker, not once per request: this is on the path of every
        # single session read and write.
        $engine->_dbh for 1 .. 5;
        T2->is( scalar @warnings, 1, 'and says it ONCE, however many requests follow' );
    }
);

# PostgreSQL: the engine reads one attribute off the handle, so a blessed hashref
# is a sufficient stand-in and this can be checked anywhere.
T2->subtest_streamed(
    'a supplied handle in manual-commit mode warns, once' => sub {
        my @warnings;
        local $SIG{'__WARN__'} = sub { push @warnings, $_[0] };

        Dancer2::Session::Pg->new(
            dbh             => bless( { AutoCommit => 0 }, 'Test::Handle' ),
            dbtable         => 'sessions',
            encryption_keys => { 0 => slot( $KEY32, undef, 1 ) },
        );
        T2->is( scalar @warnings, 1, 'AutoCommit off on a supplied handle warns' );
        T2->like( $warnings[0], qr/AutoCommit[ ]off/msx,                               'saying what the state is' );
        T2->like( $warnings[0], qr/not[ ]durable[ ]until[ ]the[ ]caller[ ]commits/msx, 'and what it means for a session write' );

        # BOTH routes, because they reach different places. carp reaches an engine
        # built by hand, where log_cb is the role's no-op default; log_cb reaches the
        # application log of an engine Dancer2 built from config, where STDERR may go
        # nowhere anybody reads.
        my @logged;
        Dancer2::Session::Pg->new(
            dbh             => bless( { AutoCommit => 0 }, 'Test::Handle' ),
            dbtable         => 'sessions',
            encryption_keys => { 0 => slot( $KEY32, undef, 1 ) },
            log_cb          => sub { push @logged, [@_]; return 1 },
        );
        T2->is( scalar @logged, 1,         'and it also goes to log_cb, for a Dancer2-built engine' );
        T2->is( $logged[0][0],  'warning', 'at warning level' );

        @warnings = ();
        Dancer2::Session::Pg->new(
            dbh             => bless( { AutoCommit => 1 }, 'Test::Handle' ),
            dbtable         => 'sessions',
            encryption_keys => { 0 => slot( $KEY32, undef, 1 ) },
        );
        T2->is( scalar @warnings, 0, 'and a handle with AutoCommit on says nothing' );

        # A coderef is not inspected at all: there is no handle yet to look at, and
        # calling it during construction would open a connection the engine may
        # never need.
        @warnings = ();
        Dancer2::Session::Pg->new(
            dbh             => sub { return bless { AutoCommit => 0 }, 'Test::Handle' },
            dbtable         => 'sessions',
            encryption_keys => { 0 => slot( $KEY32, undef, 1 ) },
        );
        T2->is( scalar @warnings, 0, 'nor is a coderef, which is not called at construction' );
    }
);

# A key change on a single key is not one clean logout, it is a rolling outage:
# during a redeploy two generations serve at once, each holds a different key,
# and each destroys what the other wrote. Measured at six logouts in twelve
# requests against a half-rolled fleet. The ring is what makes the rollout a
# non-event, and these are the properties it has to have for that to work.
T2->subtest_streamed(
    'a keyring reads old sessions while writing new ones' => sub {
        my $old = 'a' x 64;
        my $new = 'b' x 64;

        # The fleet as it runs today: one slot, which is all a deployment that never
        # rotates ever writes.
        my $before        = engine( encryption_keys => { 0 => slot( $old, 'AES-256-GCM', 1 ) } );
        my $sealed_by_old = $before->_encrypt( SID, { logged_in => 1 } );
        T2->is( ( unpack 'C3', $sealed_by_old )[2], 0, 'the row records which slot sealed it' );

        # Phase one: add the new slot, keep the old one active. AND CHANGE THE
        # CIPHER WHILE WE ARE HERE -- the slot carries both, so a key rotation and
        # an algorithm change are the same operation.
        my $both_old = engine(
            encryption_keys => {
                0 => slot( $old, 'AES-256-GCM', 1 ),
                1 => slot( $new, 'ChaCha20-Poly1305' ),
            }
        );
        T2->is(
            $both_old->_decrypt( SID, $sealed_by_old ),
            { logged_in => 1 },
            'adding a slot does not disturb what the active one wrote'
        );
        T2->is( ( unpack 'C3', $both_old->_encrypt( SID, { v => 1 } ) )[2], 0,
            'and the active slot is still the one written with' );

        # Phase two: move `active`. THIS is the pod generation that would have
        # logged everybody out before.
        my $both_new = engine(
            encryption_keys => {
                0 => slot( $old, 'AES-256-GCM' ),
                1 => slot( $new, 'ChaCha20-Poly1305', 1 ),
            }
        );
        my $sealed_by_new = $both_new->_encrypt( SID, { logged_in => 1, fresh => 1 } );
        my ( undef, $new_cipher, $new_slot ) = unpack 'C3', $sealed_by_new;
        T2->is( $new_slot,   1, 'new rows record the newly active slot' );
        T2->is( $new_cipher, 4, 'and its cipher, which is a different one' );

        T2->is(
            $both_new->_decrypt( SID, $sealed_by_old ),
            { logged_in => 1 },
            'AND IT STILL READS the sessions the old generation wrote'
        );
        T2->is(
            $both_old->_decrypt( SID, $sealed_by_new ),
            { logged_in => 1, fresh => 1 },
            'while the old generation reads the new ones -- a half-rolled fleet is coherent'
        );

        # Phase three, once the old sessions have expired: drop the retired slot.
        my $after = engine( encryption_keys => { 1 => slot( $new, 'ChaCha20-Poly1305', 1 ) } );
        T2->is(
            $after->_decrypt( SID, $sealed_by_new ),
            { logged_in => 1, fresh => 1 },
            'dropping the retired slot keeps the current sessions'
        );
        T2->is( scalar $after->_decrypt( SID, $sealed_by_old ), undef, 'and only then stops reading the old ones' );
    }
);

# The one rotation mistake the slots cannot prevent: editing a slot's alg in
# place instead of giving the new cipher a slot of its own. The cipher id in the
# header is kept purely so that this says what happened.
T2->subtest_streamed(
    'changing a slot alg in place is diagnosed, not guessed at' => sub {
        my @logged;
        my $was = engine( encryption_keys => { 0 => slot( $KEY32, 'AES-256-GCM', 1 ) } );
        my $row = $was->_encrypt( SID, { v => 1 } );

        my $edited = Dancer2::Session::Pg->new(
            dbh             => sub { die "no\n" },
            dbtable         => 'sessions',
            encryption_keys => { 0 => slot( $KEY32, 'ChaCha20-Poly1305', 1 ) },
            log_cb          => sub { push @logged, [@_]; return 1 },
        );

        T2->is( scalar $edited->_decrypt( SID, $row ), undef, 'the stranded row does not decrypt' );
        T2->like( $logged[0][1], qr/slot[ ]0[ ]now[ ]says/msx, 'and the log names the slot' );
        T2->like( $logged[0][1], qr/slot[ ]of[ ]its[ ]own/msx, 'and says what to have done instead' );
    }
);

T2->subtest_streamed(
    'a rotation can change the key LENGTH as well' => sub {

        # Nothing special is needed for this, which is the point of pairing a key
        # with its cipher: each slot's key is checked against that slot's cipher and
        # nothing else, so two slots may hold keys of different lengths. Getting off
        # a 16-byte key used to be impossible without logging everybody out.
        my %ring = (
            0 => slot( 'c' x 32, 'AES-128-GCM', 1 ),    # 16 bytes
            1 => slot( 'd' x 64, 'AES-256-GCM' ),       # 32 bytes
        );

        my $was     = engine( encryption_keys => \%ring );
        my $old_row = $was->_encrypt( SID, { v => 'old' } );
        T2->is( ( unpack 'C3', $old_row )[1], 1, 'AES-128-GCM writes cipher id 1' );

        $ring{0} = slot( 'c' x 32, 'AES-128-GCM' );
        $ring{1} = slot( 'd' x 64, 'AES-256-GCM', 1 );
        my $now = engine( encryption_keys => \%ring );

        my ( undef, $cipher_id, $key_id ) = unpack 'C3', $now->_encrypt( SID, { v => 'new' } );
        T2->is( $cipher_id,                      3,              'new rows use the new cipher' );
        T2->is( $key_id,                         1,              'and the new, longer key' );
        T2->is( $now->_decrypt( SID, $old_row ), { v => 'old' }, 'while rows from the short-key slot are still readable' );
    }
);

# A principal_column naming a column _flush already writes would make it appear
# twice in one INSERT, and PostgreSQL would refuse every session write with error
# 42701. Caught at construction, because somebody's first login is the wrong
# place to discover it.
#
# Built here rather than inline below so each closure can capture its own
# lexical: a closure over the loop variable of a `map` would read $_ when it
# finally runs, long after $_ has moved on.
my @RESERVED_COLUMN_CASES;
for my $column (qw( id session_data created updated expires EXPIRES )) {
    push @RESERVED_COLUMN_CASES,
      [
        "principal_column => '$column', which this module writes itself",
        qr/may[ ]not[ ]be/msx,
        sub { engine( principal_key => 'p', principal_column => $column ) },
      ];
}

T2->subtest_streamed(
    'construction refuses what cannot work' => sub {

        # The first group is this module's own checks, whose messages carry the fix.
        # The second is Type::Tiny catching the shapes a YAML file produces, which
        # used to be accepted here and fail much later and much less clearly.
        my @refusals = (
            [
                'neither dsn nor dbh',
                qr/either[ ]dsn[ ]or[ ]dbh/msx,
                sub {
                    Dancer2::Session::Pg->new(
                        dbtable         => 'sessions',
                        encryption_keys => { 0 => slot( $KEY32, undef, 1 ) }
                    );
                },
            ],
            [
                'a missing dbtable -- there is nothing sensible to guess',
                qr/dbtable/msx,
                sub {
                    Dancer2::Session::Pg->new(
                        dsn             => 'dbi:Pg:',
                        encryption_keys => { 0 => slot( $KEY32, undef, 1 ) }
                    );
                },
            ],
            [ 'an unknown alg',           qr/unknown[ ]alg/msx,    sub { engine( alg => 'NO-SUCH-ALG' ) } ],
            [ 'an alg that is no cipher', qr/could[ ]not[ ]be/msx, sub { engine( alg => 'DBI' ) } ],
            [
                'an object missing the contract',
                qr/does[ ]not[ ]do/msx,
                sub { engine( alg => bless {}, 'Not::A::Cipher' ) },
            ],
            [
                'a key that is the wrong length for ITS OWN alg',
                qr/needs[ ]16/msx,
                sub { engine( alg => 'AES-128-GCM' ) },
            ],
            [
                'an empty key, with the openssl command to fix it',
                qr/slot[ ]0[ ]is[ ]empty/msx,
                sub { engine( key => q{} ) },
            ],
            [
                'a cipher that fails its own self check, in any slot',
                qr/not[ ]an[ ]authenticated[ ]cipher/msx,
                sub {
                    engine(
                        encryption_keys => {
                            0 => slot( $KEY32, 'AES-256-GCM', 1 ),
                            1 => slot( $KEY32, 'Test::Cipher::NoTagCheck' ),
                        }
                    );
                },
            ],
            [
                'an implausible json_module',
                qr/implausible[ ]json_module/msx,
                sub { my $e = engine( json_module => 'not a module; rm -rf' ); $e->_json },
            ],

            # --- the slots, whose mistakes are rollout mistakes ---
            [ 'no slots at all', qr/no[ ]entries/msx, sub { engine( encryption_keys => {} ) }, ],
            [
                'no slot marked active, so nothing to write with',
                qr/is[ ]active/msx,
                sub { engine( encryption_keys => { 0 => slot($KEY32) } ) },
            ],
            [
                'TWO slots active, which would silently not rotate',
                qr/both[ ]active/msx,
                sub {
                    engine(
                        encryption_keys => {
                            0 => slot( $KEY32,   'AES-256-GCM', 1 ),
                            1 => slot( 'b' x 64, 'AES-256-GCM', 1 ),
                        }
                    );
                },
            ],

            # A digits-only check would accept '00', pack it into the header as
            # the byte 0, then look it up on read as the integer 0 -- missing a
            # ring keyed by the string. Writes succeed and every read fails.
            [
                q{a non-canonical slot id, '00'},
                qr/canonical[ ]integer/msx,
                sub { engine( encryption_keys => { '00' => slot( $KEY32, undef, 1 ) } ) },
            ],
            [
                q{a non-canonical slot id, '007'},
                qr/canonical[ ]integer/msx,
                sub { engine( encryption_keys => { '007' => slot( $KEY32, undef, 1 ) } ) },
            ],

            # The gap every other check in cipher_self_check left open: all of
            # them test AUTHENTICATION, and a cipher can authenticate flawlessly
            # while storing the session in the clear.
            [
                'a cipher that authenticates but never encrypts',
                qr/stored[ ]in[ ]the[ ]clear/msx,
                sub { engine( encryption_keys => { 0 => slot( $KEY32, 'Test::Cipher::NeverEncrypts', 1 ) } ) },
            ],

            # 1..127 is the core's whether or not a built-in uses it yet. There
            # is no interop check to offer for an unused id -- nothing to interop
            # with -- so the answer is simply no.
            [
                'a cipher squatting on a reserved id the core has not used yet',
                qr/reserves[ ]for[ ]its[ ]own[ ]ciphers/msx,
                sub { engine( encryption_keys => { 0 => slot( $KEY32, 'Test::Cipher::SquatsOnUnusedCoreId', 1 ) } ) },
            ],

            # An id names one stored format. Claiming a built-in's id promises
            # byte compatibility with it, and that promise is now checked
            # rather than documented.
            [
                q{a new cipher that helps itself to AES-256-GCM's id},
                qr/claiming[ ]it[ ]means[ ]being[ ]able/msx,
                sub { engine( encryption_keys => { 0 => slot( $KEY32, 'Test::Cipher::StealsAesId', 1 ) } ) },
            ],
            [
                'and the refusal says where to get an id of its own',
                qr/128[.][.]255/msx,
                sub { engine( encryption_keys => { 0 => slot( $KEY32, 'Test::Cipher::StealsAesId', 1 ) } ) },
            ],

            # Several slots MAY share a cipher -- that is an ordinary key
            # rotation. Two different classes claiming one id may not: the
            # header's cipher byte is what diagnoses a slot whose alg was
            # edited in place, and it could not tell them apart.
            [
                'two third-party classes claiming one cipher id',
                qr/claimed[ ]by[ ]both/msx,
                sub {
                    engine(
                        encryption_keys => {
                            0 => slot( $KEY32, 'Test::Cipher::ThirdPartyTwoHundred', 1 ),
                            1 => slot( $KEY32, 'Test::Cipher::AlsoTwoHundred' ),
                        }
                    );
                },
            ],
            [
                'a supplied handle that will not raise errors',
                qr/RaiseError[ ]off/msx,
                sub {
                    my $engine = Dancer2::Session::Pg->new(
                        dbh             => bless( { RaiseError => 0 }, 'Test::Handle::NotRaising' ),
                        dbtable         => 'sessions',
                        encryption_keys => { 0 => slot( $KEY32, undef, 1 ) },
                    );
                    $engine->_dbh;
                },
            ],
            [
                'a slot id outside the one byte the header has',
                qr/0[.][.]255/msx,
                sub { engine( encryption_keys => { 300 => slot( $KEY32, undef, 1 ) } ) },
            ],
            [
                'a slot that is a bare key rather than a hash',
                qr/must[ ]be[ ]a[ ]hash/msx,
                sub { engine( encryption_keys => { 0 => $KEY32 } ) },
            ],
            [
                'encryption_keys missing entirely',
                qr/encryption_keys/msx,
                sub {
                    Dancer2::Session::Pg->new( dbh => sub { 1 }, dbtable => 'sessions' );
                },
            ],

            # --- the type constraints, i.e. what a configuration file gets wrong ---
            [
                'a dbh that is a string, not a handle or a coderef',
                qr/dbh/msx,
                sub {
                    Dancer2::Session::Pg->new(
                        dbh             => 'dbi:Pg:',
                        dbtable         => 's',
                        encryption_keys => { 0 => slot( $KEY32, undef, 1 ) }
                    );
                },
            ],
            [
                'connect_timeout that is not a number',
                qr/connect_timeout/msx,
                sub { engine( connect_timeout => 'two' ) },
            ],
            [ 'an empty dbtable', qr/dbtable/msx, sub { engine( dbtable => q{} ) } ],
            [
                'principal_key that is neither a name nor a coderef',
                qr/principal_key/msx,
                sub { engine( principal_key => {} ) },
            ],
            [
                'an empty principal_column',
                qr/principal_column/msx,
                sub { engine( principal_key => 'p', principal_column => q{} ) },
            ],

            @RESERVED_COLUMN_CASES,
            [ 'encryption_keys that is not a hash', qr/encryption_keys/msx, sub { engine( encryption_keys => 'a key' ) }, ],
        );

        for my $case (@refusals) {
            my ( $what, $expected, $code ) = @{$case};
            my $ok = eval { $code->(); 1 };
            T2->ok( !$ok, "refused: $what" );
            T2->like( $EVAL_ERROR, $expected, 'and the message names the attribute or the reason' );
        }
    }
);

# The check has to let the legitimate case through, or it is just a ban on
# replacing a built-in -- which is a thing somebody will need to do (a
# hardware-accelerated or audited AES, vendored for one deployment).
T2->subtest_streamed(
    'a genuine drop-in may claim the built-in id it replaces' => sub {
        my $engine = engine( encryption_keys => { 0 => slot( $KEY32, 'Test::Cipher::RealAesDropIn', 1 ) } );
        T2->ok( $engine, 'a byte-compatible replacement is accepted for cipher id 3' );

        # And the point of allowing it: rows written by the built-in open under
        # the replacement, and the other way round.
        my $built_in = engine( encryption_keys => { 0 => slot( $KEY32, 'AES-256-GCM', 1 ) } );
        my $old_row  = $built_in->_encrypt( 'sid', { written_by => 'built-in' } );
        T2->is(
            $engine->_decrypt( 'sid', $old_row ),
            { written_by => 'built-in' },
            'the replacement reads a row the built-in wrote'
        );

        my $new_row = $engine->_encrypt( 'sid', { written_by => 'replacement' } );
        T2->is(
            $built_in->_decrypt( 'sid', $new_row ),
            { written_by => 'replacement' },
            'and the built-in reads a row the replacement wrote'
        );
    }
);

T2->done_testing;
