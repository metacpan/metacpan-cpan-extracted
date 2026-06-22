package Catalyst::Plugin::OpenIDConnect::Context;

use Moose;
use namespace::autoclean;
use Catalyst::Plugin::OpenIDConnect::Utils::Store;

# Per-application-class storage for extension-point callbacks.
# Keyed by the consuming application class name so that multiple Catalyst apps
# loaded in the same interpreter each hold their own handlers.
my %_scope_handler_by_class;
my %_claims_provider_by_class;

=head1 NAME

Catalyst::Plugin::OpenIDConnect::Context - OIDC provider context object

=head1 DESCRIPTION

Context object passed to controllers for accessing OIDC functionality.

=head1 ATTRIBUTES

=head2 catalyst

The Catalyst application instance.

=cut

has catalyst => (
    is  => 'ro',
    required => 1,
);

=head1 METHODS

=head2 jwt()

Returns the JWT handler instance.

=cut

sub jwt {
    my ($self) = @_;
    $self->catalyst->log->debug('Retrieving JWT handler') if $self->config->{debug};
    my $jwt = $self->catalyst->_oidc_jwt();
    unless ($jwt) {
        $self->catalyst->log->error('OpenID Connect JWT handler not initialized');
        die 'OpenID Connect JWT handler not initialized. Check your Plugin::OpenIDConnect configuration (issuer.private_key_file and issuer.public_key_file required).';
    }
    return $jwt;
}

=head2 store()

Returns the state store instance.

=cut

sub store {
    my ($self) = @_;
    $self->catalyst->log->debug('Retrieving state store') if $self->config->{debug};
    my $store = $self->catalyst->_oidc_store();
    return $store if $store;

    $self->catalyst->log->debug('Creating new state store instance') if $self->config->{debug};

    my $store_class = $self->config->{store_class}
        || 'Catalyst::Plugin::OpenIDConnect::Utils::Store';
    my $store_args  = { %{ $self->config->{store_args} || {} } };

    # Allow the Redis password to be supplied via the environment so
    # that secrets are not embedded in application config files.
    if ( !exists $store_args->{password} && defined $ENV{REDIS_PASSWORD} && $ENV{REDIS_PASSWORD} ne '' ) {
        $store_args->{password} = $ENV{REDIS_PASSWORD};
    }

    require Module::Runtime;
    Module::Runtime::require_module($store_class);

    my $new_store = $store_class->new(
        logger => $self->catalyst->log,
        %$store_args,
    );
    $self->catalyst->_oidc_store($new_store) if $self->catalyst->can('_oidc_store');
    return $new_store;
}

=head2 config()

Returns the OIDC configuration.

=cut

sub config {
    my ($self) = @_;
    return $self->catalyst->config->{'Plugin::OpenIDConnect'} || {};
}

=head2 get_client($client_id)

Retrieves a client configuration by client ID.

=cut

sub get_client {
    my ( $self, $client_id ) = @_;
    $self->catalyst->log->debug("Looking up client: $client_id") if $self->config->{debug};
    my $clients = $self->config->{clients} || {};
    my $client = $clients->{$client_id};
    if ($client) {
        $self->catalyst->log->debug("Found client configuration for: $client_id") if $self->config->{debug};
    } else {
        $self->catalyst->log->warn("Client not found: $client_id");
    }
    return $client;
}

=head2 scope_handler($handler)

Sets or retrieves the custom scope validation/processing handler.

When a handler is set, it is called during authorization after the built-in
scope intersection with the client's registered scopes.  The handler receives
the Catalyst context object and the effective, space-separated scope string,
and must return a list of scopes.  Throwing an exception from the handler
will reject the authorization request with an C<invalid_scope> error.

Handlers are stored per consuming application class, so setting a handler
once (e.g. during application startup) applies to all subsequent requests.

    $c->openidconnect->scope_handler(sub {
        my ($c, $scope_string) = @_;
        my @scopes = split /\s+/, $scope_string;
        for my $scope (@scopes) {
            die "Unknown scope: $scope" unless valid_scope($scope);
        }
        return @scopes;
    });

=cut

sub scope_handler {
    my ( $self, $handler ) = @_;
    my $class = ref( $self->catalyst ) || $self->catalyst;
    if ( @_ > 1 ) {
        die 'scope_handler must be a code reference'
            if defined $handler && ref $handler ne 'CODE';
        $_scope_handler_by_class{$class} = $handler;
        return $self;
    }
    return $_scope_handler_by_class{$class};
}

