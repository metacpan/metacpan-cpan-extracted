package Catalyst::Plugin::Authentication::Credential::PAM;

use strict;
use warnings;
use Authen::PAM qw/:constants/;
use Scalar::Util qw/blessed/;

our $VERSION = '0.01';

sub login {
    my ($c, $user, $password) = @_;
    unless ($user && defined $password) {
	$c->log->debug("Can't login a user without a username and a password") if $c->debug;
	return 0;
    }
    unless (blessed($user) && $user->isa("Catalyst::Plugin::Authentication::User")) {
	if (my $user_obj = $c->get_user($user, $password)) {
	    $user = $user_obj;
	}
	else {
	    $c->log->debug("User '$user' doesn't exist in the default store") if $c->debug;
	    return 0;
	}
    }
    if ($c->_check_password($user->id, $password)) {
	$c->set_authenticated($user);
	return 1;
    }
    else {
	return 0;
    }
}

sub _check_password {
    my ($c, $username, $password) = @_;
    my $service = $c->config->{authentication}{pam}{service} || 'login';
    my $handler = sub {
	my @response = ();
	while (@_) {
	    my $code    = shift;
	    my $message = shift;
	    my $answer;
	    if ($code == PAM_PROMPT_ECHO_ON) {
		$answer = $username;
	    }
	    elsif ($code == PAM_PROMPT_ECHO_OFF) {
		$answer = $password;
	    }
	    push(@response, PAM_SUCCESS, $answer);
	}
	return (@response, PAM_SUCCESS);
    };
    my $pam = Authen::PAM->new($service, $username, $handler);
    $pam or do {
	$c->_log_debug($username, $service, Authen::PAM->pam_strerror($pam));
	return 0;
    };
    my $result = $pam->pam_authenticate;
    unless ($result == PAM_SUCCESS) {
	$c->_log_debug($username, $service, $pam->pam_strerror($result));
	return 0;
    }
    $result = $pam->pam_acct_mgmt;
    unless ($result == PAM_SUCCESS) {
	$c->_log_debug($username, $service, $pam->pam_strerror($result));
	return 0;
    }
    $c->log->debug(qq/Successfully authenticated user '$username' using service '$service'./) if $c->debug;
    return 1;
}

sub _log_debug {
    my ($c, $username, $service, $error) = @_;
    $c->log->debug(qq/Failed to authenticate user '$username' using service '$service'. Reason: '$error'/) if $c->debug;
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Authentication::Credential::PAM - Authenticate a user against PAM

=head1 SYNOPSIS

    use Catalyst qw(
	Authentication
	Authentication::Store::Foo
	Authentication::Credential::PAM
    );
    
    package MyApp::Controller::Auth;
    
    # default is 'login'
    __PACKAGE__->config->{authentication}{pam}{service} = 'su';
    
    sub login : Local {
        my ( $self, $c ) = @_;
        $c->login( $c->req->param('username'), $c->req->param('password') );
    }

=head1 DESCRIPTION

This is an authentication credential checker that verifies passwords using a
specified PAM service.

=head1 METHODS

=over 4

=item login($username, $password)

Try to log a user in.

=back

=head1 AUTHOR

Rafael Garcia-Suarez C<< <rgarciasuarez@mandriva.com> >>

=head1 LICENSE

Copyright (c) 2006 Mandriva SA.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut
