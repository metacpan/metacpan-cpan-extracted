#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 18;
use DateTime;

use t::lib::helper;

use DateTime::Format::Flexible;

my $curr_year = DateTime->now->year;

# http://www.dummies.com/how-to/content/mastering-the-calendar-and-dates-in-german.html
# http://german.about.com/library/anfang/blanfang12b.htm
t::lib::helper::run_tests(
    [ european => 1 ],
    "20. Feb am Mittag => $curr_year-02-20T12:00:00",
    "20. Feb um Mitternacht => $curr_year-02-20T00:00:00",
    'Montag, 6. Dez 2010 => 2010-12-06T00:00:00',
    "am vierzehnten Juni => $curr_year-06-14T00:00:00",
    'am 14. Juni 2001 => 2001-06-14T00:00:00',
    '1. Januar 2000 => 2000-01-01T00:00:00',
    '10. Juni 1999 => 1999-06-10T00:00:00',
    '20. März 1888 => 1888-03-20T00:00:00',
    "am ersten Mai => $curr_year-05-01T00:00:00",
    'am 1. Mai 2001 => 2001-05-01T00:00:00',
    '14.7.01 => 2001-07-14T00:00:00',
    '1.5.01 => 2001-05-01T00:00:00',
);

{
    my $dt = DateTime::Format::Flexible->parse_datetime( '1. 1. 2000', european => 1 );
    is ( $dt->datetime, '2000-01-01T00:00:00', '1. 1. 2000 => 2000-01-01T00:00:00' );
}
{
    my $dt = DateTime::Format::Flexible->parse_datetime( '2. 4. 1999', european => 1 );
    is ( $dt->datetime, '1999-04-02T00:00:00', '2. 4. 1999 => 1999-04-02T00:00:00' );
}
{
    my $dt = DateTime::Format::Flexible->parse_datetime( '3. 5. 1617', european => 1 );
    is ( $dt->datetime, '1617-05-03T00:00:00', '3. 5. 1617 => 1617-05-03T00:00:00' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime( '-unendlich' );
    ok ( $dt->is_infinite() , '-unendlich is infinite' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime( 'unendlich' );
    ok ( $dt->is_infinite() , 'unendlich is infinite' );
}

{
    my ( $base_dt ) = DateTime::Format::Flexible->parse_datetime( '2005-06-07T13:14:15' );
    DateTime::Format::Flexible->base( $base_dt );
    my $dt = DateTime::Format::Flexible->parse_datetime( 'vor 3 Jahren' );
    is( $dt->datetime, '2002-06-07T13:14:15', 'vor 3 Jahren => 3 years ago' );

}
