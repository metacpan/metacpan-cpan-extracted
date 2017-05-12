# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..80\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::CCCheck qw(:all);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
$test = 2;

my @et = (
	'',			# null
	'MasterCard',
	'VISA',
	'AmericanExpress',
	'DinersClub/Carteblanche',
	'Discover',
	'enRoute',
	'JCB',
);

# format -- card number, expected value from @et
my @tv = (
# mastercard						# test 'n' or test '4n'
	['5100-2222 3333 4414', 1],			# 2
	['5200 2222 3333 4454', 1],			# 3
	['5300 2222 3333 4404', 1],			# 4
	['5400 2222 3333 4494', 1],			# 5
	['5400 2222 3333 4444', 0],	# bad crc	  6
	['5400 2222 3333 4494 0', 0],	# too long	  7
	['5500 2222 3333 4451', 1],			# 8
# visa
	['4000 2222 3333 4434', 2],			# 9
	['4000 2222 3333 6', 2],			# 10
	['4000 2222 3333 4444', 0],	# bad crc	  11
	['4000 2222 3333 4', 0],	# bad crc	  12
	['4000 2222 3333 4434 0', 0],	# too long	  13
	['4000 2222 3333 60', 0],	# too long	  14
# amex
	['3400 2222 3333 447', 3],			# 15
	['3700 2222 3333 440', 3],			# 16
	['3400 2222 3333 444', 0],	# bad crc	  17
	['3400 2222 3333 4470', 0],	# too long	  18
# diners/carteblanche
	['3000 2222 3333 46', 4],			# 19
	['3010 2222 3333 44', 4],			# 20
	['3020 2222 3333 42', 4],			# 21
	['3030 2222 3333 40', 4],			# 22
	['3040 2222 3333 48', 4],			# 23
	['3050 2222 3333 45', 4],			# 24
	['3600 2222 3333 40', 4],			# 25
	['3800 2222 3333 48', 4],			# 26
	['3800 2222 3333 44', 0],	# bad crc	  27
	['3800 2222 3333 490', 0],	# too long	  28
# discover
	['6011 2222 3333 4444', 5],			# 29
	['6011 2222 3333 4445', 0],	# bad crc	  30
	['6011 2222 3333 44440', 0],	# too long	  31
# enRoute
	['2014 2222',	6],		# no crc	  32
	['2014 2223',	6],				# 33
	['2014 2222 3333 4444 5555', 6], # no lenth	# 34
# jcb
	['3100 2222 3333 4443', 7],			# 35
	['3100 2222 3333 4443 0', 0],	# too long	  36
	['2131 2222 3333 464', 7],			# 37
	['1800 2222 3333 424', 7],			# 38
	['2131 2222 3333 4640', 0],	# too long	  39
	['1800 2222 3333 4240', 0],	# too long	  40
);
foreach(@tv) {
  my $ccn = CC_clean($_->[0]);
  print "bad CCN $_->[0], should be $et[$_->[1]], $i\nnot "
	unless $et[$_->[1]] eq ($i=CC_oldtype($ccn)) or ! $_->[1];

  print "ok $test\n";
  ++$test;
}

print "ok $test\n";	# dummy to align next test with 42 for easy of development
++$test;

foreach(@tv) {
  my $ccn = CC_clean($_->[0]);
  $i = CC_parity($ccn);
  unless ( ($_->[1] && $i) or !($_->[1] || $i) ) {
    print "bad parity '$i', expected: $_->[1]\n";
  }
  print "ok $test\n";
  ++$test;
}

