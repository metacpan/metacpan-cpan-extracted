use strict;
use warnings;

use Test::More;

{
    eval { require Date::Holidays };
    skip "Date::Holidays not installed", 12 if $@;

    my $dh = Date::Holidays->new( countrycode => 'es' );
    isa_ok($dh, 'Date::Holidays');

    ok($dh->is_holiday(year => 2007, month => 4, day => 9 , region => 'ca'), 'Pasqua Florida 2007');
    ok($dh->is_holiday(year => 2007, month => 1, day => 6 , region => 'ca'), 'Reis 2007'          );
    ok($dh->is_holiday(year => 2008, month => 3, day => 24, region => 'ca'), 'Pasqua Florida 2008');
    ok($dh->is_holiday(year => 2008, month => 9, day => 11, region => 'ca'), 'Diada Nacional 2008');
    ok($dh->is_holiday(year => 2009, month => 4, day => 13, region => 'ca'), 'Pasqua Florida 2009');
    ok($dh->is_holiday(year => 2009, month => 6, day => 24, region => 'ca'), 'Sant Joan 2009'     );
    ok($dh->is_holiday(year => 2010, month => 4, day => 5 , region => 'ca'), 'Pasqua Florida 2010');
    ok($dh->is_holiday(year => 2009, month => 12,day => 26, region => 'ca'), 'Sant Esteve 2010'   );

    my $holidays = $dh->holidays(year => 2007);
    is($holidays->{1225}, "Navidad", "Christmas");

    my $yho = $dh->holidays_dt(year => 2007);
    my $christmas_dt = $yho->{Navidad};
    is($christmas_dt->day, '25', "Also Christmas");
}

{
    use_ok('Date::Holidays::CA_ES');

    my $dh = Date::Holidays::CA_ES->new;
    isa_ok($dh, 'Date::Holidays::CA_ES');

    ok($dh->is_es_holiday(year => 2005, month => 3, day => 25), "Correct calculated holiday");
    ok($dh->is_es_holiday(year => 2006, month => 4, day => 14), "Correct calculated holiday");
    ok($dh->is_es_holiday(year => 2007, month => 4, day => 6 ), "Correct calculated holiday");

    my $holidays = $dh->es_holidays(year => 2007);
    is($holidays->{1225}, "Navidad", "Christmas");

    my $yho = $dh->holidays_es(year => 2007);
    my $christmas_dt = $yho->{Navidad};
    is($christmas_dt->day, '25', "Also Christmas");
}

done_testing();
