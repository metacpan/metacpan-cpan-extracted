#!/usr/bin/perl

use Test::More tests => 5;
use Test::Builder::Tester;

# turn on coloured diagnostic mode if you have a colour terminal.
# This is really useful as it lets you see even things you wouldn't
# normally see like extra spaces on the end of things.
# you can do this from the command line when running tests:
#    perl -MTest::Builder::Tester::Color -Mblib t/01foo.t
use Test::Builder::Tester::Color;

# see if we can load the module okay
BEGIN { use_ok "Acme::Test::Buffy" }

# see if we've exported the function.  No, this doesn't check the
# return value of is_buffy, it checks if the function is defined.  See
# perldoc -f defined.
ok(defined(&is_buffy),"function 'is_buffy' exported");

###
# check that when we give it the right thing we get the right thing
# back
###

# declare what we get if we get the right text
test_out("ok 1 - some text");

# run the test (somewhere between the test_out and the test_test
# meaning that the test output will be captured and not treated as a
# real test)
is_buffy("Buffy","some text");

# say we're done and compare what we got with what we thought we
# should have got
test_test("works when correct");

###
# check that when we give it the right thing we get the right thing
# back, even if we don't specify the name of the test
###

# declare what we get if we get the right text.  Note we start from
# one again as we're numbering from the number of tests we're testing
# with test out.
test_out("ok 1 - is 'Buffy'");

# run the test (somewhere between the test_out and the test_test
# meaning that the test output will be captured and not treated as a
# real test)
is_buffy("Buffy");

# say we're done and compare what we got with what we thought we
# should have got
test_test("works when correct with default text");

###
# check that when we give it the wrong thing we get the right thing
# back, including useful diagnostic test.
###

# the right text we declare is now "not ok" whatever
test_out("not ok 1 - is 'Buffy'");

# we also need to declare that the test will fail and print out the
# normal failing text in the correct manner.  Since this prints out
# the line number, we need to know where that line is.  test_fail
# takes a number that indicates where this line is relative to the
# line test_fail is on.  Note we want to do this before test_diag
# as our tests create failure messages first and then diagnostic
# output to explain why.
test_fail(+9);

# and this has the diagnostic test that the module will print
# out.  Check that it's right.  Note no '\n' at end.
test_diag("Expected 'Buffy' but got 'buffy' instead");

# run the test (somewhere between the test_out and the test_test
# meaning that the test output will be captured and not treated as a
# real test)
is_buffy("buffy");

# say we're done and compare what we got with what we thought we
# should have got
test_test("works when incorrect");


# done.
