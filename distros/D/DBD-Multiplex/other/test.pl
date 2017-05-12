#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..1\n";}
END {print "not ok 1\n" unless $loaded;}
use DBI;
use DBD::Multiplex;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

1;
