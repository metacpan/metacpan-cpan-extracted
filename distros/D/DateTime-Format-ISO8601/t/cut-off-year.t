# Copyright (C) 2005  Joshua Hoblitt
use strict;
use warnings;

use Test2::V0;

use DateTime::Format::ISO8601;

# DefaultCutOffYear()

{
    is(
        DateTime::Format::ISO8601->DefaultCutOffYear, 49,
        'class default DefaultCutOffYear()'
    );
    is(
        DateTime::Format::ISO8601->new->cut_off_year, 49,
        'object default DefaultCutOffYear()'
    );
}

for my $n ( 0 .. 99 ) {
    DateTime::Format::ISO8601->DefaultCutOffYear($n);

    is(
        DateTime::Format::ISO8601->DefaultCutOffYear,
        $n,
        "DefaultCutOffYear == $n",
    );
    is(
        DateTime::Format::ISO8601->new->cut_off_year,
        $n,
        "new->cut_off_year == $n",
    );
}

for my $n (
    -3 .. -1,
    100 .. 102
) {
    like(
        dies { DateTime::Format::ISO8601->DefaultCutOffYear($n) },
        qr/Validation failed for type named CutOffYear/,
        'invalid cutoff year',
    );
}

# restore default cut off year behavior
DateTime::Format::ISO8601->DefaultCutOffYear(49);

# set_cut_off_year()

for my $n ( 0 .. 99 ) {
    {
        my $iso_parser = DateTime::Format::ISO8601->new( cut_off_year => $n );
        isa_ok(
            $iso_parser,
            ['DateTime::Format::ISO8601'],
            "made object with cut_off_year = $n"
        );
        is( $iso_parser->cut_off_year, $n, "cut_off_year returns $n" );
    }

    {
        my $iso_parser = DateTime::Format::ISO8601->new->set_cut_off_year($n);
        is( $iso_parser->cut_off_year, $n, "set_cut_off_year to $n" );
    }
}

for my $n ( -3 .. -1, 100 .. 102 ) {
    like(
        dies { DateTime::Format::ISO8601->new( cut_off_year => $n ) },
        qr/Validation failed for type named CutOffYear/,
        'cut_off_year value out of range',
    );

    like(
        dies { DateTime::Format::ISO8601->new->set_cut_off_year($n) },
        qr/Validation failed for type named CutOffYear/,
        'set_cut_off_year() value out of range',
    );
}

# parse_datetime() as a class method

for my $n ( 0 .. 99 ) {
    DateTime::Format::ISO8601->DefaultCutOffYear($n);

    for my $i ( 0 .. DateTime::Format::ISO8601->DefaultCutOffYear ) {
        my $tdy = sprintf( '%02d', $i );
        my $dt  = DateTime::Format::ISO8601->parse_datetime("-$tdy");
        is( $dt->year, "20$tdy", "year is 20$tdy" );
    }

    for my $i ( ( DateTime::Format::ISO8601->DefaultCutOffYear + 1 ) .. 99 ) {
        my $tdy = sprintf( '%02d', $i );
        my $dt  = DateTime::Format::ISO8601->parse_datetime("-$tdy");
        is( $dt->year, "19$tdy", "year is 19$tdy" );
    }
}

# parse_datetime() as an object method

for my $n ( 0 .. 99 ) {
    my $iso_parser = DateTime::Format::ISO8601->new( cut_off_year => $n );

    for my $i ( 0 .. $iso_parser->cut_off_year ) {
        my $tdy = sprintf( '%02d', $i );
        my $dt  = $iso_parser->parse_datetime("-$tdy");
        is( $dt->year, "20$tdy", "year is 20$tdy" );
    }

    for my $i ( ( $iso_parser->cut_off_year + 1 ) .. 99 ) {
        my $tdy = sprintf( '%02d', $i );
        my $dt  = $iso_parser->parse_datetime("-$tdy");
        is( $dt->year, "19$tdy", "year is 19$tdy" );
    }
}

done_testing();
