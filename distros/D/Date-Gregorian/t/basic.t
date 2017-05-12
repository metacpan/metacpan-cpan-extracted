# Copyright (c) 1999-2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl basic.t'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..261\n"; }
END {print "not ok 1\n" unless $loaded;}
use Date::Gregorian;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use strict;

sub test {
    my ($n, $bool) = @_;
    print $bool? (): 'not ', 'ok ', $n, "\n";
}

sub test_ymd {
    my ($n, $date, @ymd) = @_;
    my $date2 = ref($date) && $date->new->check_ymd(@ymd);
    test $n, $date2 && 0 == $date2->get_days_since($date);
}

sub test_ymdg {
    my ($n, $date, $y, $m, $d, $g) = @_;
    my $date2 = ref($date) && $date->new;
    my @ymd = $date2? $date2->get_ymd: ();
    test $n,
	$date2 &&
	$y == $ymd[0] &&
	$m == $ymd[1] &&
	$d == $ymd[2] &&
	!$g == !$date->is_gregorian;
}


my $date = Date::Gregorian->new;
test 2, 'Date::Gregorian' eq ref($date);

my $date2 = $date->new;
test 3, 'Date::Gregorian' eq ref($date2);
test 4, $date2 != $date;

$date = $date2->set_easter(1701);
test 5, 'Date::Gregorian' eq ref($date2);
test 6, $date2 == $date;
test_ymd 7, $date, 1701, 3, 27;

my $kate = $date->new->configure(1752, 9, 14);
test_ymd 8, $kate, 1701, 3, 16;
test 9, 0 == $kate->get_days_since($date);

my $bate = $date->new->configure(1752, 9, 14, 1753);
test_ymd 10, $bate, 1701, 3, 16;
test 11, 0 == $bate->get_days_since($date);

my $bate2 = $bate->new;
test 12, 'Date::Gregorian' eq ref($bate2);
test 13, $bate2 != $bate;

$date2 = $bate2->configure(1582, 10, 14);
test_ymd 14, $date2, 1701, 3, 27;
test 15, 0 == $date2->get_days_since($date);

$date2 = $bate2->configure(1582, 10, 14, 1583);
test_ymd 16, $date2, 1701, 3, 27;
test 17, 0 == $date2->get_days_since($date);

$kate->set_easter(1701);
test_ymd 18, $kate, 1701, 3, 16;
test 19, 0 == $date->get_days_since($kate);

$bate->set_easter(1701);
test_ymd 20, $bate, 1701, 4, 20;
test 21, 35 == $bate->get_days_since($date);

my $ref = $date->new->set_ymd(1600, 3, 1);
test 22, 36915 == $date->get_days_since($ref);

$date = Date::Gregorian->new;
$date2 = $date->check_ymd(1500, 2, 29);
test 23, $date2;
test 24, $date2 == $date;

test 25, ! $date->check_ymd(1700, 2, 29);
test 26, $date2 == $date;
test_ymd 27, $date, 1500, 2, 29;

test 28, $date->check_ymd(1582, 10, 4);
test 29, ! $date->check_ymd(1582, 10, 5);
test 30, ! $date->check_ymd(1582, 10, 14);
test 31, $date->check_ymd(1582, 10, 15);
test 32, $date->check_ymd(1600, 2, 29);
test 33, ! $date->check_ymd(1600, 2, 30);

test 34, $bate->check_ymd(1500, 2, 29);
test 35, $bate->check_ymd(1700, 2, 29);
test 36, $bate->check_ymd(1582, 10, 4);
test 37, $bate->check_ymd(1582, 10, 5);
test 38, $bate->check_ymd(1582, 10, 14);
test 39, $bate->check_ymd(1582, 10, 15);
test 40, $bate->check_ymd(1600, 2, 29);
test 41, ! $bate->check_ymd(1600, 2, 30);