=head2 claims_provider($provider)

Sets or retrieves the custom claims provider.

When a provider is set, it is called by C<get_user_claims()> instead of the
default config-based field mapping.  The provider receives the Catalyst
context object and the user object (hash reference or object with accessors),
and must return a hash reference of JWT claims.

Providers are stored per consuming application class, so setting a provider
once (e.g. during application startup) applies to all subsequent requests.

    $c->openidconnect->claims_provider(sub {
        my ($c, $user) = @_;
        return {
            sub          => $user->id,
            name         => $user->full_name,
            custom_claim => $user->some_attribute,
        };
    });

=cut

sub claims_provider {
    my ( $self, $provider ) = @_;
    my $class = ref( $self->catalyst ) || $self->catalyst;
    if ( @_ > 1 ) {
        die 'claims_provider must be a code reference'
            if defined $provider && ref $provider ne 'CODE';
        $_claims_provider_by_class{$class} = $provider;
        return $self;
    }
    return $_claims_provider_by_class{$class};
}

=head2 get_user_claims($user)

Extracts user claims based on the configured user_claims mapping.

The user parameter can be a hash reference or an object with accessor methods.

=cut

sub get_user_claims {
    my ( $self, $user ) = @_;

    $self->catalyst->log->debug('Extracting user claims') if $self->config->{debug};

    # Delegate to the custom claims provider when one has been registered.
    if ( my $provider = $self->claims_provider ) {
        $self->catalyst->log->debug('Using custom claims provider') if $self->config->{debug};
        return $provider->( $self->catalyst, $user );
    }

    my $claims_config = $self->config->{user_claims} || {
        sub      => 'id',
        name     => 'name',
        email    => 'email',
    };

    my %claims;

    for my $claim_name ( keys %$claims_config ) {
        my $accessor = $claims_config->{$claim_name};
        my @parts = split /\./, $accessor;

        my $value = $user;
        for my $part (@parts) {
            last unless defined $value;
            if ( ref $value eq 'HASH' ) {
                $value = $value->{$part};
            } else {
                $value = $value->$part() if $value->can($part);
            }
        }

        $claims{$claim_name} = $value if defined $value;
    }

    $self->catalyst->log->debug('User claims extracted: ' . join(', ', keys %claims)) if $self->config->{debug};

    return \%claims;
}

=head2 get_discovery()

Returns the OpenID Connect provider configuration document.

=cut

sub get_discovery {
    my ($self) = @_;

    $self->catalyst->log->debug('Building OpenID Connect discovery document') if $self->config->{debug};

    my $c = $self->catalyst;
    my $issuer_url = $self->config->{issuer}{url} || $c->uri_for('/')->as_string;

    # Extract scheme and authority from issuer URL to ensure endpoints match issuer scheme
    my $base_url = $issuer_url;
    $base_url =~ s{/$}{};  # Remove trailing slash if present

    $self->catalyst->log->debug("Discovery document built for issuer: $issuer_url") if $self->config->{debug};

    return {
        issuer                          => $issuer_url,
        authorization_endpoint          => "$base_url/openidconnect/authorize",
        token_endpoint                  => "$base_url/openidconnect/token",
        userinfo_endpoint               => "$base_url/openidconnect/userinfo",
        jwks_uri                        => "$base_url/openidconnect/jwks",
        end_session_endpoint            => "$base_url/openidconnect/logout",
        registration_endpoint           => undef,
        scopes_supported                => [qw(openid profile email phone address)],
        response_types_supported        => [qw(code)],
        response_modes_supported        => [qw(query fragment form_post)],
        grant_types_supported           => [qw(authorization_code refresh_token)],
        subject_types_supported         => [qw(public pairwise)],
        id_token_signing_alg_values_supported => ['RS256'],
        userinfo_signing_alg_values_supported => ['RS256'],
        request_parameter_supported    => 1,
        request_uri_parameter_supported => 1,
        claims_supported                => [
            qw(
                sub name given_name family_name middle_name nickname
                preferred_username profile picture website email email_verified
                gender birthdate zoneinfo locale phone_number phone_number_verified
                address updated_at
            )
        ],
        claim_types_supported          => [qw(normal aggregated distributed)],
    };
}

__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHOR

Tim F. Rayner

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.

=cut
