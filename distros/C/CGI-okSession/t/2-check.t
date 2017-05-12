# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN {
	use_ok(CGI::okSession);
}
open IN, "< tmp/ID";
my $id = <IN>;
chomp $id;
close IN;
$Session = new CGI::okSession(dir=>'tmp',timeout=>3,id=>$id);
ok($Session,'test 2');
ok($Session->{test}->[4] == 5,'test 3');
ok($Session->{test}->[3] == 4,'test 3');
ok($Session->{test}->[2] == 3,'test 3');
ok($Session->{test}->[1] == 2,'test 3');
ok($Session->{test}->[0] == 1,'test 3');
ok($Session->{hash}->{one} == 1,'test 3');
ok($Session->{hash}->{two} == 2,'test 3');
ok($Session->{hash}->{three} == 3,'test 3');
ok($Session->{scal} eq 'test','test 3');
ok($Session->{client}->{email} eq 'some@email.com','test 3');
ok($Session->{client}->{name} eq 'some@email.com','test 3');
undef $Session;


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

