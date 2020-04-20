#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use DateTime;
use Date::Holidays::UA qw(:all);

my $ua = Date::Holidays::UA->new();
my $ua_en = Date::Holidays::UA->new({language => 'en'});
my $test_days_list = [
    {name => 'New Year in 2019', year => 2019, month => 1, day => 1, holiday_name => 'New Year', holiday_local_name => 'Новий рік', result => 1},
    {name => 'New Year in 2011', year => 2011, month => 1, day => 1, holiday_name => 'New Year', holiday_local_name => 'Новий рік', result => 1},
    {name => 'New Year at weekend in 2011', year => 2011, month => 1, day => 3, holiday_name => 'New Year', holiday_local_name => 'Новий рік', result => 1},
    {name => 'Orthodox Christmas in 2019', year => 2019, month => 1, day => 7, holiday_name => 'Orthodox Christmas day', holiday_local_name => 'Різдво Христове', result => 1},
    {name => 'Women day in 2019', year => 2019, month => 3, day => 8, holiday_name => 'Women Day', holiday_local_name => 'Міжнародний жіночий день', result => 1},
    {name => 'Women day at weekend in 2014', year => 2014, month => 3, day => 10, holiday_name => 'Women Day', holiday_local_name => 'Міжнародний жіночий день', result => 1},
    {name => 'Labour day 1 in 2019', year => 2019, month => 5, day => 1, holiday_name => 'Labour Day', holiday_local_name => 'День праці', result => 1},
    {name => 'Labour day in 2010', year => 2010, month => 5, day => 1, holiday_name => 'Labour Day', holiday_local_name => 'День праці', result => 1},
    {name => 'Labour day in 2010', year => 2010, month => 5, day => 2, holiday_name => 'Labour Day', holiday_local_name => 'День праці', result => 1},
    {name => 'Labour day in 2010', year => 2010, month => 5, day => 3, holiday_name => 'Labour Day', holiday_local_name => 'День праці', result => 1},
    {name => 'Labour day in 2010', year => 2010, month => 5, day => 4, holiday_name => 'Labour Day', holiday_local_name => 'День праці', result => 1},
    {name => 'Labour day in 2010 false test', year => 2010, month => 5, day => 5, result => 0},
    {name => 'Labour day in 2011', year => 2010, month => 5, day => 1, holiday_name => 'Labour Day', holiday_local_name => 'День праці', result => 1},
    {name => 'Labour day in 2011', year => 2010, month => 5, day => 2, holiday_name => 'Labour Day', holiday_local_name => 'День праці', result => 1},
    {name => 'Labour day 2 in 2019 false test', year => 2019, month => 5, day => 2, result => 0},
    {name => 'Victory day in 2019', year => 2019, month => 5, day => 9, holiday_name => 'Victory Day', holiday_local_name => 'День перемоги над нацизмом у Другій світовій війні', result => 1},
    {name => 'Constitution day in 2019', year => 2019, month => 6, day => 28, holiday_name => 'Constitution Day', holiday_local_name => 'День Конституції України', result => 1},
    {name => 'Independence day in 2019', year => 2019, month => 8, day => 24, holiday_name => 'Independence Day', holiday_local_name => 'День незалежності України', result => 1},
    {name => 'Independence day at weekend in 2019', year => 2019, month => 8, day => 26, holiday_name => 'Independence Day', holiday_local_name => 'День незалежності України', result => 1},
    {name => 'Defender Of Ukraine day in 2019', year => 2019, month => 10, day => 14, holiday_name => 'Defender Of Ukraine day', holiday_local_name => 'День захисника України', result => 1},
    {name => 'Defender of Ukraine day in 2010 false test', year => 2010, month => 10, day => 14, result => 0},
    {name => 'Catholic Christmas day in 2019', year => 2019, month => 12, day => 25, holiday_name => 'Catholic Christmas day', holiday_local_name => 'Різдво Христове(католицьке)', result => 1},
    {name => 'Catholic Christmas day in 2017 false test', year => 2017, month => 12, day => 25, result => 0},
    {name => 'Orthodox Easter day 1 in 2018', year => 2018, month => 4, day => 8, holiday_name => 'Orthodox Easter Day', holiday_local_name => 'Великдень', result => 1},
    {name => 'Orthodox Easter day 2 in 2018', year => 2018, month => 4, day => 9, holiday_name => 'Orthodox Easter Day', holiday_local_name => 'Великдень', result => 1},
    {name => 'Orthodox Easter day 1 in 2014', year => 2014, month => 4, day => 20, holiday_name => 'Orthodox Easter Day', holiday_local_name => 'Великдень', result => 1},
    {name => 'Orthodox Easter day 2 in 2014', year => 2014, month => 4, day => 21, holiday_name => 'Orthodox Easter Day', holiday_local_name => 'Великдень', result => 1},
    {name => 'Orthodox Easter day 1 in 2019', year => 2019, month => 4, day => 28, holiday_name => 'Orthodox Easter Day', holiday_local_name => 'Великдень', result => 1},
    {name => 'Orthodox Easter day 2 in 2019', year => 2019, month => 4, day => 29, holiday_name => 'Orthodox Easter Day', holiday_local_name => 'Великдень', result => 1},
    {name => 'Orthodox Pentecost day 1 in 2018', year => 2018, month => 5, day => 27, holiday_name => 'Orthodox Pentecost Day', holiday_local_name => 'Трійця', result => 1},
    {name => 'Orthodox Pentecost day 2 in 2018', year => 2018, month => 5, day => 28, holiday_name => 'Orthodox Pentecost Day', holiday_local_name => 'Трійця', result => 1},
    {name => 'Orthodox Pentecost day 1 in 2019', year => 2019, month => 6, day => 16, holiday_name => 'Orthodox Pentecost Day', holiday_local_name => 'Трійця', result => 1},
    {name => 'Orthodox Pentecost day 2 in 2019', year => 2019, month => 6, day => 17, holiday_name => 'Orthodox Pentecost Day', holiday_local_name => 'Трійця', result => 1},
];

