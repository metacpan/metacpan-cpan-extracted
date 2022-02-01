package main;

use 5.008004;

use strict;
use warnings;

use DateTime::Calendar::Julian;
use Test::More 0.88;	# Because of done_testing();

note <<'EOD';

The following from DateTime t/03components.t

EOD

{
    my $d = DateTime::Calendar::Julian->new(
        year      => 2001,
        month     => 7,
        day       => 5,
        hour      => 2,
        minute    => 12,
        second    => 50,
        time_zone => 'UTC',
    );

    is( $d->quarter,        3,      '->quarter' );
    is( $d->day_of_quarter,   5,          '->day_of_quarter' );
    is( $d->day_of_quarter_0, 4,          '->day_of_quarter_0' );
    ok( !$d->is_last_day_of_quarter, '->is_last_day_of_quarter' );
    is( $d->quarter_length, 92,  '->quarter_length' );

    is( $d->quarter_abbr, 'Q3',          '->quarter_abbr' );
    is( $d->quarter_name, '3rd quarter', '->quarter_name' );
}

{
    my @tests = (
        { year => 2017, month => 8,  day => 19, expect => 0 },
        { year => 2017, month => 3,  day => 31, expect => 1 },
        { year => 2017, month => 6,  day => 30, expect => 1 },
        { year => 2017, month => 9,  day => 30, expect => 1 },
        { year => 2017, month => 12, day => 31, expect => 1 },
    );

    for my $t (@tests) {
        my $expect = delete $t->{expect};

        my $dt = DateTime::Calendar::Julian->new($t);

        my $is = $dt->is_last_day_of_quarter;
        ok( ( $expect ? $is : !$is ), '->is_last_day_of_quarter' );
    }
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1995, month => 2, day => 1 );

    is( $dt->quarter,        1,  '->quarter is 1' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 90, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1995, month => 2, day => 1 );

    is( $dt->quarter,        1,  '->quarter is 1' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 90, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1995, month => 5, day => 1 );

    is( $dt->quarter,        2,  '->quarter is 2' );
    is( $dt->day_of_quarter, 31, '->day_of_quarter' );
    is( $dt->quarter_length, 91, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1995, month => 8, day => 1 );

    is( $dt->quarter,        3,  '->quarter is 3' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 92, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1995, month => 11, day => 1 );

    is( $dt->quarter,        4,  '->quarter is 4' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 92, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1996, month => 2, day => 1 );

    is( $dt->quarter,        1,  '->quarter is 1' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 91, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1996, month => 5, day => 1 );

    is( $dt->quarter,        2,  '->quarter is 2' );
    is( $dt->day_of_quarter, 31, '->day_of_quarter' );
    is( $dt->quarter_length, 91, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1996, month => 8, day => 1 );

    is( $dt->quarter,        3,  '->quarter is 3' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 92, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Julian->new( year => 1996, month => 11, day => 1 );

    is( $dt->quarter,        4,  '->quarter is 4' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 92, '->quarter_length' );
}

note <<'EOD';

The following are Julian-specific

EOD

foreach my $info (
    {
	year	=> 1500,	# A leap year Julian, but not Gregorian
	month	=> 1,
	day	=> 22,
	quarter	=> 1,
	day_of_quarter	=> 22,
	quarter_length	=> 91,
    },
    {
	year	=> 1500,	# A leap year Julian, but not Gregorian
	month	=> 3,
	day	=> 1,
	quarter	=> 1,
	day_of_quarter	=> 61,
	quarter_length	=> 91,
    },
    {
	year	=> 1500,	# A leap year Julian, but not Gregorian
	month	=> 4,
	day	=> 1,
	quarter	=> 2,
	day_of_quarter	=> 1,
	quarter_length	=> 91,
    },
    {
	year	=> 1501,	# Not a leap year
	month	=> 1,
	day	=> 22,
	quarter	=> 1,
	day_of_quarter	=> 22,
	quarter_length	=> 90,
    },
    {
	year	=> 1501,	# Not a leap year
	month	=> 3,
	day	=> 1,
	quarter	=> 1,
	day_of_quarter	=> 60,
	quarter_length	=> 90,
    },
    {
	year	=> 1501,	# Not a leap year
	month	=> 4,
	day	=> 1,
	quarter	=> 2,
	day_of_quarter	=> 1,
	quarter_length	=> 91,
    },
) {

    my $dt = DateTime::Calendar::Julian->new(
	year	=> $info->{year},
	month	=> $info->{month} || 1,
	day	=> $info->{day} || 1,
    );

    cmp_ok $dt->quarter, '==', $info->{quarter},
	sprintf '%s (Julian) quarter is %d', $dt->ymd, $info->{quarter};

    cmp_ok $dt->day_of_quarter, '==', $info->{day_of_quarter},
	sprintf '%s (Julian) day_of_quarter is %d', $dt->ymd,
	    $info->{day_of_quarter};

    cmp_ok $dt->quarter_length, '==', $info->{quarter_length},
	sprintf '%s (Julian) quarter_length is %d', $dt->ymd,
	    $info->{quarter_length};

}

done_testing;

1;

# ex: set textwidth=72 :
