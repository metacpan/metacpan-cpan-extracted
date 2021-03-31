# test.t

use utf8;
use Test::Most;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Date::Holidays::GB;
use Date::Holidays::GB::EAW qw( is_holiday holidays );

open( my $fh, '<:encoding(utf-8)', 't/samples/2013-holidays' )
    or die "Can't open 2013-holidays: $!";

Date::Holidays::GB::set_holidays($fh);

note "is_holiday";

ok !is_holiday( 2013, 1, 3 ),    "2013-01-03 is not a holiday";

ok my $christmas = is_holiday( 2013, 12, 25 ),
    "2013-12-25 is a holiday";
is $christmas, "Christmas Day", "Christmas Day name ok";

note "holidays";

is_deeply holidays(2013),
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
    "2013 holidays ok";

done_testing();

