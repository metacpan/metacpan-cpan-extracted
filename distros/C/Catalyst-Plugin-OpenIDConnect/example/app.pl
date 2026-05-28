#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Data::UUID;

# Explicitly require the OpenIDConnect controller before app setup
require OIDCExample::Controller::OpenIDConnect;

package OIDCExample;

use Catalyst::Runtime 5.90100;
use Catalyst;

use strict;
use warnings;

__PACKAGE__->config(
    name => 'OIDCExample',
    
    # Disable deprecated actions
    'disable_component_resolution_regex_fallback' => 1,
    
    # OpenID Connect configuration
    'Plugin::OpenIDConnect' => {
        issuer => {
            url                => 'http://localhost:5000',
            private_key_file   => 'example/keys/private.pem',
            public_key_file    => 'example/keys/public.pem',
            key_id             => 'example-key-1',
        },
        
        # Client configurations
        clients => {
            'example-client' => {
                client_secret             => 'example-client-secret',
                redirect_uris             => ['http://localhost:3000/callback'],
                post_logout_redirect_uris => ['http://localhost:3000/logged-out'],
                response_types            => 'code',
                grant_types               => 'authorization_code refresh_token',
                scope                     => 'openid profile email',
            },
            'test-app' => {
                client_secret             => 'test-secret-12345',
                redirect_uris             => [
                    'http://localhost:8080/auth/callback',
                    'http://localhost:8080/callback',
                ],
                post_logout_redirect_uris => ['http://localhost:8080/logout-complete'],
                response_types            => 'code',
                grant_types               => 'authorization_code refresh_token',
                scope                     => 'openid profile email phone',
            },
        },
        
        # Map user attributes to OIDC claims
        user_claims => {
            sub      => 'id',
            name     => 'name',
            email    => 'email',
            picture  => 'avatar_url',
        },
    },
    
    # Session configuration
    'Plugin::Session' => {
        expires => 2592000,  # 30 days
    },
);

# Load plugins
__PACKAGE__->setup(
    qw/
        -Debug
        ConfigLoader
        OpenIDConnect
        Session
        Session::Store::File
        Session::State::Cookie
        Static::Simple
    /
);

# Required by OpenIDConnect role
sub user {
    my ($self) = @_;
    return $self->{session}->{user} if ref $self && ref $self->{session};
    return;
}

=head1 NAME

OIDCExample - Example OpenID Connect Provider

=head1 DESCRIPTION

Simple example Catalyst application demonstrating the OpenIDConnect plugin.

Run with:

    perl example/app.pl

Then visit: http://localhost:3000

=cut

package OIDCExample::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(namespace => '');

=head2 index

Home page

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'index.html';
}

=head2 login

Login page/action. In a real app, this would authenticate users.

=cut

sub login : Local {
    my ( $self, $c ) = @_;

    if ( $c->request->method eq 'POST' ) {
        my $username = $c->request->params->{username};

        # In a real application, validate credentials here
        if ( $username && length($username) > 0 ) {
            # Create a mock user object
            my $user = _create_mock_user($username);
            
            $c->session->{user_id} = $user->{id};
            $c->session->{user} = $user;

            # IMPORTANT: The 'back' parameter is used by the OpenID Connect plugin
            # to resume the authorization flow after successful authentication.
            # Always redirect to it if provided to properly complete the OIDC flow.
            #
            # Security: restrict 'back' to relative paths on this server only.
            # Reject absolute URLs and protocol-relative URLs (e.g. //evil.example.com/)
            # to prevent open-redirect attacks (HIGH-1).
            my $back = $c->request->params->{back} || '/';
            $back = '/' unless $back =~ m{^/[^/]};
            return $c->response->redirect( $c->uri_for($back) );
        }

        $c->stash->{error} = 'Invalid username';
    }

    $c->stash->{template} = 'login.html';
}

=head2 protected

An example protected route that requires OpenID Connect authentication.

=cut

sub protected : Local {
    my ( $self, $c ) = @_;

    unless ( $c->session->{user} ) {
        return $c->response->redirect( $c->uri_for('/login') );
    }

    $c->stash->{user} = $c->session->{user};
    $c->stash->{template} = 'protected.html';
}

=head2 logout

Logout handler

=cut

sub logout : Local {
    my ( $self, $c ) = @_;

    delete $c->session->{user_id};
    delete $c->session->{user};

    $c->response->redirect( $c->uri_for('/') );
}

my $_uuid_gen = Data::UUID->new();

sub _create_mock_user {
    my ($username) = @_;

    return {
        id         => $_uuid_gen->create_str(),
        username   => $username,
        name       => "User $username",
        email      => "$username\@example.com",
        avatar_url => "https://gravatar.com/avatar/$username?d=identicon",
    };
}

=head2 default

404 handler

=cut

sub default : Path {
    my ( $self, $c ) = @_;

    $c->response->status(404);
    $c->stash->{template} = '404.html';
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

# Run the application
package main;
OIDCExample->run;

=head1 AUTHOR

Tim F. Rayner

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
