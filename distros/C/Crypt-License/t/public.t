# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

package CrypttestLicensePublic;

BEGIN { use File::Path;
	my $splitpath = 'blib/lib/auto/BZS/TestModule';
	system './makeLicenseMod.pl 1 TestModule';
	system './makeLicenseMod.pl 1 Nest1';
	system './makeLicenseMod.pl 1 prnt_split';
	mkpath $splitpath, 0 , 0755;
	rename 'prnt_split.pm',"$splitpath/prnt_split.al";

	$| = 1; print "1..5\n";
}
END {print "not ok 1\n" unless $loaded;
}

eval qq{use Crypt::C_LockTite;};
my $skip = $@;

use vars qw( $ptr2_License );
$ptr2_License = {
	'path'		=> do {$_ = `/bin/pwd`; chomp;$_} . '/TestCert.license',
#	'path'		=> 'TestCert.license',
};
use lib qw(.);
require TestModule;
$loaded = 1;
print "ok 1\n";

$test = 2;

eval qq{BZS::TestModule::prnt("ok $test\n")};
print "not ok $test\n$@\n" if $@;
++$test;

eval qq{BZS::TestModule::prnt_split("ok $test\n")};
print "not ok $test\n$@\n" if $@;
++$test;

eval qq{BZS::TestModule::prnt_split("ok $test\n")};
print "not ok $test\n$@\n" if $@;
++$test;

unless ($skip) {
  my @file_text = Crypt::License::get_file('TestCert.license');
  my %parms;
  Crypt::License::extract(\@file_text,\%parms);
  my $expire = Crypt::License::date2time($parms{EXP});
  $_ = $expire - time;
  $_ -= $ptr2_License->{expires};
  $_ = -$_ if $_ < 0;

  print "expiration failed, error $_\nnot " if $_ > 5;	# error must be under 5 seconds
  print "ok $test\n";
} else {
  print "ok skip test on this platform\n";
}
++$test;

