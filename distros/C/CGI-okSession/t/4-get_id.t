# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN {
	use_ok(CGI::okSession);
}
open IN, "< tmp/ID";
my $id = <IN>;
chomp $id;
close IN;
sleep 1;
$Session = new CGI::okSession(dir=>'tmp',timeout=>5,id=>$id);
ok($Session, 'Session test');
ok($Session->get_ID eq $id, 'get_ID test');
undef $Session;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
