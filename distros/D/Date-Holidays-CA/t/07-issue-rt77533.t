use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN { use_ok('Date::Holidays::CA', qw(:all)) };

{
    my $ca = Date::Holidays::CA->new({province => 'BC'});
    ok($ca->is_holiday(2024, 2, 19), "Specify province in initalization");
    my $calendar = holidays(2024, {province => 'BC', language => 'EN'});
    like($calendar->{'0219'}, qr/Family Day/, "Family Day - British Columbia");
}

done_testing;
