package Catalyst::Authentication::Credential::Crowd;

use strict;
use warnings;

our $VERSION = '0.07';

use Moose;
use HTTP::Request;
use LWP::UserAgent;
use JSON;

has 'authen_url' => (
    is => 'ro',
    isa => 'Str',
    required => '1',
    default => sub { 'http://localhost'; }
);

has 'app' => (
    is => 'ro',
    isa => 'HashRef',
    required => '1',
    default => sub { {} }
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $init_hash = {};
    $init_hash->{authen_url} = $_[0]->{authen_url} if defined $_[0]->{authen_url};
    $init_hash->{app} = $_[0]->{app} if defined $_[0]->{app};
    return $class->$orig( %$init_hash );
};

sub authenticate {
    my ($self, $c, $realm, $authinfo) = @_;
    my $response = $self->_crowd_authen( $authinfo->{username}, $authinfo->{password} );
    if ( $response->is_success ){
        my $user = $realm->find_user( { username => $authinfo->{username} }, $c );
        if ( $user ) {
            return $user;
        } else {
            $c->stash( auth_error_msg => 'Authenticated user, but could not locate in store!' );
            return;
        }
    } elsif ($response->code == 403  && $response->decoded_content =~ m|<h1>HTTP Status 403 - (.*?)</h1>|i) {
        # indicates a tomcat problem, should probably do something else here?
        $c->log->warn("Problem comunicating with crowd server: " . $response->code );
        $c->stash( auth_error_msg => 'tomcat problem: ' . $1 );
    } else {
        $c->stash( auth_error_msg => $response->decoded_content );
    }
    return;

}

sub _crowd_authen {
    my ( $self, $username, $password ) = @_;
    my $ua = LWP::UserAgent->new;
    my $uri = $self->authen_url."?username=$username";
    my $json_hash = { value => $password };
    my $json = to_json( $json_hash );
    my $req = HTTP::Request->new( 'POST',  $uri );
    $req->authorization_basic(
        $self->app->{app_name},
        $self->app->{password}
    );
    $req->header('Accept' => 'application/json');
    $req->header('Content-Type' => 'application/json');
    $req->content( $json );

    my $response = $ua->request( $req );
    return $response;
}


1;

__END__

=head1 NAME

Catalyst::Authentication::Credential::Crowd - Authenticate a user using Crowd REST Service

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication

    /;

    __PACKAGE__->config( authentication => {
        default_realm => 'crowd',
        realms => {
            crowd => {
                credential => {
                    class => 'Crowd',
                    authen_url => 'http://yourcrowdservice.url/authentication,
                    app => {
                        app_name => 'your_crowd_app_name',
                        password => 'password_for_app_name',
                    }
                },
                ...
            },
        }
    });

    # in controller

    sub login : Local {
        my ( $self, $c ) = @_;

        $c->authenticate( {
            username => $c->req->param('username'),
            password => $c->req->param('password')
        }

        # ... do something else ...
    }

=head1 METHODS

=head2 authenticate

Authenticate a user.

=head1 PRIVATE METHODS

=head2 _crowd_authen

Make a HTTP request to Crowd REST Service to authenticate a user.

=head1 SEE ALSO

https://github.com/keerati/Catalyst-Authentication-Credential-Crowd

=head1 AUTHOR

Keerati Thiwanruk, E<lt>keerati.th@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Keerati Thiwanruk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
