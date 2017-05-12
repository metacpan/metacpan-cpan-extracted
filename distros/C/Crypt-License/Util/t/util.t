# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

package Crypt::License::Util::PartA;

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Crypt::License::Util;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

# NOT really needed =>use vars qw($ptr2_License);

my $me = (getpwuid((stat(&{sub {(caller)[1]};}))[4]))[7];
my $expected = $me .'/'.'README.LICENSE';

my $rv = path2License();

print "ptr2_License text does not match
got: $ptr2_License->{path}
exp: $expected\nnot "
	unless $ptr2_License->{path} eq $expected;
print "ok $test\n";
++$test;

my $different = 'License.different';
$expected = $me .'/'.$different;
$rv = path2License($different);

print "ptr2_License text does not match
got: $ptr2_License->{path}
exp: $expected\nnot "
        unless $ptr2_License->{path} eq $expected;
print "ok $test\n";
++$test;

print "return value does not match
got: $rv
exp: $expected\nnot "
        unless $rv eq $expected;
print "ok $test\n";
++$test;

#######################################

&Crypt::License::Util::PartB::call_from_PartB;

sub call_me {	# show the calling package
  my $expected = 'Crypt::License::Util::PartB';
  my $rv = chain2next($ptr2_License);
  print "chain2next text text does not match
got: $ptr2_License->{next}
exp: $expected\nnot "
        unless $ptr2_License->{next} eq $expected;
  print "ok $test\n";
  ++$test;
  print "return value does not match
got: $rv
exp: $expected\nnot "
        unless $ptr2_License->{next} eq $expected;
  print "ok $test\n";
 ++$test;
}

undef $ptr2_License;

&Crypt::License::Util::PartC::call_from_PartC;

sub call_prev {   # show the calling package
  my $expected = 'Crypt::License::Util::PartC';
  my $rv = chain2prevLicense;
  print "chain2prevLicense text text does not match
got: $ptr2_License->{next}
exp: $expected\nnot "
        unless $ptr2_License->{next} eq $expected;
  print "ok $test\n";
  ++$test;
  print "return value does not match
got: $rv
exp: $expected\nnot "
        unless $ptr2_License->{next} eq $expected;
  print "ok $test\n";
 ++$test;
}

package Crypt::License::Util::PartB;

sub call_from_PartB {
  Crypt::License::Util::PartA::call_me;
}

package Crypt::License::Util::PartC;

sub call_from_PartC {
  Crypt::License::Util::PartA::call_prev;
}
