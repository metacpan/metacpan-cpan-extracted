# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Convert::Ethiopic;
use Convert::Ethiopic::System;
$loaded = 1;

print "ok 1  It loaded.\n";
printf "ok 2  %f\n", Convert::Ethiopic::LibEthVersion;
printf "ok 3  %s\n", Convert::Ethiopic::LibEthVersionName;
printf "ok 4  %s\n", Convert::Ethiopic::ArabToEthiopic ("1991", $unicode, $utf8, 0, "/f");
printf "ok 5  %s\n", Convert::Ethiopic::ConvertEthiopicString ("beqa! y`seral...", $sera, 0, $unicode, $utf8, 0, $amh, "/f", 0, 1);
open (TESTLE, "Hello.sera") || die ("!: Can't Open Hello.sera!\n");
print "ok 6 (text above is ok)\n", Convert::Ethiopic::ConvertEthiopicFile (\*TESTLE, STDOUT, $sera, 0, $unicode, $utf8, 0, $amh, "/f", 0);
close (TESTLE);
open (TESTLE, "Hello.sera") || die ("!: Can't Open Hello.sera!\n");
printf "ok 7  %s\n", Convert::Ethiopic::ConvertEthiopicFileToString (\*TESTLE, $sera, 0, $unicode, $utf8, 0, $amh, "/f", 0);
close (TESTLE);
printf "ok 8  %s\n", Convert::Ethiopic::easctime (localtime, $eng, $amh, 512);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

