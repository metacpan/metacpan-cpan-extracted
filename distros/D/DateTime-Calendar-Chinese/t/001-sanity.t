use utf8;
use strict;
use Test::More tests => 38;
use_ok("DateTime::Calendar::Chinese");

my $cc;
# 1 Jan 2004 is cycle (78) year 20 (Gui-Wei [Sheep]) month 12, day 10

my $dt = DateTime->new(year => 2004, month => 1, day => 1, time_zone => 'Asia/Taipei');
$cc    = DateTime::Calendar::Chinese->from_object(object => $dt);

can_ok($cc, "cycle", "cycle_year", "month", "leap_month", "day",
      "utc_rd_values");
check_cc($cc, 78, 20, 12, 10, $dt->day_of_week, ($dt->utc_rd_values())[0],
         "ç¸", "æª", 'gui3', 'wei4', 'sheep',
        );

my $dt2 = DateTime->new(year => 2003, month => 11, day => 25, time_zone => 'Asia/Taipei');

$cc->set(month => 11, day => 3);
check_cc($cc, 78, 20, 11, 3, $dt2->day_of_week, ($dt2->utc_rd_values())[0],
         "ç¸", "æª", 'gui3', 'wei4', 'sheep',
        );

$cc    = DateTime::Calendar::Chinese->new(
    cycle      => 78,
    cycle_year => 20,
    month      => 12,
    day        => 10,
    time_zone  => 'Asia/Taipei'
);
check_cc($cc, 78, 20, 12, 10, $dt->day_of_week, ($dt->utc_rd_values())[0],
         "ç¸", "æª", 'gui3', 'wei4', 'sheep',
        );


sub check_cc
{
    my($cc, $cc_cycle, $cc_cycle_year, $cc_month, $cc_day, $cc_day_of_week, $cc_rd_days,
       $cc_celestial, $cc_terrestrial, $cc_celestial_py, $cc_terrestrial_py,
       $cc_zodiac_animal) = @_;

    isa_ok($cc, "DateTime::Calendar::Chinese");
    is($cc->cycle,
        $cc_cycle,
        "cycle should be $cc_cycle. value is " . $cc->cycle);
    is($cc->cycle_year,
        $cc_cycle_year,
        "cycle_year should be $cc_cycle_year. value is " . $cc->cycle_year);
    is($cc->month,
        $cc_month,
        "month should be $cc_month. value is " . $cc->month);
    is($cc->day,
        $cc_day,
        "day should be $cc_day. value is " . $cc->day);
    is($cc->day_of_week,
        $cc_day_of_week,
        "day_of_week should be $cc_day_of_week. value is " . $cc->day_of_week);

    is($cc->celestial_stem,
        $cc_celestial,
        "celestial_stem should be $cc_celestial. value is " . $cc->celestial_stem);
    is($cc->terrestrial_branch,
        $cc_terrestrial,
        "terrestrial_branch should be $cc_terrestrial. value is " . $cc->terrestrial_branch);
    is($cc->celestial_stem_py,
        $cc_celestial_py,
        "celestial_stem_py should be $cc_celestial_py. value is " . $cc->celestial_stem_py);
    is($cc->terrestrial_branch_py,
        $cc_terrestrial_py,
        "terrestrial_branch should be $cc_terrestrial_py. value is " . $cc->terrestrial_branch_py);
    is($cc->zodiac_animal,
        $cc_zodiac_animal,
        "zodiac_animal should be $cc_zodiac_animal. value is " . $cc->zodiac_animal);

    my @vals = $cc->utc_rd_values();
    is($vals[0], $cc_rd_days, "utc_rd_values (days) should be $cc_rd_days. value is $vals[0]");
}
