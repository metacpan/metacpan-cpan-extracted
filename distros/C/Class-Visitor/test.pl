#
# Copyright (C) 1997 Ken MacLeod
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: test.pl,v 1.1.1.1 1997/10/18 16:20:01 ken Exp $
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::Visitor;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

