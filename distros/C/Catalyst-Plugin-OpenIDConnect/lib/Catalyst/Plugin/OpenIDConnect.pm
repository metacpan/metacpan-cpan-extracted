package Catalyst::Plugin::OpenIDConnect;

use strict;
use warnings;
use Moose::Role;
use namespace::autoclean;

use Catalyst::Plugin::OpenIDConnect::Context;
use Catalyst::Plugin::OpenIDConnect::Utils::JWT;
use Catalyst::Plugin::OpenIDConnect::Utils::Store;
use Catalyst::Plugin::OpenIDConnect::Role::Store;
use Crypt::OpenSSL::RSA;
use Crypt::PK::RSA;
use JSON::MaybeXS qw(encode_json decode_json);
use Try::Tiny;
use DateTime;
use DateTime::Format::ISO8601;
use Data::UUID;
use URI;

our $VERSION = '0.15';

=head1 NAME

Catalyst::Plugin::OpenIDConnect - OpenID Connect provider plugin for Catalyst

=head1 DESCRIPTION

A Catalyst plugin implementing the OpenID Connect specification,
providing OAuth 2.0 authentication and authorization. Note that this plugin 
does not implement the OIDC Client role; it is intended for applications 
acting as OIDC providers (authorization servers).

This plugin provides the core OpenIDConnect functionality (JWT handling, 
state management, and a reusable controller). To use it in your application, 
you must create a controller in your app's namespace that extends the plugin's 
controller (see below). This allows you to keep full control over your routing
while cooperating with ACL and other route-processing plugins.

=head1 CONFIGURATION

    package MyApp;
    use Catalyst qw/
        OpenIDConnect
        Session
        Session::Store::File
        Session::State::Cookie
    /;

    MyApp->config(
        'Plugin::OpenIDConnect' => {
            issuer => {
                url => 'http://localhost:5000',
                private_key_file => '/path/to/private.pem',
                public_key_file => '/path/to/public.pem',
                key_id => 'key-123',
            },
            clients => {
                'my-client' => {
                    client_secret => 'secret123',
                    redirect_uris => ['http://localhost:3000/callback'],
                    response_types => ['code'],
                    grant_types => ['authorization_code'],
                    scope => 'openid profile email',
                },
            },
        },
    );

=head1 CREATING THE OPENIDCONNECT CONTROLLER

