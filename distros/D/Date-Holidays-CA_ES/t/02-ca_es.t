use strict;
use warnings;

use Test::More tests => 11;
use Date::Holidays;

{
    my $dh = Date::Holidays->new( countrycode => 'ca_es', nocheck => 1 );
    isa_ok($dh, 'Date::Holidays');

    ok($dh->is_holiday(year => 2007, month => 4, day => 9 ), 'Pasqua Florida 2007');
    ok($dh->is_holiday(year => 2007, month => 1, day => 6 ), 'Reis 2007'          );
    ok($dh->is_holiday(year => 2008, month => 3, day => 24), 'Pasqua Florida 2008');
    ok($dh->is_holiday(year => 2008, month => 9, day => 11), 'Diada Nacional 2008');
    ok($dh->is_holiday(year => 2009, month => 4, day => 13), 'Pasqua Florida 2009');
    ok($dh->is_holiday(year => 2009, month => 6, day => 24), 'Sant Joan 2009'     );
    ok($dh->is_holiday(year => 2010, month => 4, day => 5 ), 'Pasqua Florida 2010');
    ok($dh->is_holiday(year => 2009, month => 12,day => 26), 'Sant Esteve 2010'   );
    
    my $holidays = $dh->holidays(year => 2007);
    is($holidays->{1225}, "Navidad", "Christmas");

    my $yho = $dh->holidays_dt(year => 2007);
    my $christmas_dt = $yho->{Navidad};
    is($christmas_dt->day, '25', "Also Christmas");
}
