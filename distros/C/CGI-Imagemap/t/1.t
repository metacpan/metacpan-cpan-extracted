# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('CGI::Imagemap') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @map=( 
	 "rect test1 148,0 223,20",
	 "rect test2 231,0 289,20",
	 "rect test4 354,0 422,20",
	 "default default"
	);
my($x, $y) = (323, 8);

ok(ref(my $im = new CGI::Imagemap), 'Create object');
$im->addmap(@map);
ok($im->action($x, $y) eq 'default', 'Default action');
$im->addmap("rect test3 296,0 346,20");
ok($im->action($x, $y) eq 'test3', 'Rectangle 3');
