#
# noregex.t
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

# test 2	remove all words containing the number 5
$wr->noregex(5);
my $got = $wr->count;
my $exp = 10;
print "removed: '", ($count - $got), "', should have removed '$exp' words\nnot "
	unless $count - $got == $exp;
&ok;

# test 3	remove all words containing spaces
$wr->noregex(' ');
$got = $wr->count;
$exp = 10 + 27;
print "removed: '", ($count - $got), "', should have removed '$exp' words\nnot "
	unless $count - $got == $exp;
&ok;

