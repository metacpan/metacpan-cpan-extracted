# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 8;
BEGIN { use_ok('CGI::Imagemap') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @map=( 
	 "point  test1 0,0",
	 "oval   test2 50,50 40,30",
	 "circle test3 100,100 100,150",
	 "poly   test4 100,150 150,100 150,150",
	 "point  test5 300,300",
	);

ok(ref(my $im = new CGI::Imagemap), 'Create object');
$im->addmap(@map);
ok($im->action(  5,   5) eq 'test1', 'Point');
ok($im->action( 45,  45) eq 'test2', 'Oval');
ok($im->action( 99,  99) eq 'test3', 'Circle');
ok($im->action(125, 125) eq 'test3', 'Circle overlap');
ok($im->action(149, 149) eq 'test4', 'Poly');
ok($im->action(250, 300) eq 'test5', 'Point');
