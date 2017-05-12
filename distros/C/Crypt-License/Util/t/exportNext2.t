# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

package Crypt::License::Util::PartX;

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Crypt::License::Util;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

package Crypt::License::Util::PartY;
$ptr2_License = {'next' => 'found PartY'};


package Crypt::License::Util::PartX;

# exists here, so return 0
print 'not ' if exportNext2('Crypt::License::Util::PartY');
print "ok $test\n";
++$test;

# should print existing contents
print "did not find Part Y\nnot " 
	unless $Crypt::License::Util::PartY::ptr2_License->{next}
	eq 'found PartY';
print "ok $test\n";
++$test;

# does not exist, should export to this name space
print 'not ' unless exportNext2(Crypt::License::Util::PartZ);
print "ok $test\n";
++$test;

print 'not ' unless defined $Crypt::License::Util::PartZ::ptr2_License;
print "ok $test\n";
++$test;

# should have instantiated as calling package name
print 'not ' unless $Crypt::License::Util::PartZ::ptr2_License->{next}
	eq 'Crypt::License::Util::PartX';
print "ok $test\n";
++$test;

my @pkgs = ();
foreach('A'..'G') {
 push(@_,',Crypt::License::Util::Part'.$_);
}
my $size = @_;
print "bad export count
got $_
exp $size\nnot " unless $_ = exportNext2(@_) eq $size;
print "ok $test\n";
++$test;

foreach(@_) {
  print "ptr missing in ${_}\nnot " unless ${"${_}::ptr2_License"}->{next}
	eq 'Crypt::License::Util::PartX';
  print "ok $test\n";
  ++$test;
}
