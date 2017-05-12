# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..66\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::CCCheck qw(:all);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
$test = 2;

# check months are correct
my @months = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
foreach (0..$#months) {
  next if $months[$_] eq $CC_months[$_];
  print 'not ';
  last;
}
print "ok $test\n";
++$test;

# test 3, check local year is returned
print 'not ' unless CC_year eq (split(' ', ($_=localtime)))[4];
print "ok $test\n";
++$test;

# test 4-10, check zipcode formats

print 'not ' unless length(CC_is_zip('1234')) == 5;
print "ok $test\n";
++$test;

print 'not ' unless CC_is_zip('2345') eq '02345';
print "ok $test\n";
++$test;

print 'not ' unless ($_=CC_is_zip('m4u1ab')) && $_ eq 'm4u1ab';		# canadian
print "ok $test\n";
++$test;

print 'not ' unless ($_=CC_is_zip('m4u-1ab')) &&  $_ eq 'm4u-1ab';	# with dash
print "ok $test\n";
++$test;

print 'not ' unless ($_=CC_is_zip('m4u 1ab')) && $_ eq 'm4u 1ab';	# with space
print "ok $test\n";
++$test;

print 'not ' unless ($_=CC_is_zip('m4u.1ab')) && $_ eq 'm4u.1ab';	# with period
print "ok $test\n";
++$test;

print 'not ' if CC_is_zip('m4u#1ab');		# illegal
print "ok $test\n";
++$test;

# test 11-12 check name
print 'not ' unless ($_=CC_is_name('123')) && $_ == 123; # minimum length
print "ok $test\n";
++$test;

print 'not ' if CC_is_name('12');		# too short
print "ok $test\n";
++$test;

# test 13-15 check address

print 'not ' unless ($_=CC_is_name('one two
three')) && $_ eq 'one two
three';					# three words, one endline
print "ok $test\n";
++$test;

print 'not ' unless CC_is_name('one two three'); # no endline
print "ok $test\n";
++$test;

print 'not ' unless CC_is_name('one
two');						# too short
print "ok $test\n";
++$test;

# test 16, clean a credit card number
print 'not ' unless CC_clean('555-12-12 456') eq '5551212456';
print "ok $test\n";
++$test;

# test 17, detect invalid characters in CCN
print 'not ' if CC_clean('555-12-12 D456');
print "ok $test\n";
++$test;

# test 18, format a credit card number
print 'not ' unless CC_format('5551212456') eq '5551 2124 56';
print "ok $test\n";
++$test;

# test 19
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
# mastercard
	['5100-2222 3333 4414', 1],
	['5200 2222 3333 4454', 1],
	['5300 2222 3333 4404', 1],
	['5400 2222 3333 4494', 1],
	['5400 2222 3333 4444', 0],	# bad crc
	['5400 2222 3333 4494 0', 0],	# too long
	['5500 2222 3333 4451', 1],
# visa
	['4000 2222 3333 4434', 2],
	['4000 2222 3333 6', 2],
	['4000 2222 3333 4444', 0],	# bad crc
	['4000 2222 3333 4', 0],	# bad crc
	['4000 2222 3333 4434 0', 0],	# too long
	['4000 2222 3333 60', 0],	# too long
# amex
	['3400 2222 3333 447', 3],
	['3700 2222 3333 440', 3],
	['3400 2222 3333 444', 0],	# bad crc
	['3400 2222 3333 4470', 0],	# too long
# diners/carteblanche
	['3000 2222 3333 46', 4],
	['3010 2222 3333 44', 4],
	['3020 2222 3333 42', 4],
	['3030 2222 3333 40', 4],
	['3040 2222 3333 48', 4],
	['3050 2222 3333 45', 4],
	['3600 2222 3333 40', 4],
	['3800 2222 3333 48', 4],
	['3800 2222 3333 44', 0],	# bad crc
	['3800 2222 3333 490', 0],	# too long
# discover
	['6011 2222 3333 4444', 5],
	['6011 2222 3333 4445', 0],	# bad crc
	['6011 2222 3333 44440', 0],	# too long
# enRoute
	['2014 2222',	6],		# no crc
	['2014 2223',	6],
	['2014 2222 3333 4444 5555', 6], # no lenth
# jcb
	['3100 2222 3333 4443', 7],
	['3100 2222 3333 4443 0', 0],	# too long
	['2131 2222 3333 464', 7],
	['1800 2222 3333 424', 7],
	['2131 2222 3333 4640', 0],	# too long
	['1800 2222 3333 4240', 0],	# too long
);
foreach(@tv) {
  my $ccn = CC_clean($_->[0]);
  print "bad CCN $_->[0], should be $et[$_->[1]], $i\nnot "
	unless $et[$_->[1]] eq ($i=CC_digits($ccn));
  print "ok $test\n";
  ++$test;
}

my(undef,undef,undef,undef,$mon,$yr,undef,undef,undef) = localtime;
$yr += 1900;		# current year
$mon += 1;		# current month
# missing month
print "not " unless &CC_expired('',$yr+1);
print "ok $test\n";
++$test;

# month too small
print "not " unless &CC_expired(0,$yr+1);
print "ok $test\n";
++$test;

# month too big
print "not " unless &CC_expired(13,$yr+1);
print "ok $test\n";
++$test;

# missing year
print "not " unless &CC_expired(1,);
print "ok $test\n";
++$test;

# expired year
print 'missed year expiration ', $yr-1, "\nnot " unless
	&CC_expired($mon,$yr-1);
print "ok $test\n";
++$test;

# expired month -- doesn't work right in january
# but gives correct results
print 'missed month expiration ', $mon-1, "\nnot " unless
	&CC_expired($mon-1,$yr);
print "ok $test\n";
++$test;

# good
print "\nnot " if &CC_expired($mon,$yr);
print "ok $test\n";
++$test;
 
# good + years
print "\nnot " if &CC_expired($mon,$yr+10);
print "ok $test\n";
++$test;

# good + month -- doesn't work right in december
$mon += ( $mon == 12 ) ? 0 : 1;
print "\nnot " if &CC_expired($mon,$yr+10);
print "ok $test\n";
++$test;
