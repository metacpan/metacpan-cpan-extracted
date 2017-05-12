# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::Reporter::RepFormat;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{
	my $format = new Data::Reporter::RepFormat(10, 10);
	$format->Clear();
	$format->Print("Hola!!");
	$format->MVPrintP(0,1,123.45,"999,999.99");
	($format->Getline(0) eq "Hola!!") ? print "ok 2\n" : print "nok 2\n";
	($format->Getline(1) eq "    123.45") ? print "ok 3\n" : print "nok 3 ",$format->Getline(2), "\n";
	$format->Skip(2);
	$format->Printf("%s","Hola");	
	($format->Getline(3) eq "Hola") ? print "ok 4\n" : print "nok 4\n";
	$format->Commify(12345);
	(Data::Reporter::RepFormat::ToPicture("5147709", "x-xx-xx-xx") 
			eq "5-14-77-09") ? print "ok 5\n" : print "nok 5\n";
	(Data::Reporter::RepFormat::ToPicture("5147709", "xxx") eq "514") ? 
			print "ok 6\n" : print "nok 6\n";
	(Data::Reporter::RepFormat::ToPicture("514", "xxxx") eq "514 ") ? 
			print "ok 7\n" : print "nok 7\n";
	$format->MVPrint(0, 4, "Hola");
	($format->Getline(4) eq "Hola") ? print "ok 8\n" : print "nok 8\n";
	my $format2 = new Data::Reporter::RepFormat(10, 10);
	$format2->Print("Hola!!");
	$format->Copy($format2);
	($format->Nlines() == 6) ? print "ok 9\n" : print "nok 9\n";
	$format->Move(6,7);
	($format->getX() == 6) ? print "ok 10\n" : print "nok 10\n";
	($format->getY() == 7) ? print "ok 11\n" : print "nok 11\n";
}
