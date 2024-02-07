use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN { use_ok('Date::Holidays::CA', qw(:all)) };

{
    my $ca = Date::Holidays::CA->new({province => 'NL'});
    ok($ca->is_holiday(2015, 3, 16), "Specify province in initalization");
    ok(!$ca->is_holiday(2015, 2, 16), "Specify province in initalization");
    my $calendar = holidays(2015, {province => 'NL', language => 'EN'});
    like($calendar->{'0316'}, qr/St Patrick's/, "St Patrick's Day");

}
{
    my $ca = Date::Holidays::CA->new();
    ok($ca->is_holiday(2015, 3, 16, {province => 'NL'}), "Specify province in is_holiday");
    ok(!$ca->is_holiday(2015, 2, 16), "Specify province in initalization");
    my $calendar = holidays(2015, {province => 'NL', language => 'EN'});
    like($calendar->{'0316'}, qr/St Patrick's/, "St Patrick's Day");

}

done_testing;