test 42, $bate->check_ymd(1752, 9, 2);
test 43, ! $bate->check_ymd(1752, 9, 3);
test 44, ! $bate->check_ymd(1752, 9, 13);
test 45, $bate->check_ymd(1752, 9, 14);
test 46, $bate->check_ymd(1800, 2, 28);
test 47, ! $bate->check_ymd(1800, 2, 29);
test 48, ! $bate->check_ymd(1999, 2, 29);
test 49, $bate->check_ymd(1999, 3, 1);
test 50, $bate->check_ymd(2000, 2, 29);
test 51, ! $bate->check_ymd(2000, 2, 30);

$date2 = $date->set_ymd(1581, 12, 31);
test 52, $date2 == $date;
test_ymd 53, $date, 1581, 12, 31;

my ($y, $m, $d) = $date->get_ymd;
test 54, 1581 == $y && 12 == $m && 31 == $d;

$date2 = $date->new->set_ymd(1582, 12, 31);
test 55, 355 == $date2->get_days_since($date);

($y, $m, $d) = $date2->get_ymd;
test 56, 1582 == $y && 12 == $m && 31 == $d;

$date2->set_ymd(1582, 10, 15);
test 57, 278 == $date2->get_days_since($date);

$date2->set_ymd(1582, 10, 4);
test 58, 277 == $date2->get_days_since($date);

$date->add_days(277);
($y, $m, $d) = $date->get_ymd;
test 59, 1582 == $y && 10 == $m && 4 == $d;

$date2 = $date->add_days(1);
test 60, $date2 == $date;
test_ymd 61, $date, 1582, 10, 15;

$date->add_days(-1);
test_ymd 62, $date, 1582, 10, 4;

test 63, 3 == $date->set_ymd(1999, 11, 18)->get_weekday;

($y, $d) = $date->get_yd;
test 64, 1999 == $y && 322 == $d;

my $w;
($y, $w, $d) = $date->get_ywd;
test 65, 1999 == $y && 46 == $w && 3 == $d;

($y, $w, $d) = $date->set_ymd(1999, 1, 1)->get_ywd;
test 66, 1998 == $y && 53 == $w && 4 == $d;

($y, $w, $d) = $date->set_ymd(1999, 1, 3)->get_ywd;
test 67, 1998 == $y && 53 == $w && 6 == $d;

($y, $w, $d) = $date->set_ymd(1999, 1, 4)->get_ywd;
test 68, 1999 == $y && 1 == $w && 0 == $d;

($y, $m, $d) = $date->set_yd(1999, 322)->get_ymd;
test 69, 1999 == $y && 11 == $m && 18 == $d;

($y, $m, $d) = $date->new->set_ywd(1999, 46, 3)->get_ymd;
test 70, 1999 == $y && 11 == $m && 18 == $d;

my $offset = $date->set_ymd(1970, 1, 1)->get_gmtime();
test 71, defined($offset);

$date2 = $date->new->set_gmtime(942950958 + $offset);
test_ymd 72, $date2, 1999, 11, 18;

my $t = $date->set_ymd(1999, 11, 18)->get_gmtime;
test 73, 942883200 + $offset == $t;

$date2 = $date->new->configure(9999, 12, 31)->set_ymd(1600, 1, 1);
test 74, 'Date::Gregorian' eq ref($date2->set_date($date));
test_ymd 75, $date2, 1999, 11, 5;
test 76, 0 == $date2->get_days_since($date);

test 77, $date->check_ymd(-1469870, 3, 1);

$date = Date::Gregorian->new->set_easter(1701);
$date2 = $date->new->set_easter(5701701);
test_ymd 78, $date2, 5701701, 3, 27;
test 79, 2081882250 == $date2->get_days_since($date);

$date->set_easter(532);
test_ymd 80, $date, 532, 4, 11;
$date2 = $date->new->set_easter(0);
test_ymd 81, $date2, 0, 4, 11;
test 82, 194313 == $date->get_days_since($date2);

$date = $date2->new->set_easter(-53200);
test_ymd 83, $date, -53200, 4, 11;
test 84, -19431300 == $date->get_days_since($date2);

