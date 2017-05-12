#!perl

use strict;
use Test::More;

use Data::Dumper;
use DateTime;
use Calendar::Model;

my $cal = Calendar::Model->new(selected_date=>DateTime->new(day=>3, month=>1, year=>2013));

is_deeply($cal->columns, [
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday'
        ]);

is($cal->first_entry_day->dmy,'30-12-2012');

is($cal->month, 1);

is($cal->year, 2013);

is($cal->previous_month, 12);

is($cal->previous_year, 2012);

is($cal->next_month, 2);

is($cal->next_year, 2013);

my $weeks = $cal->weeks;

my $day2 = $weeks->[0][2];

is ($day2->dow_name, 'Tuesday', '2nd day is tuesday');

is ($day2->day_of_week => 3, 'day of week');

is ($day2->dd => '01');

is ($day2->yyyy => '2013');

is ($cal->month_name, 'January', 'month name');

is ($cal->month_name('next'), 'February', 'next month name');

is ($cal->month_name('previous'), 'December', 'prev month name');

is ('02-02-2013' => $cal->last_entry_day->dmy, 'last entry day');

is_deeply([
          bless( {
                   'mm' => '12',
                   'dow_name' => 'Sunday',
                   'day_of_week' => 1,
                   'dd' => '30',
                   'yyyy' => '2012',
                   'dmy' => '30-12-2012'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '12',
                   'dow_name' => 'Monday',
                   'day_of_week' => 2,
                   'dd' => '31',
                   'yyyy' => '2012',
                   'dmy' => '31-12-2012'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Tuesday',
                   'day_of_week' => 3,
                   'dd' => '01',
                   'yyyy' => '2013',
                   'dmy' => '01-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Wednesday',
                   'day_of_week' => 4,
                   'dd' => '02',
                   'yyyy' => '2013',
                   'dmy' => '02-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Thursday',
                   'day_of_week' => 5,
                   'dd' => '03',
                   'yyyy' => '2013',
                   'dmy' => '03-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Friday',
                   'day_of_week' => 6,
                   'dd' => '04',
                   'yyyy' => '2013',
                   'dmy' => '04-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Saturday',
                   'day_of_week' => 7,
                   'dd' => '05',
                   'yyyy' => '2013',
                   'dmy' => '05-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Sunday',
                   'day_of_week' => 1,
                   'dd' => '06',
                   'yyyy' => '2013',
                   'dmy' => '06-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Monday',
                   'day_of_week' => 2,
                   'dd' => '07',
                   'yyyy' => '2013',
                   'dmy' => '07-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Tuesday',
                   'day_of_week' => 3,
                   'dd' => '08',
                   'yyyy' => '2013',
                   'dmy' => '08-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Wednesday',
                   'day_of_week' => 4,
                   'dd' => '09',
                   'yyyy' => '2013',
                   'dmy' => '09-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Thursday',
                   'day_of_week' => 5,
                   'dd' => '10',
                   'yyyy' => '2013',
                   'dmy' => '10-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Friday',
                   'day_of_week' => 6,
                   'dd' => '11',
                   'yyyy' => '2013',
                   'dmy' => '11-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Saturday',
                   'day_of_week' => 7,
                   'dd' => '12',
                   'yyyy' => '2013',
                   'dmy' => '12-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Sunday',
                   'day_of_week' => 1,
                   'dd' => '13',
                   'yyyy' => '2013',
                   'dmy' => '13-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Monday',
                   'day_of_week' => 2,
                   'dd' => '14',
                   'yyyy' => '2013',
                   'dmy' => '14-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Tuesday',
                   'day_of_week' => 3,
                   'dd' => '15',
                   'yyyy' => '2013',
                   'dmy' => '15-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Wednesday',
                   'day_of_week' => 4,
                   'dd' => '16',
                   'yyyy' => '2013',
                   'dmy' => '16-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Thursday',
                   'day_of_week' => 5,
                   'dd' => '17',
                   'yyyy' => '2013',
                   'dmy' => '17-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Friday',
                   'day_of_week' => 6,
                   'dd' => '18',
                   'yyyy' => '2013',
                   'dmy' => '18-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Saturday',
                   'day_of_week' => 7,
                   'dd' => '19',
                   'yyyy' => '2013',
                   'dmy' => '19-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Sunday',
                   'day_of_week' => 1,
                   'dd' => '20',
                   'yyyy' => '2013',
                   'dmy' => '20-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Monday',
                   'day_of_week' => 2,
                   'dd' => '21',
                   'yyyy' => '2013',
                   'dmy' => '21-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Tuesday',
                   'day_of_week' => 3,
                   'dd' => '22',
                   'yyyy' => '2013',
                   'dmy' => '22-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Wednesday',
                   'day_of_week' => 4,
                   'dd' => '23',
                   'yyyy' => '2013',
                   'dmy' => '23-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Thursday',
                   'day_of_week' => 5,
                   'dd' => '24',
                   'yyyy' => '2013',
                   'dmy' => '24-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Friday',
                   'day_of_week' => 6,
                   'dd' => '25',
                   'yyyy' => '2013',
                   'dmy' => '25-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Saturday',
                   'day_of_week' => 7,
                   'dd' => '26',
                   'yyyy' => '2013',
                   'dmy' => '26-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Sunday',
                   'day_of_week' => 1,
                   'dd' => '27',
                   'yyyy' => '2013',
                   'dmy' => '27-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Monday',
                   'day_of_week' => 2,
                   'dd' => '28',
                   'yyyy' => '2013',
                   'dmy' => '28-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Tuesday',
                   'day_of_week' => 3,
                   'dd' => '29',
                   'yyyy' => '2013',
                   'dmy' => '29-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Wednesday',
                   'day_of_week' => 4,
                   'dd' => '30',
                   'yyyy' => '2013',
                   'dmy' => '30-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '01',
                   'dow_name' => 'Thursday',
                   'day_of_week' => 5,
                   'dd' => '31',
                   'yyyy' => '2013',
                   'dmy' => '31-01-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '02',
                   'dow_name' => 'Friday',
                   'day_of_week' => 6,
                   'dd' => '01',
                   'yyyy' => '2013',
                   'dmy' => '01-02-2013'
                 }, 'Calendar::Model::Day' ),
          bless( {
                   'mm' => '02',
                   'dow_name' => 'Saturday',
                   'day_of_week' => 7,
                   'dd' => '02',
                   'yyyy' => '2013',
                   'dmy' => '02-02-2013'
                 }, 'Calendar::Model::Day' )
        ], $cal->as_list);

my $dt = DateTime->new(day=>31, month=>1, year=>2013);
is($dt, $cal->get_day($dt)->to_DateTime, 'get day from date');

done_testing();
