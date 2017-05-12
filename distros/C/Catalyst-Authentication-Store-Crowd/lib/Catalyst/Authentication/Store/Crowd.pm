package Catalyst::Authentication::Store::Crowd;

our $VERSION = 0.04;

use warnings;
use Moose;

use LWP::UserAgent;
use HTTP::Request;
use JSON;

use Catalyst::Authentication::Store::Crowd::User;

has 'find_user_url' => (
    is => 'ro',
    isa => 'Str',
    required => '1',
    default => sub {
        'http://localhost';
    }
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
    $init_hash->{find_user_url} = $_[0]->{find_user_url} if defined $_[0]->{find_user_url};
    $init_hash->{app} = $_[0]->{app} if defined $_[0]->{app};
    return $class->$orig( %$init_hash );
};

sub find_user {
    my ($self, $info) = @_;
    my $response = $self->_crowd_get_user( $info->{username} );
    if ( $response->is_success ){
        my $crowd_user_info = from_json( $response->decoded_content );
        return Catalyst::Authentication::Store::Crowd::User->new({
            info => $crowd_user_info
        });
    }
    return;
}

sub from_session {
    my ( $self, $c, $user ) = @_;
    return $user;
}

sub for_session {
    my ( $self, $c, $user ) = @_;
    return $user;
}

sub user_supports {
    my $self = shift;
    Catalyst::Authentication::Store::Crowd::User->supports(@_);
}

sub _crowd_get_user {
    my ( $self, $username ) = @_;
    my $ua = LWP::UserAgent->new;
    my $uri = $self->find_user_url."?username=$username";
    my $req = HTTP::Request->new( 'GET',  $uri );
    $req->authorization_basic(
        $self->app->{app_name},
        $self->app->{password}
    );
    $req->header('Accept' => 'application/json');

    my $response = $ua->request( $req );
    return $response;
}

1;

__END__

=head1 NAME

Catalyst::Authentication::Store::Crowd - Authentication Store with Crowd REST service

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
                    service_url => 'http://yourcrowdservice.url/authentication,
                    app => {
                        app_name => 'your_crowd_app_name',
                        password => 'password_for_app_name',
                    }
                },
                store => {
                    class => 'Crowd',
                    service_url => 'http://yourcrowdservice.url/user,
                    app => {
                        app_name => 'your_crowd_app_name',
                        password => 'password_for_app_name',
                    }
                }
            },
        }
    });

=head1 SEE ALSO

https://github.com/keerati/Catalyst-Authentication-Store-Crowd

=head1 AUTHOR

Keerati Thiwanruk, E<lt>keerati.th@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Keerati Thiwanruk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
