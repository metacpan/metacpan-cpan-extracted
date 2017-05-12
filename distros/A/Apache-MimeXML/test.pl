# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::MimeXML;
$loaded = 1;
print "ok 1\n";

$encoding;

if ($encoding = Apache::MimeXML::check_for_xml("testnone.xml")) {
	print "ok 2\n";
	if ($encoding ne 'utf-8') {
		print "not ";
	}
	print "ok 3\n";
}
else {
	print "not ok 2\nnot ok 3\n";
}

if ($encoding = Apache::MimeXML::check_for_xml("testebcdic.xml")) {
	print "ok 4\n";
	if ($encoding ne 'ebcdic-cp-fi') {
		print "not ";
	}
	print "ok 5\n";
}
else { print "not ok 4\nnot ok 5\n"; }

if ($encoding = Apache::MimeXML::check_for_xml("testutf16be.xml")) {
	print "ok 6\n";
	if ($encoding ne 'utf-16-be') {
		print "not ";
	}
	print "ok 7\n";
}
else { print "not ok 6\nnot ok 7\n"; }

if ($encoding = Apache::MimeXML::check_for_xml("testutf16le.xml")) {
	print "ok 8\n";
	if ($encoding ne 'utf-16-le') {
		print "not ";
	}
	print "ok 9\n";
}
else { print "not ok 8\nnot ok 9\n"; }

if ($encoding = Apache::MimeXML::check_for_xml("testiso.xml")) {
	print "ok 10\n";
	if ($encoding ne 'ISO-8859-1') {
		print "not ";
	}
	print "ok 11\n";
}
else { print "not ok 10\nnot ok 11\n"; }

if (Apache::MimeXML::check_for_xml("Makefile.PL")) {
	print "not ";
}
print "ok 12\n";
	
if ($encoding = Apache::MimeXML::check_for_xml("testzhbig50.xml")) {
	print "ok 13\n";
	if ($encoding ne 'BIG5') {
		print "not ";
	}
	print "ok 14\n";
}
else { print "not ok 13\nnot ok 14\n"; }
	
if ($encoding = Apache::MimeXML::check_for_xml("testzhbig512.xml")) {
	print "ok 15\n";
	if ($encoding ne 'Big5') {
		print "not ";
	}
	print "ok 16\n";
}
else { print "not ok 15\nnot ok 16\n"; }
