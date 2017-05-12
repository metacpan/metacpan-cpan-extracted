# Copyright (c) 2005-2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl business.t'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..347\n"; }
END {print "not ok 1\n" unless $loaded;}
use Date::Gregorian::Business;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use strict;
use Date::Gregorian qw(SATURDAY SUNDAY);

sub test {
    my ($n, $bool) = @_;
    print $bool? (): 'not ', 'ok ', $n, "\n";
}

sub test_equal {
    my ($n, $a, $b) = @_;
    my $check = defined($a) && defined($b) && $a == $b;
    if (!$check) {
	$a = 'undef' if !defined($a);
	$b = 'undef' if !defined($b);
	warn "[$n] $a vs $b\n";
    }
    test $n, $check;
}

sub test_array_equal {
    my ($n, $a, $b) = @_;
    my $check = $a && $b && @$a == @$b;
    my $i = 0;
    while ($check && $i < @$a) {
	$check &&=
	    defined($a->[$i]) && defined($b->[$i]) && $a->[$i] == $b->[$i];
	++$i;
    }
    test $n, $check;
}

sub test_ymd {
    my ($n, $date, @ymd) = @_;
    my $date2 = ref($date) && $date->new->check_ymd(@ymd);
    test $n, $date2 && 0 == $date2->get_days_since($date);
}

sub test_ymda {
    my ($n, $date, $y, $m, $d, $a) = @_;
    my $date2 = ref($date) && $date->new->check_ymd($y, $m, $d);
    test $n,
	$date2 &&
	0 == $date2->get_days_since($date) &&
	$a == $date->get_alignment;
}

sub fmt_date {
    my ($date) = @_;
    return sprintf "%04d-%02d-%02d", $date->get_ymd;
}

sub test_calendar {
    my ($n, $date, $calendar, @first_ymd) = @_;
    if (!$date) {
	test $n, undef;
	return;
    }
    my $date2 = $date->new->set_ymd(@first_ymd);
    my $result = 1;
    my ($biz, $exp);
    foreach $exp (@$calendar) {
	$biz = $date2->is_businessday;
	if (($biz xor $exp) || $biz != $exp) {
	    $result = '';
	    $biz = defined($biz)? "'" . $biz . "'": 'undef';
	    $exp = defined($exp)? "'" . $exp . "'": 'undef';
	    warn
		"[$n] ", fmt_date($date2),
		" is_businessday=$biz expected=$exp\n";
	}
	$date2->add_days(1);
    }
    test $n, $result;
}

sub test_equivalence {
    my ($n, $date1, $date2, $days, @ymd) = @_;
    my $result = 1;
    my ($fd1, $fd2, $delta, $biz1, $biz2);
    if (!$date1 || !$date2) {
	test $n, undef;
	return;
    }
    $fd1 = fmt_date($date1);
    $fd2 = fmt_date($date2);
    $delta = $date1->get_days_since($date2);
    if ($fd1 ne $fd2 || 0 != $delta) {
	$result = '';
	warn "[$n] current $fd1 vs $fd2, delta=$delta\n";
    }
    $date1 = $date1->new->set_ymd(@ymd);
    $date2 = $date2->new->set_ymd(@ymd);
    while (0 < $days) {
	$biz1 = $date1->is_businessday;
	$biz2 = $date2->is_businessday;
	if (($biz1 xor $biz2) || $biz1 != $biz2) {
	    $fd1 = fmt_date($date1);
	    $fd2 = fmt_date($date2);
	    $biz1 = defined($biz1)? "'" . $biz1 . "'": 'undef';
	    $biz2 = defined($biz2)? "'" . $biz2 . "'": 'undef';
	    $result = '';
	    warn "[$n] $fd1/$fd2, is_businessday $biz1 vs $biz2\n";
	}
	$date1->add_days(1);
	$date2->add_days(1);
	-- $days;
    }
    test $n, $result;
}

sub test_iterator {
    my ($n, $date, $iterator, $steps) = @_;
    my $base = $date->new;
    my $result = 'CODE' eq ref $iterator;
    my $distance = 0;
    foreach my $step (@$steps) {
	$distance += $step;
	$result &&= $iterator->();
	$result &&= $distance == $date->get_days_since($base);
    }
    $result &&= !$iterator->();
    $result &&= $distance == $date->get_days_since($base);
    test $n, $result;
}

my @my_holidays = (
    [6],                                        # Sundays
    [
	[11, 22, [3, 2, 1, 0, 6, 5, 4]],        # Thanksgiving
	[12, 25],                               # December 25
	[12, 26, undef, [2005, 2008]],          # December 26 in 2005-2008
	[12, 27, undef, sub { $_[1] & 1 }],     # December 27 in odd years
	[12, 28, undef, [undef, 2006]],		# December 28 until 2006
	[12, 29, undef, [2007, undef]],		# December 29 from 2007 on
	[12, 30, undef, 2009],			# December 30 in 2009
    ]
);