$date->set_ymd(-53200, 4, 11);
test_ymd 85, $date, -53200, 4, 11;
test 86, -19431300 == $date->get_days_since($date2);

test_ymd 87, $date->set_ymd(-4712, 1, 1)->add_days(2451545), 2000, 1, 1;

$date->set_ymd(1999, 11, 15)->set_weekday(0);
test_ymd(88, $date, 1999, 11, 15);

$date->set_ymd(1999, 11, 15)->set_weekday(0, '>=');
test_ymd(89, $date, 1999, 11, 15);

$date->set_ymd(1999, 11, 15)->set_weekday(0, '>');
test_ymd(90, $date, 1999, 11, 22);

$date->set_ymd(1999, 11, 15)->set_weekday(0, '<');
test_ymd(91, $date, 1999, 11, 8);

$date->set_ymd(1999, 11, 15)->set_weekday(0, '<=');
test_ymd(92, $date, 1999, 11, 15);

$date->set_ymd(1999, 11, 16)->set_weekday(6);
test_ymd(93, $date, 1999, 11, 21);

$date->set_ymd(1999, 11, 16)->set_weekday(6, '>=');
test_ymd(94, $date, 1999, 11, 21);

$date->set_ymd(1999, 11, 16)->set_weekday(6, '>');
test_ymd(95, $date, 1999, 11, 21);

$date->set_ymd(1999, 11, 16)->set_weekday(6, '<');
test_ymd(96, $date, 1999, 11, 14);

$date->set_ymd(1999, 11, 16)->set_weekday(6, '<=');
test_ymd(97, $date, 1999, 11, 14);

$date->set_ymd(1999, 11, 14)->set_weekday(1, '>=');
test_ymd(98, $date, 1999, 11, 16);

$date->set_ymd(1999, 11, 14)->set_weekday(1, '>');
test_ymd(99, $date, 1999, 11, 16);

$date->set_ymd(1999, 11, 21)->set_weekday(1, '<');
test_ymd(100, $date, 1999, 11, 16);

$date->set_ymd(1999, 11, 21)->set_weekday(1, '<=');
test_ymd(101, $date, 1999, 11, 16);


$date = Date::Gregorian->new;
test 102, $date->set_ymd(2000, 2, 29)->is_gregorian;
test 103, $date->set_ymd(1582, 10, 15)->is_gregorian;
test 104, ! $date->set_ymd(1582, 10, 4)->is_gregorian;
test 105, ! $date->set_ymd(-4712, 1, 1)->is_gregorian;
$date->set_ymd(1582, 10, 15)->configure(10000, 1, 1);
test 106, ! $date->is_gregorian;


my $time1 = time;
$date = Date::Gregorian->new->set_today;
my $time2 = time;
$date2 = $date->new->set_ymd(1999, 12, 31);
my $delta1 = $date2->set_localtime($time1)->get_days_since($date);
my $delta2 = $date2->set_localtime($time2)->get_days_since($date);
test 107, $date->isa('Date::Gregorian');
test 108, 0 == $delta1 || 0 == $delta2;

$date->set_ymd(12002, 6, 5);
$time2 = $date->get_gmtime;
test 109, !defined($time2) || 316592755200 == $time2 - $offset;

test 110, 366 == $date->get_days_in_year(2000);
test 111, 365 == $date->get_days_in_year(1999);
test 112, 365 == $date->get_days_in_year(1998);
test 113, 365 == $date->get_days_in_year(1997);
test 114, 366 == $date->get_days_in_year(1996);
test 115, 365 == $date->get_days_in_year(1900);
test 116, 365 == $date->get_days_in_year(1800);
test 117, 365 == $date->get_days_in_year(1700);
test 118, 366 == $date->get_days_in_year(1600);
test 119, 355 == $date->get_days_in_year(1582);
test 120, 366 == $date->get_days_in_year(1500);

