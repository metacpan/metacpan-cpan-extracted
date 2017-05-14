# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 1 };

use Object::Bouncer;

use IO::Extended qw(:all);

use class::examples::User;

use Data::Dumper;

ok(1); # If we made it this far, we're ok.

	my $tuersteher = new Object::Bouncer( );

	push @{ $tuersteher->tests },

		new Object::Bouncer::Test( field => 'email', type => 'email' ),

		new Object::Bouncer::Test( field => 'registered', type => 'not_null' ),

		new Object::Bouncer::Test( field => 'firstname', type => 'word' ),

		new Object::Bouncer::Test( field => 'lastname', type => 'word' );

	my $user = new User( email => 'hiho@test.de', registered => 1 );

	print Dumper $user;

	if( $tuersteher->inspect( $user ) )
	{
		print "User is ok";
	}
	else
	{
		warn "rejects User because of unsufficient field:", $@;
	}

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