my %some_holidays = (
    2003 => [
	[ 1,  1],
	[ 1, 20],
	[ 2, 17],
	[ 5, 26],
	[ 7,  4],
	[ 9,  1],
	[10, 13],
	[11, 11],
	[11, 27],
	[12, 25],
    ],
    2004 => [
	[ 1,  1],
	[ 1, 19],
	[ 2, 16],
	[ 5, 31],
	[ 7,  5],
	[ 9,  6],
	[10, 11],
	[11, 11],
	[11, 25],
	[12, 27],
    ],
    2005 => [
	[ 1,  3],
	[ 1, 17],
	[ 2, 21],
	[ 5, 30],
	[ 7,  4],
	[ 9,  5],
	[10, 10],
	[11, 11],
	[11, 24],
	[12, 26],
    ],
    2006 => [
	[ 1,  2],
	[ 1, 16],
	[ 2, 20],
	[ 5, 29],
	[ 7,  4],
	[ 9,  4],
	[10,  9],
	[11, 10],
	[11, 23],
	[12, 25],
    ],
);

my $my_make_calendar2_called = 0;

sub my_make_calendar {
    my ($date, $year) = @_;
    my $calendar = $date->get_empty_calendar($year, []);
    my $i;
    for ($i = 0; $i < @$calendar; $i += 10) {
	$calendar->[$i] = 0;
    }
    return $calendar;
}

sub my_make_calendar2 {
    my ($date, $year) = @_;
    my $calendar = $date->get_empty_calendar($year, [SATURDAY, SUNDAY]);
    ++ $my_make_calendar2_called;
    if (exists $some_holidays{$year}) {
	my $first = $date->new->set_yd($year, 1);
	my $this = $first->new;
	foreach my $md (@{$some_holidays{$year}}) {
	    my $i = $this->set_ymd($year, @$md)->get_days_since($first);
	    if (0 <= $i && $i < @$calendar) {
		$calendar->[$i] = 0;
	    };
	}
    }
    return $calendar;
}

my $date = Date::Gregorian::Business->new;
my $date2;
my $result;

test(2, $date->isa('Date::Gregorian::Business'));
test(3, $date->isa('Date::Gregorian'));

$result = Date::Gregorian::Business->define_configuration(
    'arr test' => \@my_holidays
);
test(4, $result);

$result = Date::Gregorian::Business->define_configuration(
    'sub test' => \&my_make_calendar
);
test(5, $result);

$result = Date::Gregorian::Business->configure_business('undef test');
test(6, !defined($result));

$date = Date::Gregorian::Business->new('de_BW');
test(7, defined($date) && $date->isa('Date::Gregorian::Business'));

$date = Date::Gregorian::Business->new->set_ymd(1999, 12, 31);
$date2 = $date->new;
test(8, $date->configure_business('arr test'));
test(9, $date2->configure_business(\@my_holidays));
test_equivalence(10, $date, $date2, 66, 2003, 11, 1);
test_equivalence(11, $date, $date2, 66, 2004, 11, 1);
test_equivalence(12, $date, $date2, 66, 2005, 11, 1);
test_equivalence(13, $date, $date2, 66, 2006, 11, 1);
test_equivalence(14, $date, $date2, 66, 2007, 11, 1);
test_equivalence(15, $date, $date2, 66, 2008, 11, 1);
test_equivalence(16, $date, $date2, 66, 2009, 11, 1);

test_calendar(17, $date, [
    (0, 1, 1, 1, 0, 1, 1),
    (0, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 0, 1, 0),
    (0, 1, 1, 1, 1, 1, 1),
], 2003, 11, 23);
test_calendar(18, $date, [
    (0, 1, 1, 1, 0, 1, 1),
    (0, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1, 0, 1, 1, 1, 1),
], 2004, 11, 21);
test_calendar(19, $date, [
    (0, 1, 1, 1, 0, 1, 1),
    (0, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 1, 1, 1),
    (0, 0, 0, 0, 1, 1, 1),
], 2005, 11, 20);
test_calendar(20, $date, [
    (0, 1, 1, 1, 0, 1, 1),
    (0, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 1, 1, 1),
    (0, 0, 0, 1, 0, 1, 1),
], 2006, 11, 19);
test_calendar(21, $date, [
    (0, 1, 1, 1, 0, 1, 1),
    (0, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 1, 1, 1),
    (0, 1, 0, 0, 0, 1, 0),
], 2007, 11, 18);
test_calendar(22, $date, [
    (0, 1, 1, 1, 0, 1, 1),
    (0, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 0, 0, 1),
    (0, 0, 1, 1, 1, 1, 1),
], 2008, 11, 23);
test_calendar(23, $date, [
    (0, 1, 1, 1, 0, 1, 1),
    (0, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 1, 0, 1),
    (0, 1, 0, 0, 1, 1, 1),
], 2009, 11, 22);

$date2->set_date($date->set_ymd(2005, 4, 23));
$result = $date->configure_business('sub test');
test(24, $result);
test_ymd(25, $date, 2005, 4, 23);
$result = $date2->configure_business(\&my_make_calendar);
test(26, $result);
test_ymd(27, $date2, 2005, 4, 23);
test_equivalence(28, $date, $date2, 100, 1999, 11, 1);
test_equivalence(29, $date, $date2, 100, 2000, 11, 1);
test_calendar(30, $date, [
    (0, 1, 1, 1, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 1, 1),
    (0, 1, 1, 1, 1, 1, 1, 1, 1, 1) x 3,
    (0, 1, 1, 1, 1, 1),
], 2000, 11, 26);

$date2 = Date::Gregorian::Business->new('us');
test(31, $date2);

$result = $date2->set_ymd(2006, 1, 6)->align(1);
test(32, $result == $date2);
test(33, 1 == $date2->get_alignment);

