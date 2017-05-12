
use strict;
use warnings;

use utf8;
use DateTime;
use Test::More tests => 211;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

BEGIN {
    use_ok('Date::Holidays::PL',
        qw(
            pl_holidays is_pl_holiday
            pl_holidays_dt is_pl_holiday_dt
        )
    );
}

my %FixedHolidays = (
    # New Year's Day
    '0101' => 'Nowy Rok',
    # Epiphany (1951-1959, 2011+ only)
    '0106' => 'Trzech Króli',
    # Labor Day
    '0501' => 'Święto Państwowe',
    # Constitution Day ( since 1990 )
    '0503' => 'Święto Narodowe Trzeciego Maja',
    # Polish Committee of National Liberation Manifesto (1951-1989 only)
    '0722' => 'Święto Odrodzenia Polski',
    # Assumption of the Blessed Virgin Mary ( 1951-1959, 1989+ )
    '0815' => 'Wniebowzięcie Najświętszej Maryi Panny',
    # All Saints' Day
    '1101' => 'Wszystkich Świętych',
    # Independence Day ( since 1989 )
    '1111' => 'Narodowe Święto Niepodległości',
    # Christmas Day
    '1225' => 'pierwszy dzień Bożego Narodzenia',
    # Boxing Day
    '1226' => 'drugi dzień Bożego Narodzenia',
);
my %MovableFeasts = (
    easter_sunday => 'pierwszy dzień Wielkanocy',
    easter_monday => 'drugi dzień Wielkanocy',
    pentecoste_sunday => 'pierwszy dzień Zielonych Świątek',
    corpus_christi => 'dzień Bożego Ciała',
);

eval {
    pl_holidays(1950);
};
like( $@, qr/between 1951 and 9999/, "1950 is outside of range for pl_holidays");

eval {
    pl_holidays_dt(1950);
};
like( $@, qr/between 1951 and 9999/, "...and for pl_holidays_dt");

eval {
    is_pl_holiday(1950, 1, 1);
};
like( $@, qr/between 1951 and 9999/, "1950 is outside of range for is_pl_holiday");

eval {
    is_pl_holiday_dt(DateTime->new(year => 1950, month => 1, day => 1));
};
like( $@, qr/between 1951 and 9999/, "...and for is_pl_holiday_dt");

eval {
    pl_holidays(10000);
};
ok( $@, "10000 is outside of range as well");

eval {
    is_pl_holiday(2010, 13, 32);
};
like( $@, qr/Date 2010-13-32 is invalid/, "date validation works");

my %fixed_holidays = (
    1951 => [qw( 0101 0106 0501 0722 0815 1101 1225 1226)],
    1960 => [qw( 0101 0501 0722 1101 1225 1226)],
    1989 => [qw( 0101 0501 0722 0815 1101 1111 1225 1226)],
    1990 => [qw( 0101 0501 0503 0815 1101 1111 1225 1226)],
    2011 => [qw( 0101 0106 0501 0503 0815 1101 1111 1225 1226)],
);

my %movable_feasts = (
    1951 => {
        easter_sunday => '0325',
        easter_monday => '0326',
        pentecoste_sunday => '0513',
        corpus_christi => '0524',
    },
    1960 => {
        easter_sunday => '0417',
        easter_monday => '0418',
        pentecoste_sunday => '0605',
        corpus_christi => '0616',
    },
    1989 => {
        easter_sunday => '0326',
        easter_monday => '0327',
        pentecoste_sunday => '0514',
        corpus_christi => '0525',
    },
    1990 => {
        easter_sunday => '0415',
        easter_monday => '0416',
        pentecoste_sunday => '0603',
        corpus_christi => '0614',
    },
    2011 => {
        easter_sunday => '0424',
        easter_monday => '0425',
        pentecoste_sunday => '0612',
        corpus_christi => '0623',
    },
);
my @movable_feasts_names_ordered = qw(
    easter_sunday easter_monday
    pentecoste_sunday corpus_christi
);


for my $year ( sort keys %fixed_holidays ) {
    my $hy = pl_holidays($year);
    my $hy_dt = pl_holidays_dt($year);
    my $hy_we = pl_holidays($year, { WEEKENDS => 0 });
    my $hy_dt_we = pl_holidays_dt($year, { WEEKENDS => 0 });

    is( keys %$hy, @{$fixed_holidays{$year}} + keys %{$movable_feasts{$year}},
        "$year: correct number of holidays returned:". scalar keys %$hy
    );
    for my $md ( @{$fixed_holidays{$year}} ) {
        my ($m, $d) = unpack "A2A2", $md;
        my $dt = DateTime->new(
            year => $year,
            month => $m,
            day => $d
        );
        is($hy->{$md}, $FixedHolidays{$md},
            "$year-$m-$d: $FixedHolidays{$md}"
        );
        is($hy_dt->{$hy->{$md}}->year, $year,
            "...DateTime object has correct year $year"
        );
        is(DateTime->compare($hy_dt->{$hy->{$md}}, $dt), 0,
            "...DateTime object has correct month-day $md"
        );

        if ( $dt->day_of_week >= 6 ) {
            ok(! exists $hy_we->{$md},
                "...and weekend holiday filtered: ". $dt->strftime('%A')
            );
            ok(! exists $hy_dt_we->{$hy->{$md}},
                "...also for pl_holidays_dt"
            );
        }
    }
    for my $feast ( @movable_feasts_names_ordered ) {
        my ($m, $d) = unpack "A2A2", $movable_feasts{$year}->{$feast};
        my $dt = DateTime->new(
            year => $year,
            month => $m,
            day => $d
        );

        my $ih = is_pl_holiday($year, $m, $d);
        my $ih_dt = is_pl_holiday_dt( $dt );

        is($ih, $MovableFeasts{$feast},
            "$year-$m-$d: is a holiday ($ih)"
        );
        is($ih, $ih_dt,
            "...is_pl_holidays_dt accepts DateTime object and works"
        );

        if ( $dt->day_of_week >= 6 ) {
            ok(! exists $hy_we->{"$m$d"},
                "...and weekend holiday filtered: ". $dt->strftime('%A')
            );
            ok(! exists $hy_dt_we->{$hy->{"$m$d"}},
                "...also for pl_holidays_dt"
            );
        }
    }
}

