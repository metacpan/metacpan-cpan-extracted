use strict;
use warnings;

use Test::More;

SKIP: {
    eval { require Date::Holidays };
    skip "Date::Holidays not installed", 4 if $@;

    my $dh = Date::Holidays->new( countrycode => 'ES' );
    isa_ok($dh, 'Date::Holidays');

    ok($dh->is_holiday(year => 2002, month => 3, day => 29), "Correct calculated holiday");
    ok($dh->is_holiday(year => 2003, month => 4, day => 18), "Correct calculated holiday");
    ok($dh->is_holiday(year => 2004, month => 4, day => 9) , "Correct calculated holiday");
}

{
    use_ok('Date::Holidays::ES');

    my $dh = Date::Holidays::ES->new;
    isa_ok($dh, 'Date::Holidays::ES');

    ok($dh->is_es_holiday(year => 2005, month => 3, day => 25), "Correct calculated holiday");
    ok($dh->is_es_holiday(year => 2006, month => 4, day => 14), "Correct calculated holiday");
    ok($dh->is_es_holiday(year => 2007, month => 4, day => 6) , "Correct calculated holiday");

    my $holidays = $dh->es_holidays(year => 2007);
    is($holidays->{1225}, "Navidad", "Christmas");

    my $yho = $dh->holidays_es(year => 2007);
    my $christmas_dt = $yho->{Navidad};
    is($christmas_dt->day, '25', "Also Christmas");
}

done_testing();
