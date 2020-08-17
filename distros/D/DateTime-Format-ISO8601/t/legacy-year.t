# Copyright (C) 2005  Joshua Hoblitt
use strict;
use warnings;

use Test2::V0;

use DateTime::Format::ISO8601;

{
    is(
        DateTime::Format::ISO8601->DefaultLegacyYear, 1,
        'default legacy year is 1'
    );
    my $iso_parser = DateTime::Format::ISO8601->new;
    is( $iso_parser->legacy_year, 1, 'legacy_year is 1' );
}

for my $n ( 0, 1, undef ) {
    DateTime::Format::ISO8601->DefaultLegacyYear($n);
    is(
        DateTime::Format::ISO8601->DefaultLegacyYear, $n,
        'default legacy was set'
    );
    my $iso_parser = DateTime::Format::ISO8601->new;
    is( $iso_parser->legacy_year, $n, 'set legacy year' );
}

for my $n ( -3 .. -1, 2 .. 4 ) {
    like(
        dies { DateTime::Format::ISO8601->DefaultLegacyYear($n) },
        qr/Validation failed for type named Bool/,
        'set legacy year to invalid value',
    );
}

# restore default legacy year behavior
DateTime::Format::ISO8601->DefaultLegacyYear(1);

for my $n ( 0, 1, undef ) {
    my $iso_parser = DateTime::Format::ISO8601->new( legacy_year => $n );
    isa_ok( $iso_parser, 'DateTime::Format::ISO8601' );
    is( $iso_parser->legacy_year, $n, 'pass legacy year to constructor' );

    $iso_parser = DateTime::Format::ISO8601->new->set_legacy_year($n);
    is( $iso_parser->legacy_year, $n, 'call set_legacy_year on object' );
}

for my $n ( -3 .. -1, 2 .. 4 ) {
    like(
        dies { DateTime::Format::ISO8601->new( legacy_year => $n ) },
        qr/Validation failed for type named Bool/,
        'pass invalid legacy year to constructor',
    );

    like(
        dies { DateTime::Format::ISO8601->new->set_legacy_year($n) },
        qr/Validation failed for type named Bool/,
        'pass invalid legacy year to set_legacy_year',
    );
}

for my $year ( 0 .. 99 ) {
    $year *= 100;    # [0, 9900], step 100
    my $iso_parser = DateTime::Format::ISO8601->new(
        legacy_year   => 0,
        base_datetime => DateTime->new( year => $year ),
    );

    for my $tdy ( 0 .. 9 ) {
        $tdy *= 10;    # [0, 90], step 10
        $tdy = sprintf( '%02d', $tdy );
        my $dt = $iso_parser->parse_datetime("-$tdy");
        is(
            $dt->year,
            sprintf(
                '%d', $iso_parser->base_datetime->strftime('%C') . $tdy
            ),
            "parses $tdy based on base_datetime with year $year",
        );
    }
}

done_testing();