$date = $date2->new;
test(34, $date);
test(35, 1 == $date2->get_alignment);

$date->set_ymd(2005, 12, 26);
test(36, 1 == $date->get_alignment);

$date->align(0);
test(37, 0 == $date->get_alignment);

test(38, 11 == $date2->get_days_since($date));
test(39, -11 == $date->get_days_since($date2));

test(40, 8 == $date2->get_businessdays_since($date));
test(41, 8 == $date->get_businessdays_until($date2));
test(42, -8 == $date->get_businessdays_since($date2));
test(43, -8 == $date2->get_businessdays_until($date));

$date2->align(0);

test(44, 7 == $date2->get_businessdays_since($date));
test(45, 7 == $date->get_businessdays_until($date2));
test(46, -7 == $date->get_businessdays_since($date2));
test(47, -7 == $date2->get_businessdays_until($date));

$date->align(1);

test(48, 7 == $date2->get_businessdays_since($date));
test(49, 7 == $date->get_businessdays_until($date2));
test(50, -7 == $date->get_businessdays_since($date2));
test(51, -7 == $date2->get_businessdays_until($date));

test_calendar(52, $date, [
    (0, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0),
], 1999, 1, 1);
test_calendar(53, $date, [
    (0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1),
], 2000, 1, 1);
test_calendar(54, $date, [
    (0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1, 1, 1),
], 2001, 1, 1);
test_calendar(55, $date, [
    (0, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1),
], 2002, 1, 1);
test_calendar(56, $date, [
    (0, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1),
], 2003, 1, 1);
test_calendar(57, $date, [
    (0, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
], 2004, 1, 1);
test_calendar(58, $date, [
    (0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1),
], 2005, 1, 1);
test_calendar(59, $date, [
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0),
    (0, 1, 1, 1, 1, 1, 0),
    (0, 1, 1),
], 2006, 1, 1);

$date->align(0);

$date->set_ymd(1999, 12, 31)->set_next_businessday('>=');
test_ymda(60, $date, 1999, 12, 31, 0);
$date->set_ymd(2000, 1, 1)->set_next_businessday('>=');
test_ymda(61, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 2)->set_next_businessday('>=');
test_ymda(62, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 3)->set_next_businessday('>=');
test_ymda(63, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 4)->set_next_businessday('>=');
test_ymda(64, $date, 2000, 1, 4, 0);

$date->set_ymd(1999, 12, 31)->set_next_businessday('>');
test_ymda(65, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 1)->set_next_businessday('>');
test_ymda(66, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 2)->set_next_businessday('>');
test_ymda(67, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 3)->set_next_businessday('>');
test_ymda(68, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 4)->set_next_businessday('>');
test_ymda(69, $date, 2000, 1, 5, 0);

$date->set_ymd(1999, 12, 31)->set_next_businessday('<=');
test_ymda(70, $date, 1999, 12, 31, 0);
$date->set_ymd(2000, 1, 1)->set_next_businessday('<=');
test_ymda(71, $date, 1999, 12, 31, 0);
$date->set_ymd(2000, 1, 2)->set_next_businessday('<=');
test_ymda(72, $date, 1999, 12, 31, 0);
$date->set_ymd(2000, 1, 3)->set_next_businessday('<=');
test_ymda(73, $date, 1999, 12, 31, 0);
$date->set_ymd(2000, 1, 4)->set_next_businessday('<=');
test_ymda(74, $date, 2000, 1, 4, 0);

$date->set_ymd(1999, 12, 31)->set_next_businessday('<');
test_ymda(75, $date, 1999, 12, 30, 0);
$date->set_ymd(2000, 1, 1)->set_next_businessday('<');
test_ymda(76, $date, 1999, 12, 31, 0);
$date->set_ymd(2000, 1, 2)->set_next_businessday('<');
test_ymda(77, $date, 1999, 12, 31, 0);
$date->set_ymd(2000, 1, 3)->set_next_businessday('<');
test_ymda(78, $date, 1999, 12, 31, 0);
$date->set_ymd(2000, 1, 4)->set_next_businessday('<');
test_ymda(79, $date, 1999, 12, 31, 0);

$date->align(1);

$date->set_ymd(1999, 12, 31)->set_next_businessday('>=');
test_ymda(80, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 1)->set_next_businessday('>=');
test_ymda(81, $date, 2000, 1, 4, 1);
$date->set_ymd(2000, 1, 2)->set_next_businessday('>=');
test_ymda(82, $date, 2000, 1, 4, 1);
$date->set_ymd(2000, 1, 3)->set_next_businessday('>=');
test_ymda(83, $date, 2000, 1, 4, 1);
$date->set_ymd(2000, 1, 4)->set_next_businessday('>=');
test_ymda(84, $date, 2000, 1, 4, 1);

$date->set_ymd(1999, 12, 31)->set_next_businessday('>');
test_ymda(85, $date, 2000, 1, 4, 1);
$date->set_ymd(2000, 1, 1)->set_next_businessday('>');
test_ymda(86, $date, 2000, 1, 4, 1);
$date->set_ymd(2000, 1, 2)->set_next_businessday('>');
test_ymda(87, $date, 2000, 1, 4, 1);
$date->set_ymd(2000, 1, 3)->set_next_businessday('>');
test_ymda(88, $date, 2000, 1, 4, 1);
$date->set_ymd(2000, 1, 4)->set_next_businessday('>');
test_ymda(89, $date, 2000, 1, 5, 1);

