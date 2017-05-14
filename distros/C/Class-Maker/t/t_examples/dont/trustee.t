# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Object::Trustee;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

	use class::examples::User;

	use Object::Bouncer;

	use Data::Dumper;

	open( CONFIG, '+<usermanager.ini' ) or warn $@;

	print "Loading: ", my $identifier = <CONFIG>, "\n";

	my $usermanager = new Object::Trustee(

		tiewith => 'Apache::Session::File',

		id => $identifier,

		args => { Directory => 'c:/temp/sessiondata', LockDirectory   => 'c:/temp/sessiondata/locks' }

	);

	print 'Session-ID: ', $usermanager->id, "\n\n";

	print CONFIG $usermanager->id, "HALLO";

	close( CONFIG );

	my %gruppe = (

		toni => new User( firstname => 'toni', email => 'toni@wrong' ),

		eva => new User( firstname => 'eva', email => 'eva@any.de' ),

		maren => new User( firstname => 'maren' ),
	);

	print "\n", 'Users:';

	print Dumper \%gruppe;

	$usermanager->store( %gruppe );

		# bouncer let filled email fields in....

	my $emailtester = new Object::Bouncer( );

	push @{ $emailtester->tests }, new Object::Bouncer::Test( field => 'email', type => 'true' );

	my $list = $usermanager->retrieve( $emailtester );

		# now, bouncer only leaves <valid> emails in...

	print "\n\nUsers with email field filled:";

	my $emailchecker = new Object::Bouncer( );

	push @{ $emailchecker->tests }, new Object::Bouncer::Test( field => 'email', type => 'email' );

	print Dumper $list;

	my $list = $usermanager->retrieve( $emailchecker );

	print "\n\nUsers with valid email:";

	print Dumper $list;
