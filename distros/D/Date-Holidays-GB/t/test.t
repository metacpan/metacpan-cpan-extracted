# test.t

use utf8;
use Test::Most;
use Test::Fatal;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Date::Holidays::GB qw/ is_holiday holidays holidays_ymd /;

open( my $fh, '<:encoding(utf-8)', 't/samples/2013-holidays' )
    or die "Can't open 2013-holidays: $!";

Date::Holidays::GB::set_holidays( $fh );

note "is_holiday";

ok !is_holiday( 2013, 1, 3 ), "2013-01-03 is not a holiday";

ok my $christmas = is_holiday( 2013, 12, 25 ), "2013-12-25 is a holiday";
is $christmas, "Christmas Day", "Christmas Day name ok (all)";

ok !is_holiday( 2013, 12, 25, [] ), "2013-12-25 is not a holiday if empty region list";

ok !is_holiday( 2013, 11, 30, ['EAW'] ),
    "2013-12-02 is not a holiday in England & Wales";
ok my $st_andrews_day = is_holiday( 2013, 12, 02, ['SCT'] ),
    "2013-12-02 is a holiday in Scotland";
is $st_andrews_day, "St Andrew\x{2019}s Day (Scotland)", "St Andrew's Day name ok";

note "holidays";

is_deeply holidays(2000), {}, "No data for year 2000 - outside range";
is_deeply holidays(2020), {}, "No data for year 2020 - outside range";

#like exception { holidays(2000) }, qr/No holiday data for year 2000/, "dies ok outside date range";
#like exception { holidays(2020) }, qr/No holiday data for year 2020/, "dies ok outside date range";

is_deeply holidays(2013),
    {
    "0101" => "New Year\x{2019}s Day",
    "0102" => "2nd January (Scotland)",
    "0318" => "St Patrick\x{2019}s Day (Northern Ireland)",
    "0329" => "Good Friday",
    "0401" => "Easter Monday (England & Wales, Northern Ireland)",
    "0506" => "Early May bank holiday",
    "0527" => "Spring bank holiday",
    "0712" =>
        "Battle of the Boyne (Orangemen\x{2019}s Day) (Northern Ireland)",
    "0805" => "Summer bank holiday (Scotland)",
    "0826" => "Summer bank holiday (England & Wales, Northern Ireland)",
    "1202" => "St Andrew\x{2019}s Day (Scotland)",
    "1225" => "Christmas Day",
    "1226" => "Boxing Day"
    },
    "2013 holidays ok";

is_deeply holidays_ymd(2013),
    {
    "2013-01-01" => "New Year\x{2019}s Day",
    "2013-01-02" => "2nd January (Scotland)",
    "2013-03-18" => "St Patrick\x{2019}s Day (Northern Ireland)",
    "2013-03-29" => "Good Friday",
    "2013-04-01" => "Easter Monday (England & Wales, Northern Ireland)",
    "2013-05-06" => "Early May bank holiday",
    "2013-05-27" => "Spring bank holiday",
    "2013-07-12" =>
        "Battle of the Boyne (Orangemen\x{2019}s Day) (Northern Ireland)",
    "2013-08-05" => "Summer bank holiday (Scotland)",
    "2013-08-26" => "Summer bank holiday (England & Wales, Northern Ireland)",
    "2013-12-02" => "St Andrew\x{2019}s Day (Scotland)",
    "2013-12-25" => "Christmas Day",
    "2013-12-26" => "Boxing Day"
    },
    "2013 holidays_ymd ok";

is_deeply holidays( year => 2013, regions => ['EAW'] ),
    {
    "0101" => "New Year\x{2019}s Day",
    "0329" => "Good Friday",
    "0401" => "Easter Monday (England & Wales)",
    "0506" => "Early May bank holiday",
    "0527" => "Spring bank holiday",
    "0826" => "Summer bank holiday (England & Wales)",
    "1225" => "Christmas Day",
    "1226" => "Boxing Day"
    },
    "got holidays for England & Wales, 2013";

done_testing();