$date->set_ymd(1999, 12, 31)->set_next_businessday('<=');
test_ymda(90, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 1)->set_next_businessday('<=');
test_ymda(91, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 2)->set_next_businessday('<=');
test_ymda(92, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 3)->set_next_businessday('<=');
test_ymda(93, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 4)->set_next_businessday('<=');
test_ymda(94, $date, 2000, 1, 4, 1);

$date->set_ymd(1999, 12, 31)->set_next_businessday('<');
test_ymda(95, $date, 1999, 12, 30, 1);
$date->set_ymd(2000, 1, 1)->set_next_businessday('<');
test_ymda(96, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 2)->set_next_businessday('<');
test_ymda(97, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 3)->set_next_businessday('<');
test_ymda(98, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 4)->set_next_businessday('<');
test_ymda(99, $date, 1999, 12, 31, 1);

$date->set_ymd(1999, 12, 31)->align(0)->add_businessdays(0);
test_ymda(100, $date, 1999, 12, 31, 0);
$date->set_ymd(1999, 12, 31)->align(0)->add_businessdays(0, 0);
test_ymda(101, $date, 1999, 12, 31, 0);
$date->set_ymd(1999, 12, 31)->align(0)->add_businessdays(0, 1);
test_ymda(102, $date, 1999, 12, 30, 1);
$date->set_ymd(1999, 12, 31)->align(1)->add_businessdays(0);
test_ymda(103, $date, 1999, 12, 31, 1);
$date->set_ymd(1999, 12, 31)->align(1)->add_businessdays(0, 0);
test_ymda(104, $date, 2000, 1, 4, 0);
$date->set_ymd(1999, 12, 31)->align(1)->add_businessdays(0, 1);
test_ymda(105, $date, 1999, 12, 31, 1);

$date->set_ymd(2000, 1, 1)->align(0)->add_businessdays(0);
test_ymda(106, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 1)->align(0)->add_businessdays(0, 0);
test_ymda(107, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 1)->align(0)->add_businessdays(0, 1);
test_ymda(108, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 1)->align(1)->add_businessdays(0);
test_ymda(109, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 1)->align(1)->add_businessdays(0, 0);
test_ymda(110, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 1)->align(1)->add_businessdays(0, 1);
test_ymda(111, $date, 1999, 12, 31, 1);

$date->set_ymd(2000, 1, 3)->align(0)->add_businessdays(0);
test_ymda(112, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 3)->align(0)->add_businessdays(0, 0);
test_ymda(113, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 3)->align(0)->add_businessdays(0, 1);
test_ymda(114, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 3)->align(1)->add_businessdays(0);
test_ymda(115, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 3)->align(1)->add_businessdays(0, 0);
test_ymda(116, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 3)->align(1)->add_businessdays(0, 1);
test_ymda(117, $date, 1999, 12, 31, 1);

$date->set_ymd(2000, 1, 4)->align(0)->add_businessdays(0);
test_ymda(118, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 4)->align(0)->add_businessdays(0, 0);
test_ymda(119, $date, 2000, 1, 4, 0);
$date->set_ymd(2000, 1, 4)->align(0)->add_businessdays(0, 1);
test_ymda(120, $date, 1999, 12, 31, 1);
$date->set_ymd(2000, 1, 4)->align(1)->add_businessdays(0);
test_ymda(121, $date, 2000, 1, 4, 1);
$date->set_ymd(2000, 1, 4)->align(1)->add_businessdays(0, 0);
test_ymda(122, $date, 2000, 1, 5, 0);
$date->set_ymd(2000, 1, 4)->align(1)->add_businessdays(0, 1);
test_ymda(123, $date, 2000, 1, 4, 1);

$date->set_ymd(2005, 1, 1)->align(0);
$date2 = $date->new->set_ymd(2005, 12, 31)->align(1);

test 124, $date->configure_business('de');
test_equal 125, 255, $date->get_businessdays_until($date2);

test 126, $date->configure_business('de_BW');
test_equal 127, 251, $date->get_businessdays_until($date2);

test 128, $date->configure_business('de_BY');
test_equal 129, 250, $date->get_businessdays_until($date2);

test 130, $date->configure_business('de_BW2');
test_equal 131, 251, $date->get_businessdays_until($date2);

test 132, $date->configure_business('de_BY2');
test_equal 133, 250, $date->get_businessdays_until($date2);

$date->set_ymd(2004, 1, 1);
$date2->set_ymd(2004, 12, 31);
test_equal 134, 253, $date->get_businessdays_until($date2);
$date->configure_business('de_BY');
test_equal 135, 254, $date->get_businessdays_until($date2);

$date->configure_business('de_BY2');
$date->set_ymd(2004, 12, 23)->align(0);
$date2->set_ymd(2004, 12, 26)->align(0);
test_equal 136, 1.5, $date->get_businessdays_until($date2);
$date->set_ymd(2004, 12, 24);
test_equal 137, 0.5, $date->is_businessday;

