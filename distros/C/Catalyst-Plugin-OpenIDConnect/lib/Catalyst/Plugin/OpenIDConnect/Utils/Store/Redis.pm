package Catalyst::Plugin::OpenIDConnect::Utils::Store::Redis;

use strict;
use warnings;
use Moose;
use namespace::autoclean;

use JSON::MaybeXS qw(encode_json decode_json);
use Bytes::Random::Secure qw(random_bytes);
use MIME::Base64 qw(encode_base64url);
use Try::Tiny;

with 'Catalyst::Plugin::OpenIDConnect::Role::Store';

=head1 NAME

Catalyst::Plugin::OpenIDConnect::Utils::Store::Redis - Redis-backed OIDC store

=head1 SYNOPSIS

    # In your Catalyst application configuration:
    'Plugin::OpenIDConnect' => {
        store_class => 'Catalyst::Plugin::OpenIDConnect::Utils::Store::Redis',
        store_args  => {
            server => '127.0.0.1:6379',  # default
            prefix => 'myapp:oidc:',     # optional namespace prefix
            # password => 'secret',      # if Redis AUTH is required
        },
        issuer => { ... },
        clients => { ... },
    },

=head1 DESCRIPTION

A Redis-backed implementation of L<Catalyst::Plugin::OpenIDConnect::Role::Store>
that stores authorization codes in Redis with automatic TTL expiry.

Because all FastCGI/pre-fork worker processes share the same Redis server, this
backend is safe for multi-process deployments. Code expiry is enforced natively
by Redis via C<SETEX>, so no background cleanup is needed.

Requires the L<Redis::Fast> module (C<Redis::Fast> is preferred for performance;
C<Redis> also works; install whichever suits your environment).

=head1 ATTRIBUTES

=head2 server

The Redis server address in C<< host:port >> form. Defaults to C<127.0.0.1:6379>.

=cut

has server => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1:6379',
);

=head2 prefix

Key namespace prefix prepended to every Redis key. Defaults to C<oidc:code:>.
Set this to a unique value per application to avoid collisions on shared Redis
instances.

=cut

has prefix => (
    is      => 'ro',
    isa     => 'Str',
    default => 'oidc:code:',
);

=head2 password

Optional Redis AUTH password. Leave unset if your Redis server does not require
authentication. If the environment variable C<REDIS_PASSWORD> is set, it will
be have been passed as the default value for this attribute by the plugin.

=cut

has password => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 0,
);

=head2 code_ttl

Lifetime of an authorization code in seconds. Defaults to 600 (10 minutes).
The value is passed directly to Redis C<SETEX>.

=cut

has code_ttl => (
    is      => 'ro',
    isa     => 'Int',
    default => 600,
);

=head2 logger

Optional logger instance for debug/info/warn logging.

=cut

has logger => (
    is       => 'ro',
    isa      => 'Maybe[Object]',
    required => 0,
);

=head2 _redis

The underlying Redis connection, lazily created on first use. This defers the
TCP connection until after the parent process has forked, which is necessary for
pre-forking servers: each worker gets its own independent socket.

=cut

has _redis => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_redis',
);

sub _build_redis {
    my ($self) = @_;

    # Prefer Redis::Fast when available; fall back to Redis.
    my $class;
    for my $candidate (qw( Redis::Fast Redis )) {
        if ( eval "require $candidate; 1" ) {
            $class = $candidate;
            last;
        }
    }
    die 'Neither Redis::Fast nor Redis is installed. '
      . 'Install one to use the Redis store backend.'
      unless $class;

    $self->logger->debug("Connecting to Redis via $class at " . $self->server)
        if $self->logger;

    my %args = (
        server    => $self->server,
        reconnect => 60,
        every     => 500_000,   # microseconds between reconnect attempts
    );
    $args{password} = $self->password if defined $self->password;

    return $class->new(%args);
}

=head1 METHODS

=head2 create_authorization_code($client_id, $user, $scope, $redirect_uri, $nonce, $pkce)

Creates an authorization code and stores it in Redis with an automatic TTL equal
to L</code_ttl> seconds.  C<$pkce> is an optional hashref with keys
C<code_challenge> and C<code_challenge_method>; omit or pass C<undef> for
non-PKCE flows.

Returns the authorization code string.

=cut

sub create_authorization_code {
    my ( $self, $client_id, $user, $scope, $redirect_uri, $nonce, $pkce ) = @_;

    $self->logger->debug("Creating authorization code for client: $client_id")
        if $self->logger;

    my $code = _generate_secure_random();
    my $now  = time();

    my $data = encode_json({
        client_id             => $client_id,
        user                  => $user,
        scope                 => $scope,
        redirect_uri          => $redirect_uri,
        nonce                 => $nonce,
        created_at            => $now,
        expires_at            => $now + $self->code_ttl,
        ( $pkce ? (
            code_challenge        => $pkce->{code_challenge},
            code_challenge_method => $pkce->{code_challenge_method},
        ) : () ),
    });

    $self->_redis->setex( $self->prefix . $code, $self->code_ttl, $data );

    $self->logger->debug(
        "Authorization code created: $code (TTL=" . $self->code_ttl . "s)")
        if $self->logger;

    return $code;
}

