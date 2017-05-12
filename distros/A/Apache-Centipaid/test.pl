# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache ();
print "ok Apache\n";
use Apache::File;
print "ok Apache::File\n";
use IO::Socket;
print "ok IO::Socket\n";
use Net::hostent;
print "ok Net::hostent\n";
use DBI;
print "ok DBI\n";
use DBD::mysql;
print "ok DBD::mysql\n";
use CGI::Cookie;
print "ok CGI::Cookie\n";
use Apache::Centipaid;
print "ok Apache::Centipaid\n";
$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


