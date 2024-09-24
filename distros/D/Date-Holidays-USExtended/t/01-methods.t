#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Date::Holidays::USExtended';

my $dh = new_ok 'Date::Holidays::USExtended';

my %holidays = ( # 2024
  '0101' => "New Year's Day",
  '0115' => 'Martin Luther King Jr.',
  '0214' => "Valentine's Day",
  '0219' => "President's Day",
  '0317' => "St. Patrick's Day",
  '0331' => 'Easter',
  '0505' => 'Cinco de Mayo',
  '0512' => "Mother's Day",
  '0527' => 'Memorial Day',
  '0614' => 'Flag Day',
  '0616' => "Father's Day",
  '0619' => 'Juneteenth',
  '0704' => 'Independence Day',
  '0902' => 'Labor Day',
  '1014' => "Columbus; Indigenous Peoples' Day",
  '1031' => 'Halloween',
  '1111' => "Veteran's Day",
  '1128' => 'Thanksgiving',
  '1224' => 'Christmas Eve',
  '1225' => 'Christmas',
  '1231' => "New Year's Eve",
);

subtest holidays => sub {
    my $got = $dh->holidays(2024);
    is_deeply $got, \%holidays, 'holidays 2024';
};

subtest us_holidays => sub {
    my $expect = {};
    # build what is expected from the literal holidays hash
    for my $key (keys %holidays) {
        my @day = ( $key =~ /^(\d\d)(\d\d)$/g );
        $expect->{ $day[0] + 0 }{ $day[1] + 0 } = $holidays{$key};
    }
    $expect->{4} = $expect->{8} = {};
    my $us_holidays = $dh->us_holidays(2024);
    is_deeply $us_holidays, $expect, 'us_holidays 2024';
    is $us_holidays->{3}{31}, 'Easter', 'easter 2024';

    my $got = $dh->us_holidays(2023);
    is $got->{4}{9}, 'Easter', 'easter 2023';
    is $got->{4}{9}, $us_holidays->{3}{31}, 'easters';
};

subtest is_holiday => sub {
    for my $month ('01' .. '12') {
        for my $day ('01' .. '31') {
            my $is_holiday = exists $holidays{ $month . $day };
            my $got = $dh->is_holiday(2024, $month + 0, $day + 0);
            if ($is_holiday) {
                ok $got, "$month$day is_holiday";
            }
        }
    }
};

done_testing();

