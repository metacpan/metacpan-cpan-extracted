#!/usr/bin/perl -w

use Date::Tie;

my $test = 1;
tie my %d, 'Date::Tie';

sub test {
	if ($_[0] ne $_[1]) {
		print "not ok $test # $_[0] : $_[1]\n";
	}
	else {
		print "ok $test\n";
	}
	$test++;
}

print "1..7\n";

$d{year} = 2001;
$d{month} = 8;
$d{day} = 31;

test "$d{year}$d{month}$d{day}", "20010831";
  $d{month} += 2;
test "$d{year}$d{month}$d{day}", "20011031";
  $d{month} += 1;
test "$d{year}$d{month}$d{day}", "20011130";
  $d{year} = 2000;
test "$d{year}$d{month}$d{day}", "20001130";
  $d{month} = 2;
test "$d{year}$d{month}$d{day}", "20000229";
  $d{year}++;
test "$d{year}$d{month}$d{day}", "20010228";

# this tests "next month's last day"
  $d{month}+=2;
  $d{day} = 0;   # this is actually a "-1" since days start in "1"
test "$d{year}$d{month}$d{day}", "20010331";

1;