To enable the OpenIDConnect endpoints, create a controller in your app that extends
the plugin's controller. Create the file C<lib/MyApp/Controller/OpenIDConnect.pm> 
(where MyApp is your app's namespace) with the following content:

    package MyApp::Controller::OpenIDConnect;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Plugin::OpenIDConnect::Controller::Root' }

    __PACKAGE__->meta->make_immutable;
    1;

Then, in your main app module, explicitly load this controller before setup:

    package MyApp;
    use Catalyst qw/
        OpenIDConnect
        Session
        Session::Store::File
        Session::State::Cookie
    /;
    
    # Load the controller before setup so Catalyst discovers it
    use MyApp::Controller::OpenIDConnect;
    
    MyApp->config(...);
    MyApp->setup(...);

Setting up the controller in this way allows you to keep full control over your
routing, and avoid namespace conflicts with ACL and other route-processing plugins.
The plugin's controller will automatically mount the standard OpenID Connect
endpoints (e.g. C</authorize>, C</token>, C</userinfo>) under the C</openidconnect>
path, so you can access them at C</openidconnect/authorize>, etc.

=head1 ROUTES ADDED TO THE APPLICATION

The plugin's controller adds the following routes to the application:

    GET  /.well-known/openid-configuration
    GET  /openidconnect/authorize
    POST /openidconnect/token
    GET  /openidconnect/userinfo
    GET  /openidconnect/jwks
    POST /openidconnect/logout

=cut

requires 'config', 'log', 'uri_for', 'user', 'request', 'response';

# Per-application-class storage for JWT and Store instances.
# Keyed by consuming application class name so that multiple Catalyst apps
# loaded in the same Perl interpreter each hold their own instances and cannot
# accidentally overwrite each other's JWT keys or stores (MED-3).
my %_oidc_jwt_by_class;
my %_oidc_store_by_class;

=head1 ATTRIBUTES

=head2 _oidc_jwt

JWT handler instance.

=cut

# Accessor method for JWT handler
sub _oidc_jwt {
    my ($self, $value) = @_;
    my $class = ref($self) || $self;
    if (defined $value) {
        die 'JWT handler must be an instance of Catalyst::Plugin::OpenIDConnect::Utils::JWT'
            unless ref $value && $value->isa('Catalyst::Plugin::OpenIDConnect::Utils::JWT');
        $_oidc_jwt_by_class{$class} = $value;
    }
    return $_oidc_jwt_by_class{$class};
}

=head2 _oidc_store

State and code storage.

=cut

# Accessor method for Store handler
sub _oidc_store {
    my ($self, $value) = @_;
    my $class = ref($self) || $self;
    if (defined $value) {
        die 'Store handler must implement Catalyst::Plugin::OpenIDConnect::Role::Store'
            unless ref $value && $value->DOES('Catalyst::Plugin::OpenIDConnect::Role::Store');
        $_oidc_store_by_class{$class} = $value;
    }
    return $_oidc_store_by_class{$class};
}

=head1 METHODS

=head2 setup

Catalyst setup hook - initialize the plugin. Note that this hook can effectively be blocked
in the consuming app by a similar setup method checking for configuration and deleting 
$config->{issuer} if not properly configured. This allows the consuming app to control whether 
the plugin initializes or not, which is useful for example in FastCGI deployments where multiple 
apps share the same codebase but only some are OIDC providers.

=cut

after 'setup' => sub {
    my ($app) = @_;
    
    my $config = $app->config->{'Plugin::OpenIDConnect'} || {};
    
    $app->log->debug('OpenID Connect plugin setup starting') if $config->{debug};
    
    # Only initialize if properly configured
    if ( $config->{issuer} && $config->{issuer}{private_key_file} ) {
        try {
            $app->log->debug('Initializing OpenID Connect with issuer: ' . $config->{issuer}{url}) if $config->{debug};
            
            # Create JWT handler
            my $jwt = $app->_oidc_build_jwt_handler($config);
            $app->_oidc_jwt($jwt);
            $app->log->debug('JWT handler initialized successfully') if $config->{debug};
            
            # Create store - class and constructor args are configurable so that
            # shared-memory backends (e.g. Redis) can be used under FastCGI.
            my $store_class = $config->{store_class}
                || 'Catalyst::Plugin::OpenIDConnect::Utils::Store';
            my $store_args  = { %{ $config->{store_args} || {} } };

            # Allow the Redis password to be supplied via the environment so
            # that secrets are not embedded in application config files.
            if ( !exists $store_args->{password} && defined $ENV{REDIS_PASSWORD} && $ENV{REDIS_PASSWORD} ne '' ) {
                $store_args->{password} = $ENV{REDIS_PASSWORD};
            }

            # Dynamically load the store class (no-op if already loaded)
            require Module::Runtime;
            Module::Runtime::require_module($store_class);

            my $store = $store_class->new(
                logger => $app->log,
                %$store_args,
            );
            die "store_class '$store_class' does not implement Role::Store"
                unless $store->DOES('Catalyst::Plugin::OpenIDConnect::Role::Store');

            $app->_oidc_store($store);
            $app->log->debug("State store initialized ($store_class)") if $config->{debug};
        }
        catch {
            $app->log->error("Failed to initialize OpenID Connect plugin: $_");
            die $_;
        };
    } else {
        $app->log->warn('OpenID Connect plugin not configured (missing issuer.private_key_file)');
    }
};

before setup_finalize => sub {
    my ($app) = @_;
    my $config = $app->config->{'Plugin::OpenIDConnect'} || {};
    $config->{debug} ||= $app->debug;
};

=head2 openidconnect()

Returns the OIDC context/handler object for use in controllers.

=cut

sub openidconnect {
    my ($c) = @_;
    return Catalyst::Plugin::OpenIDConnect::Context->new( catalyst => $c );
}

=head2 _oidc_build_jwt_handler($config)

Builds and configures the JWT handler from config.

=cut

sub _oidc_build_jwt_handler {
    my ( $c, $config ) = @_;

    $c->log->debug('Building JWT handler from configuration') if $config->{debug};

    my $issuer_cfg = $config->{issuer} || {};
    my $issuer_url = $issuer_cfg->{url} || $c->uri_for('/')->as_string;

    $c->log->debug("JWT issuer URL: $issuer_url") if $config->{debug};

    # Load private key
    my $private_key_file = $issuer_cfg->{private_key_file}
        or die 'issuer.private_key_file is required';

    $c->log->debug("Loading private key from: $private_key_file") if $config->{debug};
    
    open my $key_fh, '<', $private_key_file
        or die "Cannot read private key file: $!";
    my $key_data = do { local $/; <$key_fh> };
    close $key_fh;

    my $private_key = Crypt::OpenSSL::RSA->new_private_key($key_data);
    $c->log->debug('Private key loaded successfully') if $config->{debug};

    # Load or derive public key
    my $public_key;
    if ( my $public_key_file = $issuer_cfg->{public_key_file} ) {
        $c->log->debug("Loading public key from: $public_key_file") if $config->{debug};
        
        open $key_fh, '<', $public_key_file
            or die "Cannot read public key file: $!";
        my $pub_data = do { local $/; <$key_fh> };
        close $key_fh;
        $public_key = Crypt::OpenSSL::RSA->new_public_key($pub_data);
        $c->log->debug('Public key loaded successfully') if $config->{debug};
    } else {
        $c->log->debug('Deriving public key from private key') if $config->{debug};
        # Extract public key from private key
        $public_key = Crypt::OpenSSL::RSA->new_public_key(
            $private_key->get_public_key_string()
        );
        $c->log->debug('Public key derived successfully') if $config->{debug};
    }

    my $key_id = $issuer_cfg->{key_id} || 'default';
    $c->log->debug("Using key ID: $key_id") if $config->{debug};

    return Catalyst::Plugin::OpenIDConnect::Utils::JWT->new(
        private_key => $private_key,
        public_key  => $public_key,
        key_id      => $key_id,
        issuer      => $issuer_url,
        logger      => $c->log,
    );
}

1;

=head1 AUTHOR

Tim F. Rayner

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.

=cut
