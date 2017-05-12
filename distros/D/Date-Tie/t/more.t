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

print "1..30\n";

$d{year} = 2001;
$d{month} = 10;
$d{day} = 20;
test "$d{year}$d{month}$d{day}", "20011020";

$d{hour} = 10;
$d{minute} = 11;
$d{second} = 12;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20011020T101112";

$d{epoch}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20011020T101113";

$d{week}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20011027T101113";
test "$d{weekyear}W$d{week}$d{weekday}T$d{hour}$d{minute}$d{second}", "2001W436T101113";

$d{weekyear}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20021026T101113";
test "$d{weekyear}W$d{week}$d{weekday}T$d{hour}$d{minute}$d{second}", "2002W436T101113";

$d{year} = 1997;
$d{week} = 1;
$d{weekday} = 1;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "19961230T101113";
test "$d{weekyear}W$d{week}$d{weekday}T$d{hour}$d{minute}$d{second}", "1997W011T101113";
$d{day}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "19961231T101113";
test "$d{weekyear}W$d{week}$d{weekday}T$d{hour}$d{minute}$d{second}", "1997W012T101113";

$d{tzhour} = -3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tzhour}:$d{tzminute}", "19961231T071113 -03:-00";

$d{tzhour} = 0;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tzhour}:$d{tzminute}", "19961231T101113 +00:+00";

$d{tzhour} = 3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tzhour}:$d{tzminute}", "19961231T131113 +03:+00";

$d{tz} = '-0030';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19961231T094113 -0030";

$d{tzminute} += 5;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19961231T094613 -0025";

$d{tz} = '+0000';
$d{hour} = 23;
$d{day} = 31;
$d{tz} = '-0200';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19961231T211113 -0200";

# test month overflow
$d{month}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19970131T211113 -0200";
$d{month}--;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19961231T211113 -0200";

$d{tz} = '+0200';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19970101T011113 +0200";

# can't use 'Z' instead of '0000'
# $d{tz} = 'Z';
# test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19970101T011113 +0000";

# This is NOT expected to work!
# print " d = ", %d, "\n";
# tie my %b, 'Date::Tie', %d;
# test "$b{year}$b{month}$b{day}T$d{hour}$b{minute}$b{second} $b{tz}", "19970101T011113 +0200";

# 'copy'
tie my %c, 'Date::Tie', tz => $d{tz}, epoch => $d{epoch};
test "$c{year}$c{month}$c{day}T$c{hour}$c{minute}$c{second} $c{tz}", "19970101T011113 +0200";

# test direct assignment
tie my %c2, 'Date::Tie';
%c2 = %c;
test "$c2{year}$c2{month}$c2{day}T$c2{hour}$c2{minute}$c2{second} $c2{tz}", "19970101T011113 +0200";

# thanks to Eduardo M. Cavalcanti for this test:
# it fails in Date::Tie 0.07

my $date1 = Date::Tie->new();
my $date2 = Date::Tie->new();
# print "$date1->{year}-$date1->{month}-$date1->{day}\n";
# print "$date2->{year}-$date2->{month}-$date2->{day}\n";
$date1->{day} = 28;
$date1->{month} = 4;
$date2->{month} = 4;
$date2->{day} = 28;
# print "$date1->{year}-$date1->{month}-$date1->{day}\n";
# print "$date2->{year}-$date2->{month}-$date2->{day}\n";
test "$date1->{day}$date1->{month}", "2804";
test "$date2->{day}$date1->{month}", "2804";

my $date3;

$date3 = $date1->new;
$date3->{month}++;
test "$date1->{day}$date1->{month}", "2804";
test "$date3->{day}$date3->{month}", "2805";

( $date3 = $date1->new )->{month}++;
test "$date1->{day}$date1->{month}", "2804";
test "$date3->{day}$date3->{month}", "2805";

$date3 = $date1->new(month => 3);
test "$date1->{day}$date1->{month}", "2804";
test "$date3->{day}$date3->{month}", "2803";

1;
