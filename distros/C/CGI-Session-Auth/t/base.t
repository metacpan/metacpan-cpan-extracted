#!perl -T

use Test::More tests => 14;

use CGI;                                                                                                   
use CGI::Session;                                                                                                   


BEGIN { 
	use_ok('CGI::Session::Auth');
}

require_ok('CGI::Session::Auth');

my $cgi = new CGI;
my $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp'});

sub _auth {
	return new CGI::Session::Auth({
		CGI => $cgi,
		Session => $session,
	});
}

# basic tests
{
	my $auth = _auth;
	isa_ok($auth, 'CGI::Session::Auth');
	can_ok($auth, 'new');
	can_ok($auth, 'authenticate');
	can_ok($auth, 'loggedIn');
	can_ok($auth, 'profile');
	can_ok($auth, 'logout');
	is($auth->_loggedIn(), 0, 'internal login status unset');
}

# login/logout
{
	my $auth = _auth;
	can_ok($auth, '_loggedIn');
	$auth->_loggedIn(0);
	is($auth->loggedIn(), 0, 'public login status unset');
	is($auth->_loggedIn(), 0, 'internal login status unset');
	$auth->_loggedIn(1);
	is($auth->loggedIn(), 1, 'public login status unset');
	is($auth->_loggedIn(), 1, 'internal login status unset');
}
