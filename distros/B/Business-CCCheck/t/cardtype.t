# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..38\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::CCCheck qw(:all);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
$test = 2;

# Notes:  not a very well thought out test
#

my @et = (
	'',			# null
	'MasterCard',
	'VISA',
	'AmericanExpress',
	'DinersClubInternational',
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
	['5500 2222 3333 4451', 1],			# 6
# visa
	['4000 2222 3333 4434', 2],			# 7
	['4000 2222 3333 6', 2],			# 8
	['4000 2222 3333 4444', 0],	# bad crc	  9
	['4000 2222 3333 4', 0],	# bad crc	  10
	['4000 2222 3333 4434 0', 0],	# too long	  11
	['4000 2222 3333 60', 0],	# too long	  12
# amex
	['3700 2222 3333 447', 3],			# 13
	['3700 2222 3333 440', 3],			# 14
	['3700 2222 3333 444', 0],	# bad crc	  15
	['3700 2222 3333 4470', 0],	# too long	  16
# diners/carteblanche
	['3000 2222 3333 46', 0],			# 17
	['3010 2222 3333 44', 0],			# 18
	['3020 2222 3333 42', 0],			# 19
	['3030 2222 3333 40', 0],			# 20
	['3040 2222 3333 48', 0],			# 21
	['3050 2222 3333 45', 0],			# 22
	['3600 2222 3333 40', 4],			# 23
	['3800 2222 3333 48', 0],			# 24
	['3800 2222 3333 44', 0],	# bad crc	  25
	['3800 2222 3333 490', 0],	# too long	  26
# discover
	['6011 2222 3333 4444', 5],			# 27
	['6011 2222 3333 4445', 0],	# bad crc	  28
	['6011 2222 3333 44440', 0],	# too long	  29
# enRoute
	['2014 2222',	6],		# no crc	  30
	['2014 2223',	6],				# 31
	['2014 2222 3333 4444 5555', 6], # no lenth	# 32
# jcb
	['3500 2222 3333 4443', 7],			# 33
	['3500 2222 3333 4443 0', 0],	# too long	  34
	['3500 2222 3333 464', 7],			# 35
	['3500 2222 3333 424', 7],			# 36
	['3500 2222 3333 4640', 0],	# too long	  37
	['3500 2222 3333 4240', 0],	# too long	  38
);
my $abort = 0;
my $i;
foreach(@tv) {
  my $ccn = CC_clean($_->[0]);
  ($i = CC_typGeneric($ccn)) =~ s/\s+//g;
  if ($_->[1] && $et[$_->[1]] ne $i) {
    print "bad CCN $_->[0], exp: $et[$_->[1]], got: $i\nnot ";
#print $ccn," ''$i'' $_->[1]\n";
  }
  print "ok $test\n";
  ++$test;
#last if ++$abort > 13;
}

