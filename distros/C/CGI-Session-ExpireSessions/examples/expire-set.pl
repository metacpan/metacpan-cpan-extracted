#!/usr/bin/env perl
#
# Name:
#	expire-set.pl.
#
# Author:
#	Ron Savage
#	http://savage.net.au/index.html
#
# Purpose:
#	Call CGI::Session::ExpireSessions' sub expire_sessions() twice,
#	in order to demonstrate various options available with the module
#	CGI::Session::ExpireSessions.
#
# Note:
#	tab = 4 spaces || die.

use strict;
use warnings;

use CGI::Session;
use CGI::Session::ExpireSessions 1.08;

# -------------

# Create a default (i.e. file-based) type of session, and then sleep so we can be sure
# that the session will be older than the time specified by delta (1 second).
# Also, you can - in the background - create a db-based session, and then
# run this program, and that db-based session will be deleted by the first call to
# sub expire_sessions().

my($s) = CGI::Session -> new();

sleep(2);

# Note:
# Parameters to CGI::Session::ExpireSessions can be given
# when calling new() and/or when calling expire_sessions().

my($expirer) = CGI::Session::ExpireSessions -> new(delta => 1);

# Note:
# o cgi_session_dsn
#	This value is mandatory in order to use db-based sessions, since, by default,
#	CGI::Session used file-based sessions.
# o dsn_args
#	This value (! undef) is mandatory, in order to use database sessions.

$expirer -> expire_sessions
(
	cgi_session_dsn	=> 'driver:mysql;serializer:default;id:MD5',
	dsn_args		=>
	{
		DataSource	=> 'dbi:mysql:mids',
		User		=> 'root',
		Password	=> 'toor',
	}
);

# Note:
# o cgi_session_dsn
#	This value is mandatory to reset the value above back to the default.
#	Note that this default will be supplied by CGI::Session.
# o dsn_args
#	This value (undef) is not really mandatory in order to cancel out the db_dsn above,
#	because the value of cgi_session_dsn is what says this call to expire_sessions()
#	is intended to deal with file-based sessions. Nevertheless, I set it to undef because
#	it would be /very confusing/ to specify database parametes to file-based sessions.
#	So don't do that!
# o verbose
#	This value is optional. The default value is 0.

$expirer -> expire_sessions
(
	cgi_session_dsn	=> undef,
	dsn_args		=> undef,
	verbose			=> 1,
);
