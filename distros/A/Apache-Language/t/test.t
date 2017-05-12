#$Id: test.t,v 1.3 1999/03/07 22:46:46 gozer Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n";  }
END {print "not ok 1\n" unless $loaded;}
use Apache::Language;
$loaded = 1;
print "ok 1\n";


my $i=2;
foreach my $handler   ('PlainFile','DBI')
	{
	eval "use Apache::Language::$handler";
	print "not " if($@);
	print "ok ", $i++ , "\n";
	}
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#use Apache::test;

#skip_test unless have_module Apache::FakeRequest;


