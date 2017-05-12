# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

package Crypt::License::Util::requireLicense4;

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Crypt::License::Util;
use lib qw(.);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

# create pointer and add a list of words


my @list1 = ('one','two','three','four','five');
my $expected = join(',',@list1);

my $rv = modules4privateList(@list1);
print "private return value does not match
got: $rv
exp: $expected\nnot " unless $rv eq $expected;
print "ok $test\n";
++$test;

print "could not find \$ptr2_License\nnot " unless defined $ptr2_License;
print "ok $test\n";
++$test;

print "could not fine private key\nnot " unless exists $ptr2_License->{private};
print "ok $test\n";
++$test;

print "private hash value does not match
got: $ptr2_License->{private};
exp: $expected\nnot " unless $ptr2_License->{private} eq $expected;
print "ok $test\n";
++$test;

### add some values to existing key -- remember there is a SORT here

my @exp = ('six','seven','eight','nine');
my @list2 = ('five',@exp);		# check for dups
$expected = join(',', sort { $b cmp $a } (@list1,@exp));

$rv = modules4privateList(@list2);
print "private return value does not match
got: $rv
exp: $expected\nnot " unless $rv eq $expected;
print "ok $test\n";
++$test;

### test module function


requirePrivateLicense4('TESTmodule4Util');

eval (BZS::TESTmodule4Util::prnt("ok $test\n"));
print "$@\nnot ok $test\n" if $@;
++$test;

print "missing \$ptr2_License\nnot " 
	unless defined $TESTmodule4Util::ptr2_License;
print "ok $test\n";
++$test;

print "\$ptr2_License->{next} not found\nnot "
	unless exists $TESTmodule4Util::ptr2_License->{next};
print "ok $test\n";
++$test;

$expected = 'Crypt::License::Util::requireLicense4';
print "\$ptr2_License->{next} text does not match
got: $ptr2_License->{next}
exp: $expected\nnot " 
	unless $expected eq $TESTmodule4Util::ptr2_License->{next};
print "ok $test\n";
++$test;
