# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

package Crypt::License::Util::requireLicense4;

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Crypt::License::Util;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

my $test_module = 'File::Basename';
requireLicense4 $test_module;
import $test_module;
my @str = ('once/upon/a/', 'time', '.com');
$str = join('',@str);
my($name,$path,$suffix) = fileparse($str, $str[$#str]);

print "string miss-match in module $test_module module test\nnot "
	unless $path eq $str[0] &&
	$name eq $str[1] && $suffix eq $str[2];
print "ok $test\n";
++$test;

print "ptr2_License does not exist\nnot "
	unless defined ${"${test_module}::ptr2_License"};
print "ok $test\n";
++$test;

print 'not ' unless exists ${"${test_module}::ptr2_License"}->{next};
print "ok $test\n";
++$test;

print "did not find $test_module\::\$ptr2_License->{next} text\nnot "
        unless ${"${test_module}::ptr2_License"}->{next}
        eq __PACKAGE__;
print "ok $test\n";
++$test;
