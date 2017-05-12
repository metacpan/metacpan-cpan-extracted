# test.t

use utf8;
use Test::Most;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Date::Holidays::GB;
use Date::Holidays::GB::EAW;
use Date::Holidays::GB::NIR;
use Date::Holidays::GB::SCT;

open( my $fh, '<:encoding(utf-8)', 't/samples/2013-holidays' )
    or die "Can't open 2013-holidays: $!";

Date::Holidays::GB::set_holidays($fh);

note "is_holiday";

ok !Date::Holidays::GB::EAW::is_holiday( 2013, 1, 3 ),
    "2013-01-03 is not a holiday";

ok my $christmas = Date::Holidays::GB::EAW::is_holiday( 2013, 12, 25 ),
    "2013-12-25 is a holiday";
is $christmas, "Christmas Day", "Christmas Day name ok";

ok !Date::Holidays::GB::EAW::is_holiday( 2013, 12, 02 ),
    "St Andrew's Day not holiday in England & Wales";
ok my $st_andrews_day = Date::Holidays::GB::SCT::is_holiday( 2013, 12, 02 ),
    "2013-12-02 is a holiday in Scotland";
is $st_andrews_day, "St Andrew\x{2019}s Day (Scotland)",
    "St Andrew's Day name ok";

note "holidays";

is_deeply Date::Holidays::GB::SCT::holidays(2013),
    {
    "0101" => "New Year\x{2019}s Day",
    "0102" => "2nd January (Scotland)",
    "0329" => "Good Friday",
    "0506" => "Early May bank holiday",
    "0527" => "Spring bank holiday",
    "0805" => "Summer bank holiday (Scotland)",
    "1202" => "St Andrew\x{2019}s Day (Scotland)",
    "1225" => "Christmas Day",
    "1226" => "Boxing Day"
    },
    "2013 holidays ok";

done_testing();

