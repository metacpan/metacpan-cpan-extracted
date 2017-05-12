package main;

use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use DateTime::Calendar::Christian;

my $gw = DateTime::Calendar::Christian->new(
    year	=> 1732,
    month	=> 2,
    day		=> 22,
);

is $gw->strftime( '%Y-%m-%d %{calendar_name}' ), '1732-02-22 Gregorian',
    q<George Washington's birthday, Gregorian>;

$gw = DateTime::Calendar::Christian->new(
    year	=> 1732,
    month	=> 2,
    day		=> 11,
    reform_date	=> 'uk',
);

is $gw->strftime( '%Y-%m-%d %{calendar_name}' ), '1732-02-11 Julian',
    q<George Washington's birthday, Julian>;

done_testing;

1;

# ex: set textwidth=72 :
