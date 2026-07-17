use v5.36;
use Test::More;
use Test::Fatal;
use Digest::SHA qw/sha256/;
use MIME::Base64 qw/encode_base64url/;
use lib 't/lib';
use StubStore;
use TestApp::Model::OAuthStore;

my $class = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Server';
require_ok($class);

my $key      = 'k' x 32;
my $VERIFIER = 'pkce-verifier-' . ( '0' x 29 );

sub fresh_engine { return $class->new(
    store => StubStore->new, signing_key => $key,
    issuer => 'https://as', resource => 'https://rs/mcp',
) }

sub mint_code ( $eng, $verifier, $subject = 'user-9' ) {
    my $challenge = encode_base64url( sha256($verifier) );
    $eng->store->create_client({
        client_id => 'c1', redirect_uris => ['https://app/cb'] });
    my $rid = $eng->validate_authorize({
        client_id => 'c1', redirect_uri => 'https://app/cb',
        response_type => 'code', code_challenge => $challenge,
        code_challenge_method => 'S256', scope => 'example:read',
        resource => 'https://rs/mcp',
    })->{request_id};
    return $eng->issue_code( $subject, $rid )->{code};
}

sub first_pair ( $eng, $verifier = $VERIFIER, $subject = 'user-9' ) {
    my $code = mint_code( $eng, $verifier, $subject );
    return $eng->exchange_authorization_code({
        grant_type => 'authorization_code', code => $code,
        redirect_uri => 'https://app/cb', code_verifier => $verifier,
    });
}

# refresh, returning the new pair
sub do_refresh ( $eng, $rt ) {
    return $eng->refresh(
        { grant_type => 'refresh_token', refresh_token => $rt } );
}

# refresh, returning the exception (undef when it succeeded)
sub try_refresh ( $eng, $rt ) {
    return exception { do_refresh( $eng, $rt ) };
}

# every stored binding, in no particular order, for assertions about
# family identity
sub bindings ( $eng ) {
    my $r = $eng->store->refresh;
    return [ map { $r->{$_}{binding} } keys %$r ];
}

# A live token rotates once, then reports reuse on replay.
{
    my $store = StubStore->new;
    $store->create_refresh_token( 'h1',
        { client_id => 'c1', subject => 'user-9' }, time + 3600 );

    my $first = $store->rotate_refresh_token('h1');
    is( ref $first, 'HASH', 'rotate returns a hashref' );
    is( $first->{binding}{subject}, 'user-9', 'binding comes back wrapped' );
    ok( !$first->{reused}, 'a live token is not flagged as reused' );

    my $replay = $store->rotate_refresh_token('h1');
    ok( $replay,            'a replayed token is not undef' );
    ok( $replay->{reused},  'a replayed token is flagged reused' );
    is( $replay->{binding}{subject}, 'user-9',
        'the replay carries the binding so the family can be found' );
}

# Unknown and expired stay undef: they are not replays.
{
    my $store = StubStore->new;
    is( $store->rotate_refresh_token('nope'), undef, 'unknown token -> undef' );

    $store->create_refresh_token( 'old', { subject => 'u' }, time - 1 );
    is( $store->rotate_refresh_token('old'), undef, 'expired token -> undef' );
}

# A tombstone (rotated once, so revoked) that later expires must report
# undef, not reused: the expiry check has to run before the revoked check,
# or the reuse-detection window becomes unbounded instead of == refresh_ttl.
{
    my $store = StubStore->new;
    $store->create_refresh_token( 'h2',
        { client_id => 'c1', subject => 'user-9' }, time + 3600 );

    my $first = $store->rotate_refresh_token('h2');
    ok( $first, 'first rotation of h2 succeeds' );
    ok( !$first->{reused}, 'first rotation is not a replay' );

    # Backdate the now-revoked tombstone's exp into the past.
    $store->refresh->{h2}{exp} = time - 1;

    is( $store->rotate_refresh_token('h2'), undef,
        'a rotated-then-expired tombstone reports undef, not reused' );
}

