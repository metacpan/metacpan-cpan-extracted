#
# remove.t
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
require Bad::Words;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my $wr = once Bad::Words;

my $count = $wr->count;

# words to remove
my @these = qw(piss whore ass and non swear words);

$wr->remove(@these);

my $got = $wr->count;

# test 2	should have removed three words
my $exp = 3;
print "removed: '", ($count - $got), "', should have removed '$exp' words\nnot "
	unless $count - $got == 3;
&ok;

# test 3	check passes
# there should be one pass for the swear words
# and one for each non-swear word except "words" 
# which sorts to the bottom of the list and thus
# is included in the last "pass" for a total of 4

$exp = 4;
$got = $wr->_passes;
print "did '$got' passes, should have done '$exp'\nnot "
	unless $got == $exp;
&ok;
