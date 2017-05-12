# Copyright (c) 2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# test stringification
print "1..26\n";

use Date::Gregorian;

sub test {
    my ($nr, $check) = @_;
    print $check? '': 'not ', "ok $nr\n";
}

my $date = Date::Gregorian->new->set_ymd(2007, 4, 8);
my $str = $date->get_string;

test 1, defined($str);
test 2, defined($str) && '2007-04-08G' eq $str;

my $date2 = $date->new->set_ymd(1517, 10, 31);
my $str2 = $date2->get_string;

test 3, defined($str2);
test 4, defined($str2) && '1517-10-31J' eq $str2;

my $date3 = $date->new;
my $res = $date3->set_string($str2);

test 5, defined($res);
test 6, defined($res) && $date3 == $res;
test 7, 0 == $date3->get_days_since($date2);

$date3 = $date2->new;
$res = $date3->set_string($str);

test 8, defined($res);
test 9, defined($res) && $date3 == $res;
test 10, 0 == $date3->get_days_since($date);

$date->set_ymd(1987, 12, 18);
$res = $date3->set_string('1987-12-18');

test 11, defined($res);
test 12, defined($res) && $date3 == $res;
test 13, 0 == $date3->get_days_since($date);
test 14, $date3->is_gregorian;

$date->set_ymd(1483, 11, 10);
$res = $date3->set_string('1483-11-10');

test 15, defined($res);
test 16, defined($res) && $date3 == $res;
test 17, 0 == $date3->get_days_since($date);
test 18, !$date3->is_gregorian;

$date->set_ymd(-752, 4, 21);
$res = $date3->set_string('-752-04-21');

test 19, defined($res);
test 20, defined($res) && $date3 == $res;
test 21, 0 == $date3->get_days_since($date);
test 22, !$date3->is_gregorian;

$date3->set_ymd(2001, 4, 8);
$date->set_date($date3);
$res = $date3->set_string('X');

test 23, !defined($res);
test 24, 0 == $date3->get_days_since($date);

$date3->set_date($date);
$date3->set_string('2006-01-31X');

test 25, !defined($res);
test 26, 0 == $date3->get_days_since($date);

__END__
