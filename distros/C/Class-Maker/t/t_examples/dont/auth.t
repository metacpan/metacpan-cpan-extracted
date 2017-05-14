# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Object::Auth;
$loaded = 1;
print "ok 1\n";

#use Object::Debugable;

use Object::Auth;

::class 'Admin',
{
	isa => [qw( Object::Auth )],

	public =>
	{
		string => [ qw/workspace_logged/ ],
	},
};

sub Admin::_preinit
{
	my $this = shift;

		$this->workspace_logged(10);
}

	my $auth = new Admin( userid => 'test', passwd => 'testpw' );

	if( $auth->login( 'testpw' ) )
	{
		printf "Login successfull for '%s'\n", $auth->userid;

		$auth->debugDump();

		$auth->logout();
	}

	print "after the login...";

	$auth->debugDump();

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

