#!/usr/bin/env perl

use strict;
use diagnostics;

BEGIN
{
	use CGI::Session;
	use CGI::Session::ExpireSessions;
	use Test::More;

	if (CGI::Session -> can('find') )
	{
		plan tests => 3;
	}
	else
	{
		plan skip_all => "Requires a version of CGI::Session with method 'find()'";
	}
};

# Create a block so $s goes out of scope before we try to access the session.
# Without the {}, CGI::Session::ExpireSessions does not see this session,
# although it will see sessions created by previous runs of this program.

{
	my($s) = new CGI::Session(undef, undef, {Directory => 't'} );

	ok($s, 'The test session has been created');

	$s -> expire(1);

	ok($s -> id, "The test session's id has been set");

	#print "id: ", $s -> id(), ". \n";

	$s -> param(purpose => "Create session simply to test deleting it with CGI::Session's sub find()");

	ok($s -> param('purpose'), "The test session's parameter called 'purpose' has been set");
}

CGI::Session::ExpireSessions -> new(delta => 0, dsn_args => {Directory => 't'}, verbose => 1) -> expire_sessions();
