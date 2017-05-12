# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More;
my @actions = qw(
	loadfile
	closefile
	newfile
	savefile
	listlayers
	writeLayer
	setLayer
	getCircle
	writeCircle
	getArc
	writeArc
	writeLine
	getText
	writeText
	getPoint
	writePoint
	writeLWPline
	getImage
	getentinit
	getent
	get_extrusion
	entype
	);
plan tests => 2 + @actions;
use CAD::Drawing::IO::DWGI;
ok(1, "use successful"); # If we made it this far, we're ok.
my $dwg = CAD::Drawing::IO::DWGI->new();
ok(defined($dwg), "constructor working");

foreach my $action (@actions) {
	ok($dwg->can($action), $action . " available");
}


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