for my $test_day(@{$test_days_list}) {
    t_day($test_day);
}

my $test_year_list = [
    {
        name => 'Holidays in 2010',
        year => 2010,
        result => {
          '0308' => 'Women Day',
          '0524' => 'Orthodox Pentecost Day',
          '0503' => 'Labour Day',
          '0501' => 'Labour Day',
          '0404' => 'Orthodox Easter Day',
          '0509' => 'Victory Day',
          '0405' => 'Orthodox Easter Day',
          '0824' => 'Independence Day',
          '0628' => 'Constitution Day',
          '0504' => 'Labour Day',
          '0107' => 'Orthodox Christmas day',
          '0523' => 'Orthodox Pentecost Day',
          '0101' => 'New Year',
          '0502' => 'Labour Day',
          '0510' => 'Victory Day'
        },
        local_result => {
          '0524' => 'Трійця',
          '0501' => 'День праці',
          '0503' => 'День праці',
          '0404' => 'Великдень',
          '0628' => 'День Конституції України',
          '0509' => 'День перемоги над нацизмом у Другій світовій війні',
          '0101' => 'Новий рік',
          '0502' => 'День праці',
          '0308' => 'Міжнародний жіночий день',
          '0824' => 'День незалежності України',
          '0523' => 'Трійця',
          '0510' => 'День перемоги над нацизмом у Другій світовій війні',
          '0405' => 'Великдень',
          '0107' => 'Різдво Христове',
          '0504' => 'День праці'
        }
    },
    {
        name => 'Holidays in 2019',
        year => 2019,
        result => {
          '0428' => 'Orthodox Easter Day',
          '0107' => 'Orthodox Christmas day',
          '0501' => 'Labour Day',
          '0308' => 'Women Day',
          '0628' => 'Constitution Day',
          '0509' => 'Victory Day',
          '0616' => 'Orthodox Pentecost Day',
          '1014' => 'Defender Of Ukraine day',
          '0617' => 'Orthodox Pentecost Day',
          '0429' => 'Orthodox Easter Day',
          '0826' => 'Independence Day',
          '0101' => 'New Year',
          '0824' => 'Independence Day',
          '1225' => 'Catholic Christmas day'
        },
        local_result => {
          '0501' => 'День праці',
          '0308' => 'Міжнародний жіночий день',
          '0107' => 'Різдво Христове',
          '1014' => 'День захисника України',
          '0617' => 'Трійця',
          '0429' => 'Великдень',
          '0428' => 'Великдень',
          '0509' => 'День перемоги над нацизмом у Другій світовій війні',
          '0101' => 'Новий рік',
          '1225' => 'Різдво Христове(католицьке)',
          '0628' => 'День Конституції України',
          '0824' => 'День незалежності України',
          '0826' => 'День незалежності України',
          '0616' => 'Трійця'
        }
    }
];

