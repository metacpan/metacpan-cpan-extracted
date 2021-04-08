package MyTest;
use 5.012;
use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, 'en_US.UTF-8');
use Test::Catch();
use Config;

use Date qw/
    now date date_ymd rdate rdate_ymd rdate_const rdate_ymd_const today today_epoch :const
    tzset tzget gmtime localtime timegm timegmn timelocal timelocaln
/;

Date::use_embed_timezones();
tzset('Europe/Moscow');

XS::Loader::load();

sub import {
    no strict 'refs';
    my $stash = \%{MyTest::};
    my $caller = caller();
    *{"${caller}::$_"} = *{"MyTest::$_"} for keys %$stash;
}

sub catch_run {
    my $old = Date::tzembededdir();
    chdir "clib" or die $!; # c tests reset embed zones relative to "clib"
    Test::Catch::run(@_);
    chdir ".." or die $!;
    Date::tzembededdir($old);
    Date::use_embed_timezones(); # return full path of embed zones
}

1;
