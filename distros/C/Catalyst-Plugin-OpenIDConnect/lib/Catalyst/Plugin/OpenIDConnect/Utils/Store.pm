package Catalyst::Plugin::OpenIDConnect::Utils::Store;

use strict;
use warnings;
use Moose;
use namespace::autoclean;

use Try::Tiny;
use Bytes::Random::Secure qw(random_bytes);
use MIME::Base64 qw(encode_base64url);

with 'Catalyst::Plugin::OpenIDConnect::Role::Store';

=head1 NAME

Catalyst::Plugin::OpenIDConnect::Utils::Store - In-process memory store for OIDC state

=head1 DESCRIPTION

Provides in-process memory storage for authorization codes and OIDC session
state. Suitable for development and single-process deployments.

B<Not suitable for multi-process servers such as FastCGI or pre-forking>
because each worker process has its own independent copy of the data.
For those deployments, use L<Catalyst::Plugin::OpenIDConnect::Utils::Store::Redis>
or another shared-backend store that consumes
L<Catalyst::Plugin::OpenIDConnect::Role::Store>.

=head1 ATTRIBUTES

=head2 codes

Storage for authorization codes (code => {client_id, user, scope, ...})

=cut

has codes => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

=head2 sessions

Storage for user sessions (session_id => {user, tokens, ...})

=cut

has sessions => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

=head2 logger

Optional logger instance for debug/info logging.

=cut

has logger => (
    is       => 'ro',
    isa      => 'Maybe[Object]',
    required => 0,
);

# Private storage for refresh token JTIs (MED-1).

has _refresh_tokens => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

# Secondary index: sub => { jti => 1 }  Used for bulk revocation at logout.
has _rt_by_sub => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

=head1 METHODS

=head2 create_authorization_code($client_id, $user, $scope, $redirect_uri, $nonce, $pkce)

Creates an authorization code for the given parameters.  C<$pkce> is an
optional hashref with keys C<code_challenge> and C<code_challenge_method>;
omit or pass C<undef> for non-PKCE flows.

Returns the authorization code string.

=cut

sub create_authorization_code {
    my ( $self, $client_id, $user, $scope, $redirect_uri, $nonce, $pkce ) = @_;

    $self->logger->debug("Creating authorization code for client: $client_id") if $self->logger;

    my $code = _generate_secure_random();

    $self->codes->{$code} = {
        client_id             => $client_id,
        user                  => $user,
        scope                 => $scope,
        redirect_uri          => $redirect_uri,
        nonce                 => $nonce,
        created_at            => time(),
        expires_at            => time() + 600,  # 10 minutes
        ( $pkce ? (
            code_challenge        => $pkce->{code_challenge},
            code_challenge_method => $pkce->{code_challenge_method},
        ) : () ),
    };

    $self->logger->debug("Authorization code created: $code (expires in 600 seconds)") if $self->logger;

    return $code;
}

=head2 get_authorization_code($code)

Retrieves an authorization code by value.

Returns the code data hashref or undef if not found.

=cut

sub get_authorization_code {
    my ( $self, $code ) = @_;

    $self->logger->debug("Retrieving authorization code: $code") if $self->logger;

    my $code_data = $self->codes->{$code};

    return unless $code_data;

    # Check if code is expired
    if ( $code_data->{expires_at} < time() ) {
        $self->logger->warn("Authorization code expired: $code") if $self->logger;
        delete $self->codes->{$code};
        return;
    }

    $self->logger->debug("Authorization code found: $code") if $self->logger;
    return $code_data;
}

=head2 consume_authorization_code($code)

Atomically deletes the authorization code and returns its data.  Uses Perl's
C<delete> which fetches and removes the hash entry in a single operation,
making it race-free within a single process.

Returns the code data hashref on success, or C<undef> if the code does not
exist or has expired.

=cut

sub consume_authorization_code {
    my ( $self, $code ) = @_;

    $self->logger->debug("Consuming authorization code: $code") if $self->logger;

    # delete() is atomic within a single process: it removes and returns the
    # value in one step, preventing two concurrent requests from both
    # succeeding a check-then-delete sequence.
    my $code_data = delete $self->codes->{$code};
    return unless $code_data;

    if ( $code_data->{expires_at} < time() ) {
        $self->logger->warn("Authorization code expired at consume time: $code")
            if $self->logger;
        return;
    }

    $self->logger->debug("Authorization code consumed: $code") if $self->logger;
    return $code_data;
}

=head2 store_refresh_token($jti, $sub, $client_id, $ttl)

Stores a refresh token JTI with the associated subject, client, and a TTL in
seconds.  Called at token-issuance time so that the token endpoint can later
enforce single-use semantics via L</consume_refresh_token>.

=cut

sub store_refresh_token {
    my ( $self, $jti, $sub, $client_id, $ttl ) = @_;
    $self->_refresh_tokens->{$jti} = {
        sub       => $sub,
        client_id => $client_id,
        exp       => time() + $ttl,
    };
    # Secondary index by subject so all tokens can be revoked at logout.
    $self->_rt_by_sub->{$sub}{$jti} = 1;
}

=head2 consume_refresh_token($jti)

Atomically removes the JTI from the store and returns the associated data
hashref, or C<undef> if absent or expired (already used / revoked / TTL
elapsed).

=cut

sub consume_refresh_token {
    my ( $self, $jti ) = @_;
    my $data = delete $self->_refresh_tokens->{$jti};
    return unless $data;
    if ( $data->{exp} < time() ) {
        delete $self->_rt_by_sub->{ $data->{sub} }{$jti};
        return;
    }
    delete $self->_rt_by_sub->{ $data->{sub} }{$jti};
    return $data;
}

=head2 revoke_refresh_tokens_for_user($sub)

Removes all refresh token JTIs for the given subject identifier from the store.
Called at logout time to prevent re-use of stolen tokens.

=cut

sub revoke_refresh_tokens_for_user {
    my ( $self, $sub ) = @_;
    my $jtis = delete $self->_rt_by_sub->{$sub} // {};
    delete $self->_refresh_tokens->{$_} for keys %{$jtis};
}

# Generate a cryptographically secure random string for codes and tokens.
# Uses Bytes::Random::Secure to draw from the OS CSPRNG (e.g. /dev/urandom),
# which is safe even after fork() — important for pre-forking servers.
sub _generate_secure_random {
    # 120 random bytes -> 160 base64url characters; after stripping the
    # non-alphanumeric "-" and "_" characters (roughly 3% of chars) we have
    # well over 128 alphanumeric characters to work with.
    my $bytes   = random_bytes(120);
    my $encoded = encode_base64url($bytes);
    $encoded    =~ s/[^a-zA-Z0-9]//g;
    return substr( $encoded, 0, 128 );
}

__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHOR

Tim F. Rayner

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.

=cut