$date->configure(2100, 1, 5);
test 121, 356 == $date->get_days_in_year(2099);
test 122, 361 == $date->get_days_in_year(2100);

$date->set_yd(2100, 1);
test_ymd(123, $date, 2100, 1, 5);

# A reformation date before March 1, 200, creates ambiguities.
# Here we check whether these are handled gracefully.
$date->configure(-5000, 1, 1);
test 124, 405 == $date->get_days_in_year(-5000);
my $result = $date->check_ymd(-5001, 12, 31);
test 125, $result;
$date->set_ymd(-5001, 12, 31)->add_days(40);
test_ymdg(126, $date, -5000, 2, 9, 0);
$date->add_days(1);
test_ymdg(127, $date, -5000, 1, 1, 1);

# A reformation date after Dec 31, 48901, can create empty years.
$date->configure(48902, 1, 1);
test 128, 0 == $date->get_days_in_year(48901);
$date->set_ymd(48900, 12, 31);
test_ymdg(129, $date, 48900, 12, 31, 0);
$date->add_days(1);
test_ymdg(130, $date, 48902, 1, 1, 1);

# --- checks for iterators ---

$date = Date::Gregorian->new->set_ymd(2005, 12, 31);
$date2 = $date->new->add_days(3);
my $iter = $date->iterate_days_upto($date2, '<');
test 131, defined($iter) && 'CODE' eq ref($iter);

$date->add_days(20);
$date2->add_days(2);
my $iter2 = $date->iterate_days_downto($date2, '>=', 5);
test 132, defined($iter2) && 'CODE' eq ref($iter);

test 133, $iter->();
test_ymd(134, $date, 2005, 12, 31);
test 135, $iter2->();
test_ymd(136, $date, 2006, 1, 20);
test 137, $iter2->();
test_ymd(138, $date, 2006, 1, 15);
test 139, $iter->() && $iter->();
test_ymd(140, $date, 2006, 1, 2);
test 141, $iter2->();
test_ymd(142, $date, 2006, 1, 10);
test 143, !$iter->();
test_ymd(144, $date, 2006, 1, 10);
test 145, $iter2->();
test_ymd(146, $date, 2006, 1, 5);
test 147, !$iter2->();
test_ymd(148, $date, 2006, 1, 5);

$date->set_ymd(2006, 1, 20);
$iter = $date->iterate_days_downto($date2, '>', 5);
test 149, $iter->();
test 150, $iter->();
test 151, $iter->();
test 152, !$iter->();
test_ymd(153, $date, 2006, 1, 10);

$date->set_ymd(2006, 1, 10);
$iter = $date->iterate_days_downto($date2, '>');
$iter2 = $date2->iterate_days_upto($date, '<');
test 154, $iter->();
test 155, $iter2->();
test_ymd(156, $date, 2006, 1, 10);
test_ymd(157, $date2, 2006, 1, 5);
test 158, $iter->() && $iter->() && $iter->() && $iter->();
test 159, $iter2->() && $iter2->() && $iter2->() && $iter2->();
test_ymd(160, $date, 2006, 1, 6);
test_ymd(161, $date2, 2006, 1, 9);
test 162, !$iter->();
test 163, !$iter2->();

$date->set_ymd(2006, 1, 10);
$date2->set_date($date);
$iter = $date->iterate_days_downto($date2, '>=');
$iter2 = $date2->iterate_days_upto($date, '<=');
test 164, $iter->();
test 165, $iter2->();
test 166, !$iter->();
test 167, !$iter2->();
test_ymd(168, $date, 2006, 1, 10);
test_ymd(169, $date2, 2006, 1, 10);

$date->set_ymd(2006, 1, 10);
$date2->set_date($date);
$iter = $date->iterate_days_downto($date2, '>');
$iter2 = $date2->iterate_days_upto($date, '<');
test 170, !$iter->();
test 171, !$iter2->();

