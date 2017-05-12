#!/usr/bin/perl

package testapp;
use base qw( CGI::Application );

use CGI;
use CGI::Session;
use CGI::Session::Auth::DBI;
use CGI::Carp;

sub setup {
	my $self = shift;
	
	$self->start_mode('free');
	$self->mode_param('cmd');
	$self->run_modes(
    	'free' => 'showFreePage',
    	'secret' => 'showSecretPage',
    	'logout' => 'showLogoutPage',
	);
	
	# new session object
	my $session = new CGI::Session(undef, $self->query, {Directory=>'/tmp'});
	$self->param('_session' => $session);
	
	# new authentication object
	my $auth = new CGI::Session::Auth::DBI({
		CGI => $self->query,
		Session => $self->param('_session'),
		DSN => "dbi:mysql:host=localhost;database=cgiauth",
		DoIPAuth => 1,
	});
	$self->param('_auth' => $auth);
	$auth->authenticate();

	# send session cookie	
	$self->header_props( -cookie => $auth->sessionCookie() );
}

sub _auth {
	my $self = shift;
	
	return $self->param('_auth');
}

sub showFreePage {
	my $self = shift;

	return <<HTML;
<html>
<head><title>Free page</title></head>
<body>
<h1>Free accessible page</h1>
<p><a href="testapp-dbi.pl?cmd=secret">Secret page</a></p>
</body>
</html>
HTML
}

sub showSecretPage {
	my $self = shift;

	if (! $self->_auth->loggedIn) {
		$self->showLoginPage;
	}
	else {
		$self->showSecretData;
	}
}

sub showLoginPage {
	my $self = shift;
	
	return <<HTML;
<html>
<head><title>Not logged in</title></head>
<body>
<h1>You are not logged in</h1>
<p>Please log in to see the secret page:</p>
<form action="testapp-dbi.pl" method="POST">
<input type="hidden" name="cmd" value="secret">
<p><input type="text" size="30" name="log_username" value="username"></p>
<p><input type="text" size="30" name="log_password" value="password"></p>
<p><input type="submit"></p>
</form>
</body>
</html>
HTML
}

sub showSecretData {
	my $self = shift;
	
	my $username = $self->_auth->profile('username');
	
	return <<HTML;
<html>
<head><title>Secret page</title></head>
<body>
<h1>Secret data</h1>
<p><b>Hello $username!</b></p>
<p>There's more than one way to do it!</p>
<p><a href="testapp-dbi.pl?cmd=logout">Log out</a></p>
</body>
</html>
HTML
}

sub showLogoutPage {
	my $self = shift;
	
	$self->_auth->logout();
	
	return <<HTML;
<html>
<head><title>Logged out</title></head>
<body>
<h1>You have logged out.</h1>
<p><a href="testapp-dbi.pl?cmd=secret">Secret page</a></p>
</body>
</html>
HTML
}

1;

package main;

my $app = new testapp;
$app->run();