# TestApp::Model::OAuthStore is a second Store implementation, backed by a
# process-wide %REFRESH hash (not per-instance like StubStore's). It names
# its binding key "b" internally but must still wrap it as "binding" on the
# way out. Use distinctive hashes so this cannot collide with rows any other
# test in this process happens to leave behind.
{
    my $store = TestApp::Model::OAuthStore->new;
    $store->create_refresh_token( 'oauthstore-h1-9f3a2e',
        { client_id => 'c1', subject => 'user-oauthstore-9' }, time + 3600 );

    my $first = $store->rotate_refresh_token('oauthstore-h1-9f3a2e');
    is( ref $first, 'HASH', 'rotate returns a hashref' );
    is( $first->{binding}{subject}, 'user-oauthstore-9',
        'binding comes back wrapped' );
    ok( !$first->{reused}, 'a live token is not flagged as reused' );

    my $replay = $store->rotate_refresh_token('oauthstore-h1-9f3a2e');
    ok( $replay,           'a replayed token is not undef' );
    ok( $replay->{reused}, 'a replayed token is flagged reused' );
    is( $replay->{binding}{subject}, 'user-oauthstore-9',
        'the replay carries the binding so the family can be found' );
}

# TestApp::Model::OAuthStore::revoke_family, exercised directly at the Store
# layer (not through HTTP, where reuse and unknown are deliberately
# indistinguishable and so cannot pin that a *family* -- not just one token
# -- was revoked). Storage is process-wide %REFRESH, so distinctive hashes
# and family ids are used and the store is not assumed to start empty.
{
    my $store = TestApp::Model::OAuthStore->new;
    my $b = sub {
        return {
            client_id => 'c1', subject => 'user-oauthstore-fam',
            family_id => 'oauthstore-FAM-7c1d',
        };
    };
    $store->create_refresh_token( "oauthstore-live$_-7c1d", $b->(), time + 3600 )
        for 1 .. 3;
    $store->create_refresh_token(
        'oauthstore-other-7c1d',
        {
            client_id => 'c1', subject => 'user-oauthstore-fam',
            family_id => 'oauthstore-OTHER-7c1d',
        },
        time + 3600,
    );

    is( $store->revoke_family('oauthstore-FAM-7c1d'), 3,
        'revokes every live token in the family' );
    ok( $store->rotate_refresh_token("oauthstore-live$_-7c1d")->{reused},
        "oauthstore-live$_-7c1d is dead" )
        for 1 .. 3;
    ok( !$store->rotate_refresh_token('oauthstore-other-7c1d')->{reused},
        'a sibling family is untouched' );
    is( $store->revoke_family('oauthstore-FAM-7c1d'), 0,
        'revoking again is a no-op' );
}

# family_id is born at the code exchange and survives a chain of rotations
{
    my $eng  = fresh_engine();
    my $pair = first_pair($eng);

    my ($born) = map { $_->{family_id} } @{ bindings($eng) };
    ok( defined $born && length $born, 'code exchange births a family_id' );

    my $rt = $pair->{refresh_token};
    for my $hop ( 1 .. 3 ) {
        my $next = $eng->refresh({
            grant_type => 'refresh_token', refresh_token => $rt });
        $rt = $next->{refresh_token};
    }

    my @all_bindings = @{ bindings($eng) };
    ok( ( scalar( grep { defined $_->{family_id} } @all_bindings )
            == scalar @all_bindings ),
        'every binding in the chain has a defined family_id' );

    my %families = map { ( $_->{family_id} // 'MISSING' ) => 1 } @all_bindings;
    is( scalar keys %families, 1,
        'one family_id across the whole rotation chain' );
    is( ( keys %families )[0], $born, 'and it is the family born at exchange' );
}

# two independent code exchanges must not share a family_id: a non-distinct
# family_id would mean, once revoke_family is wired up, that a replay by any
# attacker revokes every refresh token for every user.
{
    my $eng1 = fresh_engine();
    my $eng2 = fresh_engine();

    first_pair( $eng1, $VERIFIER, 'user-a' );
    first_pair( $eng2, $VERIFIER, 'user-b' );

    my ($family1) = map { $_->{family_id} } @{ bindings($eng1) };
    my ($family2) = map { $_->{family_id} } @{ bindings($eng2) };

    ok( defined $family1 && length $family1,
        'first exchange births a family_id' );
    ok( defined $family2 && length $family2,
        'second exchange births a family_id' );
    isnt( $family1, $family2,
        'two independent code exchanges get different family_ids' );
}

# the invariant: _issue_token_pair refuses a binding with no family_id
{
    my $eng = fresh_engine();
    my $no_family = { client_id => 'c1', subject => 'u' };
    like(
        exception { $eng->_issue_token_pair($no_family) },
        qr/family_id/,
        '_issue_token_pair croaks without a family_id'
    );
}

# the reuse path guards family_id too: revoke_family(undef) would match
# every family_id-less row via the "// ''" comparison and revoke tokens
# across different subjects, so a reused result with no family_id must
# croak before revoke_family is ever called
{
    my $eng = fresh_engine();
    my $stale = first_pair($eng)->{refresh_token};

    no warnings 'redefine';
    local *StubStore::rotate_refresh_token = sub {
        return { binding => { client_id => 'c1', subject => 'u' }, reused => 1 };
    };
    my $revoke_called = 0;
    local *StubStore::revoke_family = sub { $revoke_called++; return 0 };

    like(
        exception { do_refresh( $eng, $stale ) },
        qr/family_id/,
        'a reused binding with no family_id croaks instead of revoking blind'
    );
    is( $revoke_called, 0,
        'revoke_family is never called when family_id is missing' );
}

# THE test: a replay kills the live token, not just the replayed one
{
    my $eng   = fresh_engine();
    my $pair  = first_pair($eng);
    my $stale = $pair->{refresh_token};
    my $live  = do_refresh( $eng, $stale )->{refresh_token};

    # attacker replays the stale token
    isnt( try_refresh( $eng, $stale ), undef,
        'replaying the stale token is rejected' );

    # the legitimate client's live token must now be dead too
    isnt( try_refresh( $eng, $live ), undef,
        'the live token is revoked by the replay (family revoked)' );
}

# cross-family isolation: one user, two devices, one replay
{
    my $eng = fresh_engine();
    my $a   = first_pair( $eng, $VERIFIER, 'user-9' );
    my $b   = first_pair( $eng, 'other-verifier-' . ( '1' x 28 ), 'user-9' );

    my $a_stale = $a->{refresh_token};
    do_refresh( $eng, $a_stale );

    isnt( try_refresh( $eng, $a_stale ), undef,
        'replay in family A is rejected' );

    # family B belongs to the same subject and must be untouched
    is( try_refresh( $eng, $b->{refresh_token} ), undef,
        'family B still refreshes: per-family, not per-subject' );
}

# a replay from deeper in the chain still kills the family
{
    my $eng  = fresh_engine();
    my $deep = first_pair($eng)->{refresh_token};

    my $rt = $deep;
    $rt = do_refresh( $eng, $rt )->{refresh_token} for 1 .. 3;

    isnt( try_refresh( $eng, $deep ), undef,
        'replaying a token from 3 hops back is rejected' );
    isnt( try_refresh( $eng, $rt ), undef,
        'and it revokes the family, killing the current token' );
}

# an unknown token revokes nothing
{
    my $eng  = fresh_engine();
    my $pair = first_pair($eng);

    my $revoked = 0;
    no warnings 'redefine';
    my $orig = \&StubStore::revoke_family;
    local *StubStore::revoke_family = sub { $revoked++; $orig->(@_) };

    isnt( try_refresh( $eng, 'garbage' ), undef,
        'an unknown refresh token is rejected' );
    is( $revoked, 0, 'an unknown token revokes no family' );

    is( try_refresh( $eng, $pair->{refresh_token} ), undef,
        'and the real token still works' );
}

# the engine revokes the replayed token's own family, exactly once, by
# family_id: passing anything else (the subject, say) would either revoke
# nothing or revoke too much
{
    my $eng   = fresh_engine();
    my $stale = first_pair($eng)->{refresh_token};
    my ($fid) = map { $_->{family_id} } @{ bindings($eng) };
    do_refresh( $eng, $stale );

    my @args;
    no warnings 'redefine';
    my $orig = \&StubStore::revoke_family;
    local *StubStore::revoke_family
        = sub { push @args, $_[1]; return $orig->(@_) };

    try_refresh( $eng, $stale );
    is_deeply( \@args, [$fid],
        'a replay revokes its own family_id, once' );
}

# a Store that cannot revoke is broken: the failure must surface, not be
# swallowed into invalid_grant while the compromised family lives on
{
    my $eng   = fresh_engine();
    my $stale = first_pair($eng)->{refresh_token};
    do_refresh( $eng, $stale );

    no warnings 'redefine';
    local *StubStore::revoke_family = sub { die "store is on fire\n" };

    like( try_refresh( $eng, $stale ), qr/store is on fire/,
        'a failing revoke_family propagates instead of becoming invalid_grant' );
}

# no oracle: reuse and unknown are indistinguishable to the client
{
    my $eng   = fresh_engine();
    my $stale = first_pair($eng)->{refresh_token};
    do_refresh( $eng, $stale );

    my $reuse   = try_refresh( $eng, $stale );
    my $unknown = try_refresh( $eng, 'garbage' );

    is( $reuse->error, $unknown->error,
        'reuse and unknown share an error code' );
    is( $reuse->error_description, $unknown->error_description,
        'and a description: no reuse oracle for an attacker' );
}

# revoke_family is idempotent
{
    my $eng  = fresh_engine();
    first_pair($eng);
    my ($fid) = map { $_->{family_id} } @{ bindings($eng) };

    my $first = $eng->store->revoke_family($fid);
    is( $first, 1, 'revoking a one-token family revokes one token' );
    is( $eng->store->revoke_family($fid), 0,
        'revoking again is a no-op, not an error' );
}

# THE family test: revoke_family revokes every live member of the family,
# not just one. The engine can never leave more than one live token per
# family (each rotation tombstones its predecessor), so this state is built
# directly against the Store instead. A Store that stops after the first
# match (e.g. "WHERE family_id = ? LIMIT 1") would pass every other test in
# this file, because those never exercise a family with more than one live
# token.
{
    my $store = StubStore->new;
    my $b = sub {
        return { client_id => 'c1', subject => 'u', family_id => 'FAM' };
    };
    $store->create_refresh_token( "live$_", $b->(), time + 3600 ) for 1 .. 3;
    $store->create_refresh_token(
        'other',
        { client_id => 'c1', subject => 'u', family_id => 'OTHER' },
        time + 3600,
    );

    is( $store->revoke_family('FAM'), 3,
        'revokes every live token in the family' );
    ok( $store->rotate_refresh_token("live$_")->{reused}, "live$_ is dead" )
        for 1 .. 3;
    ok( !$store->rotate_refresh_token('other')->{reused},
        'a sibling family is untouched' );
    is( $store->revoke_family('FAM'), 0, 'revoking again is a no-op' );
}

# A replay racing a rotation must not leave a live token in the dead family.
{
    my $eng   = fresh_engine();
    my $stale = first_pair($eng)->{refresh_token};

    my $interleaved = 0;
    no warnings 'redefine';
    my $orig = \&StubStore::create_refresh_token;
    local *StubStore::create_refresh_token = sub {
        my @args = @_;
        # R2 lands in R1's gap: after R1 rotated, before R1 created.
        eval { do_refresh( $eng, $stale ) } unless $interleaved++;
        return $orig->(@args);
    };

    my $r1 = eval { do_refresh( $eng, $stale ) };
    ok( $interleaved, 'the replay interleaved' );

    my $rt = $r1 && $r1->{refresh_token};
    my $survived = 0;
    if ($rt) {
        for ( 1 .. 5 ) {
            my $next = eval { do_refresh( $eng, $rt ) } or last;
            $rt = $next->{refresh_token};
            $survived++;
        }
    }
    is( $survived, 0, 'no rotation survives a raced family revocation' );
}

done_testing;