$date->set_ymd(2006, 1, 9);
$date2->set_ymd(2006, 1, 11);
$iter = $date->iterate_days_downto($date2, '>=');
$iter2 = $date2->iterate_days_upto($date, '<=');
test 172, !$iter->();
test 173, !$iter2->();

$date->set_ymd(2006, 1, 6);
$date2->set_ymd(2006, 1, 20);
$iter = $date->iterate_days_upto($date2, '<', 7);
$date->add_days(3);
$iter2 = $date->iterate_days_upto($date2, '<', 7);
test 174, $iter->();
test_ymd(175, $date, 2006, 1, 6);
test 176, $iter->();
test_ymd(177, $date, 2006, 1, 13);
test 178, !$iter->();
test 179, $iter2->();
test_ymd(180, $date, 2006, 1, 9);
test 181, $iter2->();
test_ymd(182, $date, 2006, 1, 16);
test 183, !$iter2->();

$date->set_ymd(2006, 1, 6);
$date2->set_ymd(2006, 1, 20);
$iter = $date->iterate_days_upto($date2, '<=', 7);
$date->add_days(1);
$iter2 = $date->iterate_days_upto($date2, '<=', 7);
test 184, $iter->();
test_ymd(185, $date, 2006, 1, 6);
test 186, $iter->() && $iter->();
test_ymd(187, $date, 2006, 1, 20);
test 188, !$iter->();
test 189, $iter2->();
test_ymd(190, $date, 2006, 1, 7);
test 191, $iter2->();
test_ymd(192, $date, 2006, 1, 14);
test 193, !$iter2->();

$date->set_ymd(2004, 5, 1)->set_weekday(0, '<=');
$date2->set_ymd(2004, 6, 1);
$iter = $date->iterate_days_upto($date2, '<', 7);
$result = '';
my $loopcheck = 6;
my $loopcheck2 = -1;
while ($iter->()) {
    last if !$loopcheck--;
    my $w = ($date->get_ywd)[1];
    $result .= sprintf "(%2d)", $w;
    $date2->set_date($date)->add_days(7);
    $iter2 = $date->iterate_days_upto($date2, '<');
    $loopcheck2 = 7;
    while ($iter2->()) {
	last if !$loopcheck2--;
	my ($y, $m, $d) = $date->get_ymd;
	$result .= 5 == $m? sprintf(" %02d", $d): '   ';
    }
    last if $loopcheck2;
    $result .= "\n";
}
test 194, !$loopcheck && !$loopcheck2;
test 195, $result eq
    "(18)                01 02\n" .
    "(19) 03 04 05 06 07 08 09\n" .
    "(20) 10 11 12 13 14 15 16\n" .
    "(21) 17 18 19 20 21 22 23\n" .
    "(22) 24 25 26 27 28 29 30\n" .
    "(23) 31                  \n";

# --- some more general tests ---

$date = Date::Gregorian->new->set_ymd(1998, 26, 29);
test_ymd(196, $date, 2000, 2, 29);
$date->set_ymd(2100, 3, 0);
test_ymd(197, $date, 2100, 2, 28);
$date->set_ymd(1502, -22, 29);
test_ymd(198, $date, 1500, 2, 29);

$date = $date->new->set_ymd(2006, 11, 11);
$result = $date->check_ywd(2006, 52, 6);
test 199, $result;
test 200, $result == $date;
test_ymd(201, $date, 2006, 12, 31);
$result = $date->check_ywd(2006, 53, 0);
test 202, !defined($result);
test_ymd(203, $date, 2006, 12, 31);
$result = $date->check_ywd(2006, 0, 6);
test 204, !defined($result);
test_ymd(205, $date, 2006, 12, 31);
$result = $date->check_ywd(2004, 53, 6);
test 206, $result;
test_ymd(207, $date, 2005, 1, 2);

# --- results of set_* methods

$date = Date::Gregorian->new;
$bate = $date->new;
test 208, $bate != $date;

$date2 = $date->set_date($bate);
test 209, $date == $date2;