$date = Date::Gregorian::Business->new('us');
test_calendar(138, $date, [
    0, 1, 1, 0, 0,
    (1, 1, 1, 1, 1, 0, 0) x 2,
    0, 1, 1, 1, 1, 0, 0,
    (1, 1, 1, 1, 1, 0, 0) x 3,
    0, 1, 1, 1, 1, 0, 0,
    (1, 1, 1, 1, 1, 0, 0) x 13,
    0, 1, 1, 1, 1, 0, 0,
    (1, 1, 1, 1, 1, 0, 0) x 4,
    1, 1, 1, 1, 0, 0, 0,
    (1, 1, 1, 1, 1, 0, 0) x 8,
    0, 1, 1, 1, 1, 0, 0,
    (1, 1, 1, 1, 1, 0, 0) x 5,
    0, 1, 1, 1, 1, 0, 0,
    (1, 1, 1, 1, 1, 0, 0) x 3,
    1, 0, 1, 1, 1, 0, 0,
    1, 1, 1, 1, 1, 0, 0,
    1, 1, 1, 0, 1, 0, 0,
    (1, 1, 1, 1, 1, 0, 0) x 3,
    1, 1, 1, 0, 1, 0, 0,
    1, 1, 1,
], 2003, 1, 1);
test(139, !$date->set_ymd(1998, 7, 3)->is_businessday);

$my_make_calendar2_called = 0;
delete $some_holidays{1998};
$date2 = Date::Gregorian::Business->new(\&my_make_calendar2);
test_calendar(140, $date2, [1, 0, 0, 1], 1998, 7, 3);
test(141, 1 == $my_make_calendar2_called);

$date2->set_ymd(1998, 7, 3);
test_equivalence(142, $date, $date2, 1461, 2003, 1, 1);

