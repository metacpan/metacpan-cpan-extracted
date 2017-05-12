#
# byref.t
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
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
my $exp = 755;
my $got = $wr->count;
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;

# do it by reference
my @list = qw(The Quick Brown Fox Jumped Over The Lazy Dog);
$wr = $wr->new(\@list);

$exp += @list -1;	# two "The's"
$got = $wr->count;
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;

print "Quick not in added word list\nnot "
	unless grep {/quick/} @$wr;
&ok;

print "zabourah not in word list\nnot "
	unless grep {'xxzabourah' =~ /$_/} @$wr;
&ok;
