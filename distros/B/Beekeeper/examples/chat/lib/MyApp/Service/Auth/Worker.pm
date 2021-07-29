package MyApp::Service::Auth::Worker;

use strict;
use warnings;

use MyApp::Service::Base;
use base 'MyApp::Service::Base';

use Beekeeper::Worker::Extension::RemoteSession;
use MyApp::Service::Chat;


sub authorize_request {
    my ($self, $req) = @_;

    # Make an exception over the MyApp::Service::Base rule of requiring a logged user
    return BKPR_REQUEST_AUTHORIZED if $req->{method} eq 'myapp.auth.login';

    return $self->SUPER::authorize_request($req);
}

sub on_startup {
    my $self = shift;

    $self->init_persistent_connections;

    $self->accept_remote_calls(
        'myapp.auth.login'  => 'login',
        'myapp.auth.logout' => 'logout',
        'myapp.auth.kick'   => 'kick',
    );

    log_info "Ready";
}

sub on_shutdown {
    my $self = shift;

    log_info "Stopped";
}

sub login {
    my ($self, $params) = @_;

    my $username = $params->{username} || die "No username";
    my $password = $params->{password};

    # For simplicity, this example avoids resolving username <--> uuid  
    # mapping, and username and password are not verified at all
    my $uuid = $username;

    # The authentication data will be present on all subsequent requests
    $self->set_authentication_data( $uuid );

    # Make the authentication data persist and assign an arbitrary address to the user
    $self->bind_remote_session( address => "frontend.user-$uuid" );

    MyApp::Service::Chat->send_notice(
        to_uuid => $uuid,
        message => "Welcome $username",
    );

    return 1;
}

sub logout {
    my ($self, $params) = @_;

    my $uuid = $self->get_authentication_data;

    MyApp::Service::Chat->send_notice(
        to_uuid => $uuid,
        message => "Bye!",
    );

    $self->unbind_remote_session;

    return 1;
}

sub kick {
    my ($self, $params) = @_;

    # For simplicity, this example avoids resolving username <--> uuid 
    my $kick_uuid = $params->{'username'};

    MyApp::Service::Chat->send_notice(
        to_uuid => $kick_uuid,
        message => "Sorry, you were kicked",
    );

    $self->unbind_remote_address( address => "frontend.user-$kick_uuid" );

    return 1;
}

1;