$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(3);
test_ymda(143, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(3, 0);
test_ymda(144, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(3, 1);
test_ymda(145, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(2);
test_ymda(146, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(2, 0);
test_ymda(147, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(2, 1);
test_ymda(148, $date, 2003, 7, 3, 1);

$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-3);
test_ymda(149, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-3, 0);
test_ymda(150, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-3, 1);
test_ymda(151, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-4);
test_ymda(152, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-4, 0);
test_ymda(153, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-4, 1);
test_ymda(154, $date, 2003, 7, 3, 1);

$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(2.5);
test_ymda(155, $date, 2003, 7, 3, 0);
$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(3.5);
test_ymda(156, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(2.5, 0);
test_ymda(157, $date, 2003, 7, 3, 0);
$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(3.5, 0);
test_ymda(158, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(2.5, 1);
test_ymda(159, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 1)->align(0)->add_businessdays(3.5, 1);
test_ymda(160, $date, 2003, 7, 7, 1);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(1.5);
test_ymda(161, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(2.5);
test_ymda(162, $date, 2003, 7, 7, 1);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(1.5, 0);
test_ymda(163, $date, 2003, 7, 3, 0);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(2.5, 0);
test_ymda(164, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(1.5, 1);
test_ymda(165, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 1)->align(1)->add_businessdays(2.5, 1);
test_ymda(166, $date, 2003, 7, 7, 1);

$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-3.5);
test_ymda(167, $date, 2003, 7, 3, 0);
$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-2.5);
test_ymda(168, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-3.5, 0);
test_ymda(169, $date, 2003, 7, 3, 0);
$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-2.5, 0);
test_ymda(170, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-3.5, 1);
test_ymda(171, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 10)->align(0)->add_businessdays(-2.5, 1);
test_ymda(172, $date, 2003, 7, 7, 1);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-4.5);
test_ymda(173, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-3.5);
test_ymda(174, $date, 2003, 7, 7, 1);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-4.5, 0);
test_ymda(175, $date, 2003, 7, 3, 0);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-3.5, 0);
test_ymda(176, $date, 2003, 7, 7, 0);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-4.5, 1);
test_ymda(177, $date, 2003, 7, 3, 1);
$date->set_ymd(2003, 7, 10)->align(1)->add_businessdays(-3.5, 1);
test_ymda(178, $date, 2003, 7, 7, 1);

$date2 = $date->new;
$date->set_ymd(2003, 7, 1)->align(0);

$date2->set_ymd(2003, 7, 3)->align(0);
test(179,  2 == $date->get_businessdays_until($date2));
test(180, -2 == $date2->get_businessdays_until($date));
test(181, -2 == $date->get_businessdays_since($date2));
test(182,  2 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 3)->align(1);
test(183,  3 == $date->get_businessdays_until($date2));
test(184, -3 == $date2->get_businessdays_until($date));
test(185, -3 == $date->get_businessdays_since($date2));
test(186,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 4)->align(0);
test(187,  3 == $date->get_businessdays_until($date2));
test(188, -3 == $date2->get_businessdays_until($date));
test(189, -3 == $date->get_businessdays_since($date2));
test(190,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 4)->align(1);
test(191,  3 == $date->get_businessdays_until($date2));
test(192, -3 == $date2->get_businessdays_until($date));
test(193, -3 == $date->get_businessdays_since($date2));
test(194,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 6)->align(0);
test(195,  3 == $date->get_businessdays_until($date2));
test(196, -3 == $date2->get_businessdays_until($date));
test(197, -3 == $date->get_businessdays_since($date2));
test(198,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 6)->align(1);
test(199,  3 == $date->get_businessdays_until($date2));
test(200, -3 == $date2->get_businessdays_until($date));
test(201, -3 == $date->get_businessdays_since($date2));
test(202,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 7)->align(0);
test(203,  3 == $date->get_businessdays_until($date2));
test(204, -3 == $date2->get_businessdays_until($date));
test(205, -3 == $date->get_businessdays_since($date2));
test(206,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 7)->align(1);
test(207,  4 == $date->get_businessdays_until($date2));
test(208, -4 == $date2->get_businessdays_until($date));
test(209, -4 == $date->get_businessdays_since($date2));
test(210,  4 == $date2->get_businessdays_since($date));

$date->set_ymd(2003, 6, 30)->align(1);

$date2->set_ymd(2003, 7, 3)->align(0);
test(211,  2 == $date->get_businessdays_until($date2));
test(212, -2 == $date2->get_businessdays_until($date));
test(213, -2 == $date->get_businessdays_since($date2));
test(214,  2 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 3)->align(1);
test(215,  3 == $date->get_businessdays_until($date2));
test(216, -3 == $date2->get_businessdays_until($date));
test(217, -3 == $date->get_businessdays_since($date2));
test(218,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 4)->align(0);
test(219,  3 == $date->get_businessdays_until($date2));
test(220, -3 == $date2->get_businessdays_until($date));
test(221, -3 == $date->get_businessdays_since($date2));
test(222,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 4)->align(1);
test(223,  3 == $date->get_businessdays_until($date2));
test(224, -3 == $date2->get_businessdays_until($date));
test(225, -3 == $date->get_businessdays_since($date2));
test(226,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 6)->align(0);
test(227,  3 == $date->get_businessdays_until($date2));
test(228, -3 == $date2->get_businessdays_until($date));
test(229, -3 == $date->get_businessdays_since($date2));
test(230,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 6)->align(1);
test(231,  3 == $date->get_businessdays_until($date2));
test(232, -3 == $date2->get_businessdays_until($date));
test(233, -3 == $date->get_businessdays_since($date2));
test(234,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 7)->align(0);
test(235,  3 == $date->get_businessdays_until($date2));
test(236, -3 == $date2->get_businessdays_until($date));
test(237, -3 == $date->get_businessdays_since($date2));
test(238,  3 == $date2->get_businessdays_since($date));
$date2->set_ymd(2003, 7, 7)->align(1);
test(239,  4 == $date->get_businessdays_until($date2));
test(240, -4 == $date2->get_businessdays_until($date));
test(241, -4 == $date->get_businessdays_since($date2));
test(242,  4 == $date2->get_businessdays_since($date));

$date2 = Date::Gregorian->new;
$date->set_ymd(2003, 7, 1)->align(0);

$date2->set_ymd(2003, 7, 3);
test(243,  2 == $date->get_businessdays_until($date2));
test(244, -2 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 4);
test(245,  3 == $date->get_businessdays_until($date2));
test(246, -3 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 6);
test(247,  3 == $date->get_businessdays_until($date2));
test(248, -3 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 7);
test(249,  3 == $date->get_businessdays_until($date2));
test(250, -3 == $date->get_businessdays_since($date2));

$date->set_ymd(2003, 6, 30)->align(1);

$date2->set_ymd(2003, 7, 3);
test(251,  2 == $date->get_businessdays_until($date2));
test(252, -2 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 4);
test(253,  3 == $date->get_businessdays_until($date2));
test(254, -3 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 6);
test(255,  3 == $date->get_businessdays_until($date2));
test(256, -3 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 7);
test(257,  3 == $date->get_businessdays_until($date2));
test(258, -3 == $date->get_businessdays_since($date2));

$date->set_ymd(2003, 7, 10)->align(0);

$date2->set_ymd(2003, 7, 3);
test(259, -4 == $date->get_businessdays_until($date2));
test(260,  4 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 4);
test(261, -3 == $date->get_businessdays_until($date2));
test(262,  3 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 6);
test(263, -3 == $date->get_businessdays_until($date2));
test(264,  3 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 7);
test(265, -3 == $date->get_businessdays_until($date2));
test(266,  3 == $date->get_businessdays_since($date2));

$date->set_ymd(2003, 7, 9)->align(1);

$date2->set_ymd(2003, 7, 3);
test(267, -4 == $date->get_businessdays_until($date2));
test(268,  4 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 4);
test(269, -3 == $date->get_businessdays_until($date2));
test(270,  3 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 6);
test(271, -3 == $date->get_businessdays_until($date2));
test(272,  3 == $date->get_businessdays_since($date2));
$date2->set_ymd(2003, 7, 7);
test(273, -3 == $date->get_businessdays_until($date2));
test(274,  3 == $date->get_businessdays_since($date2));

$date = Date::Gregorian::Business->new->configure(1752, 9, 14, 1753);
my $calendar = $date->get_empty_calendar(2000, [SUNDAY]);
test_array_equal(275, $calendar, [
    1, 0,
    (1, 1, 1, 1, 1, 1, 0) x 52,
]);
$calendar = $date->get_empty_calendar(1752, [SUNDAY]);
test_array_equal(276, $calendar, [
    1, 1, 1, 1, 0,
    (1, 1, 1, 1, 1, 1, 0) x 50,
]);

$result =
    Date::Gregorian::Business->define_configuration("redefine test", "de");
test(277, $result);
$date = Date::Gregorian::Business->new("redefine test")->
    set_ymd(2005, 1, 1)->align(0);
$result =
    Date::Gregorian::Business->define_configuration("redefine test", "us");
$date2 = Date::Gregorian::Business->new("redefine test")->
    set_ymd(2005, 12, 31)->align(1);
test(278, defined($date) && defined($date2));
test(279, 255 == $date->get_businessdays_until($date2)); # conf "de" still
test(280, 250 == $date2->get_businessdays_since($date)); # conf "us"

$date = Date::Gregorian::Business->new('us')->set_ymd(1999, 2, 1);
$date2 = $date->new->set_ymd(1999, 3, 1);
my $iter = $date->iterate_businessdays_upto($date2, '<');
test_iterator(281, $date, $iter, [qw(
    0 1 1 1 1
    3 1 1 1 1
    4 1 1 1
    3 1 1 1 1
)]);

$date->set_ymd(1999, 2, 25);
$iter = $date->iterate_businessdays_upto($date2, '<=');
test_iterator(282, $date, $iter, [0, 1, 3]);

$date->set_ymd(1999, 2, 13);
$date2->set_ymd(1999, 2, 17);
$iter = $date->iterate_businessdays_upto($date2, '<');
test_iterator(283, $date, $iter, [3]);

$date->set_ymd(1999, 2, 13);
$date2->add_days(-1);
$iter = $date->iterate_businessdays_upto($date2, '<=');
test_iterator(284, $date, $iter, [3]);

$date->set_ymd(1999, 2, 13);
$iter = $date->iterate_businessdays_upto($date2, '<');
test_iterator(285, $date, $iter, []);

$date->set_ymd(1999, 2, 13);
$date2->add_days(-1);
$iter = $date->iterate_businessdays_upto($date2, '<=');
test_iterator(286, $date, $iter, []);

$date->set_ymd(1999, 2, 13);
$date2->set_date($date);
$iter = $date->iterate_businessdays_upto($date2, '<');
test_iterator(287, $date, $iter, []);

$date->set_ymd(1999, 2, 13);
$date2->add_days(-1);
$iter = $date->iterate_businessdays_upto($date2, '<=');
test_iterator(288, $date, $iter, []);

$date->set_ymd(1999, 2, 25);
$date2->set_date($date);
$iter = $date->iterate_businessdays_upto($date2, '<');
test_iterator(289, $date, $iter, []);

$date->set_ymd(1999, 2, 25);
$date2->add_days(-1);
$iter = $date->iterate_businessdays_upto($date2, '<=');
test_iterator(290, $date, $iter, []);

$date = Date::Gregorian::Business->new('us')->set_ymd(1999, 1, 31);
$date2 = $date->new->set_ymd(1998, 12, 31);
$iter = $date->iterate_businessdays_downto($date2, '>');
test_iterator(291, $date, $iter, [qw(
    -2 -1 -1 -1 -1
    -3 -1 -1 -1
    -4 -1 -1 -1 -1
    -3 -1 -1 -1 -1
)]);

$date->set_ymd(1999, 1, 5);
$iter = $date->iterate_businessdays_downto($date2, '>=');
test_iterator(292, $date, $iter, [0, -1, -4]);

$date->set_ymd(1999, 1, 18);
$date2->set_ymd(1999, 1, 14);
$iter = $date->iterate_businessdays_downto($date2, '>');
test_iterator(293, $date, $iter, [-3]);

$date->set_ymd(1999, 1, 18);
$date2->add_days(1);
$iter = $date->iterate_businessdays_downto($date2, '>=');
test_iterator(294, $date, $iter, [-3]);

$date->set_ymd(1999, 1, 18);
$iter = $date->iterate_businessdays_downto($date2, '>');
test_iterator(295, $date, $iter, []);

$date->set_ymd(1999, 1, 18);
$date2->add_days(1);
$iter = $date->iterate_businessdays_downto($date2, '>=');
test_iterator(296, $date, $iter, []);

$date->set_ymd(1999, 1, 18);
$date2->set_date($date);
$iter = $date->iterate_businessdays_downto($date2, '>');
test_iterator(297, $date, $iter, []);

$date->set_ymd(1999, 1, 18);
$date2->add_days(1);
$iter = $date->iterate_businessdays_downto($date2, '>=');
test_iterator(298, $date, $iter, []);

$date->set_ymd(1999, 1, 7);
$date2->set_date($date);
$iter = $date->iterate_businessdays_downto($date2, '>');
test_iterator(299, $date, $iter, []);

$date->set_ymd(1999, 1, 7);
$date2->add_days(1);
$iter = $date->iterate_businessdays_downto($date2, '>=');
test_iterator(300, $date, $iter, []);

$date->set_ymd(1999, 12, 25);
$date2->set_date($date)->add_days(12);
$iter = $date->iterate_days_upto($date2, '<');
my $iter2;
$result = '';
my $loopcheck = 12;
my $loopcheck2 = -1;
while ($iter->()) {
    last if !$loopcheck--;
    my ($m, $d) = ($date->get_ymd)[1, 2];
    $result .= sprintf "%02d/%02d:", $m, $d;
    $date2->set_date($date)->add_businessdays(2);
    $iter2 = $date->iterate_businessdays_upto($date2, '<');
    $loopcheck2 = 2;
    while ($iter2->()) {
	last if !$loopcheck2--;
	($m, $d) = ($date->get_ymd)[1, 2];
	$result .= sprintf " %02d/%02d", $m, $d;
    }
    last if $loopcheck2;
    $result .= "\n";
}
test 301, !$loopcheck && !$loopcheck2;
test 302, $result eq
    "12/25: 12/28 12/29\n" .
    "12/26: 12/28 12/29\n" .
    "12/27: 12/28 12/29\n" .
    "12/28: 12/28 12/29\n" .
    "12/29: 12/29 12/30\n" .
    "12/30: 12/30 12/31\n" .
    "12/31: 12/31 01/04\n" .
    "01/01: 01/04 01/05\n" .
    "01/02: 01/04 01/05\n" .
    "01/03: 01/04 01/05\n" .
    "01/04: 01/04 01/05\n" .
    "01/05: 01/05 01/06\n";


$result = Date::Gregorian::Business->define_configuration('Argh', {});
test 303, !defined($result);

$result = $date->configure_business({});
test 304, !defined($result);

$result = Date::Gregorian::Business->configure_business({});
test 305, !defined($result);

$result = Date::Gregorian::Business->configure_business([[6], []]);
test 306, $result;

$date = Date::Gregorian::Business->new->set_ymd(2006, 1, 19)->align(0);
$date2 = $date->new;
test 307, 0 == $date->get_businessdays_since($date2);
test 308, 0 == $date->get_businessdays_until($date2);
$date2->add_days(-1)->align(1);
test 309, 0 == $date->get_businessdays_since($date2);
test 310, 0 == $date2->get_businessdays_until($date);

$date = Date::Gregorian::Business->new->configure_business([[], []]);
test 311, ref $date;
$date->set_ymd(2001, 12, 1);
$date2 = $date->new->set_ymd(2003, 1, 31);
my $delta1 = $date2->get_days_since($date);
my $delta2 = $date2->get_businessdays_since($date);
test 312, $delta1 == $delta2;
test 313, 30+365+31 == $delta2;

my @strange_holidays = (
    [],
    [
        #            2284       2285       3784       3785
	[0, -115], # 2283-12-13 2284-11-27 3784-01-01 3784-12-16
	[0, -80],  # 2284-01-17 2285-01-01 3784-02-05 3785-01-20
	[0, 250],  # 2284-12-12 2285-11-27 3784-12-31 3785-12-16
	[0, 284],  # 2285-01-15 2285-12-31 3785-02-03 3786-01-19
    ]
);

$date->configure_business(\@strange_holidays);
test 314, !$date->set_ymd(2284,  1, 17)->is_businessday;
test 315,  $date->set_ymd(2284, 11, 27)->is_businessday;
test 316, !$date->set_ymd(2284, 12, 12)->is_businessday;
test 317, !$date->set_ymd(2285,  1,  1)->is_businessday;
test 318,  $date->set_ymd(2285,  1, 15)->is_businessday;
test 319, !$date->set_ymd(2285, 11, 27)->is_businessday;
test 320, !$date->set_ymd(2285, 12, 31)->is_businessday;
test 321, !$date->set_ymd(3784,  1,  1)->is_businessday;
test 322, !$date->set_ymd(3784,  2,  5)->is_businessday;
test 323,  $date->set_ymd(3784, 12, 16)->is_businessday;
test 324, !$date->set_ymd(3784, 12, 31)->is_businessday;
test 325, !$date->set_ymd(3785,  1, 20)->is_businessday;
test 326,  $date->set_ymd(3785,  2,  3)->is_businessday;
test 327, !$date->set_ymd(3785, 12, 16)->is_businessday;

# paranoia starts here

@strange_holidays = (
    [],
    [
        [0, 0, [0, 0, 0, 0, 0, 0, -115]],
        [0, 0, [0, 0, 0, 0, 0, 0, -80]],
        [0, 0, [0, 0, 0, 0, 0, 0, 250]],
        [0, 0, [0, 0, 0, 0, 0, 0, 284]],
    ]
);

$date->configure_business(\@strange_holidays);
test 328, !$date->set_ymd(2284,  1, 17)->is_businessday;
test 329,  $date->set_ymd(2284, 11, 27)->is_businessday;
test 330, !$date->set_ymd(2284, 12, 12)->is_businessday;
test 331, !$date->set_ymd(2285,  1,  1)->is_businessday;
test 332,  $date->set_ymd(2285,  1, 15)->is_businessday;
test 333, !$date->set_ymd(2285, 11, 27)->is_businessday;
test 334, !$date->set_ymd(2285, 12, 31)->is_businessday;
test 335, !$date->set_ymd(3784,  1,  1)->is_businessday;
test 336, !$date->set_ymd(3784,  2,  5)->is_businessday;
test 337,  $date->set_ymd(3784, 12, 16)->is_businessday;
test 338, !$date->set_ymd(3784, 12, 31)->is_businessday;
test 339, !$date->set_ymd(3785,  1, 20)->is_businessday;
test 340,  $date->set_ymd(3785,  2,  3)->is_businessday;
test 341, !$date->set_ymd(3785, 12, 16)->is_businessday;

$result = Date::Gregorian::Business->define_configuration('t1', 'unheard of');
test 342, !defined $result;
$result = Date::Gregorian::Business->define_configuration('t2', 't1');
test 343, !defined $result;
$result = Date::Gregorian::Business->define_configuration('t3', 'us');
test 344, $result;

$my_make_calendar2_called = 0;
$result = Date::Gregorian::Business->configure_business(\&my_make_calendar2);
test 345, $result;
$date2 = Date::Gregorian::Business->new();
test_calendar(346, $date2, [1, 0, 0, 1], 1998, 7, 3);
test 347, 1 == $my_make_calendar2_called;

__END__
