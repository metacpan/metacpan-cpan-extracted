use strict;
use DateTime;
BEGIN { $ENV{TZ} = 'Asia/Seoul' } 

use Date::Holidays::KR;
use Test::More tests => 24 * 3;

my @tests = (
    [ 1989, 2,  6 ],
    [ 1990, 1, 27 ],
    [ 1991, 2, 15 ],
    [ 1992, 2,  4 ],
    [ 1993, 1, 23 ],
    [ 1994, 2, 10 ],
    [ 1995, 1, 31 ],
    [ 1996, 2, 19 ],
    [ 1997, 2,  8 ],
    [ 1998, 1, 28 ],
    [ 1999, 2, 16 ],
    [ 2000, 2,  5 ],
    [ 2001, 1, 24 ],
    [ 2002, 2, 12 ],
    [ 2003, 2,  1 ],
    [ 2004, 1, 22 ],
    [ 2005, 2,  9 ],
    [ 2006, 1, 29 ],
    [ 2007, 2, 18 ],
    [ 2008, 2,  7 ],
    [ 2009, 1, 26 ],
    [ 2010, 2, 14 ],
    [ 2011, 2,  3 ],
    [ 2012, 1, 23 ],
);

for my $test (@tests) {
    my ( $year, $month, $day ) = @{ $test };

    my $dt = DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        time_zone => 'local',
    );
    my $dt_prev = $dt->clone->subtract( days => 1 );
    my $dt_next = $dt->clone->add( days => 1 );

    is(
        is_holiday($dt_prev->year, $dt_prev->month, $dt_prev->day),
        '설앞날',
        $dt_prev->ymd,
    );
    is(
        is_holiday($dt->year, $dt->month, $dt->day),
        '설날',
        $dt->ymd,
    );
    is(
        is_holiday($dt_next->year, $dt_next->month, $dt_next->day),
        '설뒷날',
        $dt_next->ymd,
    );
}

done_testing;
