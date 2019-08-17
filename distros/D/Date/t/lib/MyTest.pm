package MyTest;
use 5.012;
use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, 'en_US.UTF-8');

use Time::XS qw/
    tzset tzget tzname tzdir gmtime localtime timegm timegmn timelocal timelocaln
    available_zones use_embed_zones use_system_zones
/;

use Date qw/now date rdate rdate_const idate today today_epoch :const/;

use_embed_zones();
tzset('Europe/Moscow');

sub import {
    no strict 'refs';
    my $stash = \%{MyTest::};
    my $caller = caller();
    *{"${caller}::$_"} = *{"MyTest::$_"} for keys %$stash;
}

1;
