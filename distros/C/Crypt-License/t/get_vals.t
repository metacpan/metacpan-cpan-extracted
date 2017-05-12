# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use License;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test = 2;

# SERV:  http server name only if server running
# HOST:  local fqdn
# USER:  current user
# GROUP: current group
# HOME:  current working directory

my %ta;
my %pa = (
	'dummy'	=>	'should not appear',
);

&Crypt::License::get_vals(\%pa,\%ta);
$_ = %ta + 0;
print "want 0 found $_ elements in return array\nnot "
	if $_;
print "ok $test\n";
++$test;

# working directory
$pa{HOME} = (split(m|/[^/]*License|,`pwd`))[0];

# current user
$_ = `/usr/bin/id -un`;
chomp;
$pa{USER} = $_;
# current group
$_ = `/usr/bin/id -gn`;
chomp;
$pa{GROUP} = $_;

&Crypt::License::get_vals(\%pa,\%ta);
$_ = (keys %ta);
print "want 3 found $_ elements in return array\nnot "
        unless $_ == 3;;
print "ok $test\n";
++$test;

foreach(sort keys %ta) {
  print "$_ is $ta{$_}, should be $pa{$_}\nnot "
	unless $ta{$_} eq $pa{$_};
  print "ok $test\n";
  ++$test;
}

$pa{SERV} = 'test val';
&Crypt::License::get_vals(\%pa,\%ta);
print "SERV not equal $pa{SERV}\nnot "
	unless $ta{SERV} eq $pa{SERV};
print "ok $test\n";
++$test;

$ENV{SERVER_NAME} = 'Hokey, Pokey';
&Crypt::License::get_vals(\%pa,\%ta);
print "SERV is $ta{SERV}, should be \L$ENV{SERVER_NAME}\nnot "
        unless $ta{SERV} eq "\L$ENV{SERVER_NAME}";
print "ok $test\n";
++$test;