for my $test_year(@{$test_year_list}) {
    t_year($test_year);
}

done_testing();

sub t_day {
    my $t = shift;
    my $dt = DateTime->new(year => $t->{year}, month => $t->{month}, day => $t->{day});

    is(is_holiday($t->{year}, $t->{month}, $t->{day}), $t->{result}, $t->{name});
    is(is_ua_holiday($t->{year}, $t->{month}, $t->{day}), $t->{holiday_local_name}, $t->{name});
    is(is_ua_holiday($t->{year}, $t->{month}, $t->{day},{language => 'en'}), $t->{holiday_name}, $t->{name});
    is(is_holiday_dt($dt), $t->{result}, $t->{name});
    is($ua_en->is_holiday($t->{year}, $t->{month}, $t->{day}), $t->{result}, $t->{name});
    is($ua->is_holiday($t->{year}, $t->{month}, $t->{day}), $t->{result}, $t->{name});
    is($ua_en->is_ua_holiday($t->{year}, $t->{month}, $t->{day}), $t->{holiday_name}, $t->{name});
    is($ua->is_ua_holiday($t->{year}, $t->{month}, $t->{day}), $t->{holiday_local_name}, $t->{name});
    is($ua_en->is_holiday_dt($dt), $t->{result}, $t->{name});
    is($ua->is_holiday_dt($dt), $t->{result}, $t->{name});
}

sub t_year {
    my $t = shift;

    ok(holidays_dt($t->{year}), $t->{name});
    ok(holidays_dt($t->{year},{language => 'en'}), $t->{name});

    ok(ua_holidays($t->{year}), $t->{name});
    ok(ua_holidays($t->{year},{language => 'en'}), $t->{name});

    ok(holidays($t->{year}), $t->{name});
    ok(holidays($t->{year},{language => 'en'}), $t->{name});

    ok($ua->ua_holidays($t->{year}), $t->{name});
    ok($ua_en->ua_holidays($t->{year}), $t->{name});

    ok($ua->holidays($t->{year}), $t->{name});
    ok($ua_en->holidays($t->{year}), $t->{name});
    
    ok(eq_hash(ua_holidays($t->{year}), $t->{local_result}), $t->{name});
    ok(eq_hash($ua->ua_holidays($t->{year}), $t->{local_result}), $t->{name});
    ok(eq_hash($ua->holidays($t->{year}), $t->{local_result}), $t->{name});
    ok(eq_hash(ua_holidays($t->{year},{language => 'en'}), $t->{result}), $t->{name});
    ok(eq_hash($ua_en->holidays($t->{year}), $t->{result}), $t->{name});
    ok(eq_hash($ua_en->ua_holidays($t->{year}), $t->{result}), $t->{name});
}