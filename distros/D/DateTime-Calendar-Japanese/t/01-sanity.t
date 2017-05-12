#!perl
use Test::More tests => 41;
BEGIN
{
    print STDERR 
        "\n*** This test will take a long time, please be patient ***\n",
        "*** Starting on ", scalar(localtime), "\n";
    use_ok("DateTime::Calendar::Japanese", qw(HEISEI));
}

my $cc;
# 1 Jan 2004 is cycle 78 year 20 (Gui-Wei [Sheep]) month 12, day 10

my $dt = DateTime->new(year => 2004, month => 1, day => 1, time_zone => 'Asia/Tokyo');
$cc    = DateTime::Calendar::Japanese->from_object(object => $dt);
check_cc($cc, 78, 20, HEISEI, 16, 12, 10, 4, ($dt->utc_rd_values)[0]);
$cc    = DateTime::Calendar::Japanese->new(
    cycle      => 78,
    cycle_year => 20,
    month      => 12,
    day        => 10,
    time_zone  => 'Asia/Tokyo'
);
check_cc($cc, 78, 20, HEISEI, 16, 12, 10, 4, ($dt->utc_rd_values)[0]);

$cc    = DateTime::Calendar::Japanese->new(
    era_name   => HEISEI,
    era_year   => 16,
    month      => 12,
    day        => 10,
    time_zone  => 'Asia/Tokyo'
);
check_cc($cc, 78, 20, HEISEI, 16, 12, 10, 4, ($dt->utc_rd_values)[0]);

$cc->set(era_year => 15);
check_cc($cc, 78, 19, HEISEI, 15, 12, 10, 6, 731225);


sub check_cc
{
    my($cc, $cycle, $cycle_year, $era_id, $era_year, $month, $day, $day_of_week, $rd) = @_;

    isa_ok($cc, "DateTime::Calendar::Japanese");
    can_ok($cc, "cycle", "cycle_year", "month", "leap_month", "day",
        "utc_rd_values");

    is($cc->cycle, $cycle);
    is($cc->cycle_year, $cycle_year);
    is($cc->era->id, $era_id);
    is($cc->era_year, $era_year);
    is($cc->month, $month);
    is($cc->day, $day);
    is($cc->day_of_week, $day_of_week);

    my @vals = $cc->utc_rd_values();
    is($vals[0], $rd);
}
