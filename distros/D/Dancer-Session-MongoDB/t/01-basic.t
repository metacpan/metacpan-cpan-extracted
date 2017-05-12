#!perl -T

use strict;
use warnings;
use Test::More;
use Dancer::Config 'setting';
use Dancer::Session::MongoDB;

my $conn;
eval { $conn = MongoDB::Connection->new; };

SKIP: {
	if ($@) {
		diag("MongoDB needs to be running for this test.");
		skip("MongoDB needs to be running for this test.", 4);
	}

	eval { Dancer::Session::MongoDB->create };
	like $@, qr/You must define the name of the MongoDB database for session use in the app's settings/, "setting mongodb_dbname is mandatory";

	setting mongodb_session_db => 'test_dancer_sessions';
	setting mongodb_auto_reconnect => 0;
	my $engine;
	eval { $engine = Dancer::Session::MongoDB->create };
	is $@, '', 'successfully created session object';

	isa_ok $engine, 'Dancer::Session::MongoDB';
	can_ok $engine, qw(create retrieve flush destroy init)
}

done_testing();