=head2 get_authorization_code($code)

Retrieves authorization code data from Redis.

Returns a hashref with the code data, or C<undef> if the code does not exist
or has already expired (Redis TTL handles expiry automatically).

=cut

sub get_authorization_code {
    my ( $self, $code ) = @_;

    $self->logger->debug("Retrieving authorization code: $code") if $self->logger;

    my $raw = $self->_redis->get( $self->prefix . $code );
    return unless defined $raw;

    my $data = try {
        decode_json($raw);
    }
    catch {
        $self->logger->warn("Failed to decode authorization code data: $_")
            if $self->logger;
        undef;
    };

    $self->logger->debug("Authorization code found: $code") if $self->logger && $data;
    return $data;
}

=head2 consume_authorization_code($code)

Atomically fetches and deletes the authorization code from Redis using the
C<GETDEL> command (Redis E<ge> 6.2).  Because C<GETDEL> is a single server-side
operation it is race-free: a second concurrent request carrying the same code
will receive C<nil> from Redis and be rejected.

Returns the decoded code data hashref on success, or C<undef> if the code
does not exist, has already been consumed, or cannot be decoded.

=cut

sub consume_authorization_code {
    my ( $self, $code ) = @_;

    $self->logger->debug("Consuming authorization code: $code") if $self->logger;

    # GETDEL (Redis >= 6.2) fetches and deletes atomically in a single
    # round-trip, eliminating the GET + DEL race condition (HIGH-4).
    my $raw = $self->_redis->getdel( $self->prefix . $code );
    return unless defined $raw;

    my $data = try {
        decode_json($raw);
    }
    catch {
        $self->logger->warn("Failed to decode consumed authorization code data: $_")
            if $self->logger;
        undef;
    };

    $self->logger->debug("Authorization code consumed: $code") if $self->logger && $data;
    return $data;
}

=head2 store_refresh_token($jti, $sub, $client_id, $ttl)

Stores a refresh token JTI in Redis with C<SETEX> using C<$ttl> seconds.  Also
maintains a secondary per-subject Set (C<{prefix}rt_sub:{sub}>) so that all
tokens for a user can be revoked atomically at logout time.

=cut

sub store_refresh_token {
    my ( $self, $jti, $sub, $client_id, $ttl ) = @_;
    my $data = encode_json({ sub => $sub, client_id => $client_id });
    $self->_redis->setex( $self->prefix . 'rt:' . $jti, $ttl, $data );
    # Secondary index for bulk-revocation at logout.
    my $set_key = $self->prefix . 'rt_sub:' . $sub;
    $self->_redis->sadd( $set_key, $jti );
    $self->_redis->expire( $set_key, $ttl );
}

=head2 consume_refresh_token($jti)

Atomically fetches and deletes the JTI entry using C<GETDEL> (Redis E<ge> 6.2).
Returns the decoded data hashref, or C<undef> if absent (already used, revoked,
or expired).

=cut

sub consume_refresh_token {
    my ( $self, $jti ) = @_;
    my $raw = $self->_redis->getdel( $self->prefix . 'rt:' . $jti );
    return unless defined $raw;
    my $data = try { decode_json($raw) } catch { undef };
    if ($data) {
        $self->_redis->srem( $self->prefix . 'rt_sub:' . $data->{sub}, $jti );
    }
    return $data;
}

=head2 revoke_refresh_tokens_for_user($sub)

Revokes all outstanding refresh tokens for the given subject by iterating the
per-subject Redis Set and deleting each JTI key, then deleting the Set itself.
Called at logout time.

=cut

sub revoke_refresh_tokens_for_user {
    my ( $self, $sub ) = @_;
    my $set_key = $self->prefix . 'rt_sub:' . $sub;
    my @jtis    = $self->_redis->smembers($set_key);
    for my $jti (@jtis) {
        $self->_redis->del( $self->prefix . 'rt:' . $jti );
    }
    $self->_redis->del($set_key);
}

# Generate a cryptographically secure random string for authorization codes.
# Uses Bytes::Random::Secure which reads from the OS CSPRNG. The lazy _redis
# attribute means the connection is made after fork(), so random state is
# not shared between worker processes.
sub _generate_secure_random {
    my $bytes   = random_bytes(120);
    my $encoded = encode_base64url($bytes);
    $encoded    =~ s/[^a-zA-Z0-9]//g;
    return substr( $encoded, 0, 128 );
}

__PACKAGE__->meta->make_immutable;
1;

=head1 DEPENDENCIES

L<Redis::Fast> (preferred) or L<Redis>, plus L<JSON::MaybeXS> and
L<Bytes::Random::Secure>.

=head1 AUTHOR

Tim F. Rayner

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.

=cut
