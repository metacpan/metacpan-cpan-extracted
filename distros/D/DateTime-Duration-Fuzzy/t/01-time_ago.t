#!perl -T

use Test::More tests => 35;

BEGIN {
    use_ok( 'DateTime::Duration::Fuzzy', qw(time_ago) ) || print "Bail out!
";
    use_ok('DateTime');
    use_ok('DateTime::Duration');
}

sub dt {
    return DateTime->new(@_)
}

sub dur {
    return DateTime::Duration->new(@_)
}

sub t {
    my $string = pop @_;
    return is(time_ago(@_), $string, $string)
}

my $ts = 1292174161;
my $now = DateTime->from_epoch(epoch => $ts);

is($now->datetime, '2010-12-12T17:16:01', 'Created DateTime object');

my $future = $now + dur(seconds => 1);
t($future, $now, 'in the future');

t($now, $now, 'just now');

t($now - dur(minutes => 5), $now, 'a few minutes ago');

t($now - dur(minutes => 20), $now, 'less than an hour ago');

t($now - dur(minutes => 60), $now, 'about an hour ago');

t($now - dur(minutes => 100), $now, 'more than an hour ago');

t($now - dur(hours => 4, minutes => 2), $now, 'several hours ago');

$now = dt(year => 2010, month => 12, day => 12, hour => 23);
my $then = $now->clone->set_hour(3)->subtract(minutes => 2);
t($then, $now, 'tonight');

$then->set_hour(8);
t($then, $now, 'this morning');

$then->set_hour(12);
t($then, $now, 'today');

$then->set_hour(16);
t($then, $now, 'this afternoon');

$then->set_day(11);
t($then, $now, 'yesterday');

$now->set_hour(9);
t($then, $now, 'yesterday');

$now->set_day(10);
$then->set_day(7);
t($then, $now, 'this week');

$then->set_day(1);
t($then, $now, 'last week');

$now->set_day(24); # merry Christmas!
t($then, $now, 'this month');

$then->set_month(11);
t($then, $now, 'last month');

$then->set_month(9);
t($then, $now, 'several months ago');

$then->set_month(1);
t($then, $now, 'about a year ago');

$then->set_year(2009)->set_month(12);
t($then, $now, 'last year');

$then->set_year(2008)->set_month(9);
$now->set_month(6);
t($then, $now, 'more than a year ago');

$then->set_year(2003);
t($then, $now, 'several years ago');

$then->set_year(2000);
t($then, $now, 'about a decade ago');

$then->set_year(1991);
$now->set_year(2009);
t($then, $now, 'last decade');  # very decadent

$then->set_year(1975);
t($then, $now, 'several decades ago');

$then->set_year(1910);
t($then, $now, 'about a century ago');

$now->set_year(2053);
t($then, $now, 'last century');

$then->set_year(1784);
t($then, $now, 'several centuries ago');

$then->set_year(1054);
t($then, $now, 'about a millenium ago');

$now->set_year(2010);
$then->set_year(1009);
t($then, $now, 'more than a millenium ago');

$then->set_year(1);
t($then, $now, 'millenia ago');