$date2 = $date->set_ymd(2007, 4, 8);
test 210, $date == $date2;

$date2 = $date->set_yd(2007, 98);
test 211, $date == $date2;

$date2 = $date->set_ywd(2007, 14, 6);
test 212, $date == $date2;

$date2 = $date->set_easter(2007);
test 213, $date == $date2;

$date2 = $date->set_today;
test 214, $date == $date2;

$date2 = $date->set_localtime(1175990400);
test 215, $date == $date2;

$date2 = $date->set_gmtime(1175990400);
test 216, $date == $date2;

$date2 = $date->set_weekday(6, '<=');
test 217, $date == $date2;

# --- easter formula, border cases ---

test_ymd(218, $date->set_easter(2011), 2011, 4, 24);
test_ymd(219, $date->set_easter(2038), 2038, 4, 25);
test_ymd(220, $date->set_easter(2049), 2049, 4, 18);
test_ymd(221, $date->set_easter(2076), 2076, 4, 19);
test_ymd(222, $date->set_easter(2201), 2201, 4, 19);
test_ymd(223, $date->set_easter(2258), 2258, 4, 25);

$date->configure(1600, 1, 1, 1700);
test_ymd(224, $date->set_easter(1666), 1666, 4, 25);

$date->configure(-5000, 1, 1, -5000);
$date->set_easter(-4000);
test_ymd(225, $date, -4000, 4, 16);

# --- more checks of checks ---

$date = Date::Gregorian->new;
test 226, !$date->check_ymd();
test 227, !$date->check_ymd(2007);
test 228, !$date->check_ymd(2007, 6);
test 229, !$date->check_ymd(2007, undef, 20);
test 230, !$date->check_ymd(undef, 6, 20);
test 231, !$date->check_ymd(2007, 6, 0);
test 232, !$date->check_ymd(2007, 6, 31);
test 233, !$date->check_ymd(2007, 6, 32);
test 234, !$date->check_ymd(2007, 0, 1);
test 235, !$date->check_ymd(2007, 13, 1);
test 236, !$date->check_ymd(2147483647, 1, 1);
test 237, !$date->check_ymd(-2147483647, 1, 1);

my $MONDAY = Date::Gregorian::MONDAY;
my $SUNDAY = Date::Gregorian::SUNDAY;
test 238, $MONDAY + 6 == $SUNDAY;

test 239, !$date->check_ywd();
test 240, !$date->check_ywd(2007);
test 241, !$date->check_ywd(2007, 20);
test 242, !$date->check_ywd(2007, undef, $MONDAY);
test 243, !$date->check_ywd(undef, 20, $MONDAY);
test 244, !$date->check_ywd(2007, 20, $MONDAY-1);
test 245, !$date->check_ywd(2007, 20, $SUNDAY+1);
test 246, !$date->check_ywd(2007, 0, $SUNDAY);
test 247, !$date->check_ywd(2007, 53, $MONDAY);
test 248, !$date->check_ywd(2007, 54, $MONDAY);
test 249,  $date->check_ywd(2008, 1, $MONDAY);
test 250, !$date->check_ywd(2147483647, 20, $MONDAY);
test 251, !$date->check_ywd(-2147483647, 1, $MONDAY);

# --- get_days_until, compare ---

$date = Date::Gregorian->new->set_ymd(1999, 11, 29);
$date2 = $date->new->set_ymd(2007, 6, 14);

test 252, 2754 == $date->get_days_until($date2);
test 253, -2754 == $date2->get_days_until($date);
test 254, -1 == $date->compare($date2);
test 255, 1 == $date2->compare($date);
$date2->set_date($date);
test 256, 0 == $date->get_days_until($date2);
test 257, 0 == $date->get_days_until($date);
test 258, 0 == $date->compare($date2);
test 259, 0 == $date->compare($date);
$date2->configure(1752, 9, 14, 1753);
test 260, 0 == $date->get_days_until($date2);
test 261, 0 == $date->compare($date2);

__END__
