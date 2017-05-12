package main;

use 5.008004;

use strict;
use warnings;

use DateTime;
use DateTime::Calendar::Christian;
use Test::More 0.88;	# Because of done_testing();

my $rd = DateTime->new(		# UK
    year	=> 1752,
    month	=> 9,
    day		=> 14,
);

foreach my $test (
    [ 1751, 12, 31, 365 ],
    [ 1752,  1,  1,   1 ],
    [ 1752,  1, 31,  31 ],
    [ 1752,  2, 28,  59 ],
    [ 1752,  2, 29,  60 ],
    [ 1752,  3,  1,  61 ],
    [ 1752,  9,  2, 246 ],
    [ 1752,  9, 14, 247 ],
    [ 1752, 12, 31, 355 ],
    [ 1753,  1,  1,   1 ],
) {
    my ( $year, $month, $day, $day_of_year ) = @{ $test };

    my $date = sprintf '%04d-%02d-%02d', $year, $month, $day;

    my $dt = DateTime::Calendar::Christian->new(
	year		=> $year,
	month		=> $month,
	day		=> $day,
	reform_date	=> $rd,
    );

    cmp_ok $dt->day_of_year, '==', $day_of_year,
	"day_of_year() of $date is $day_of_year";

    cmp_ok $dt->day_of_year_0, '==', $day_of_year - 1,
	"day_of_year_0() of $date is @{[ $day_of_year - 1 ]}";

    $dt = DateTime::Calendar::Christian->from_day_of_year(
	year	=> $year,
	day_of_year	=> $day_of_year,
	reform_date	=> $rd,
    );

    cmp_ok $dt->ymd, 'eq', $date,
	"from_day_of_year() of $year $day_of_year is $date";

}

done_testing;

1;

# ex: set textwidth=72 :
