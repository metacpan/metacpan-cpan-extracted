#!/usr/bin/env perl

use strict;
use utf8;
use Test::More;
use POSIX qw/setlocale/;
use DateLocale;

my $count_test = 0;
my @time  =  qw/33 22 11 11 2 114/;
my @time1 =  qw/33 22 7 11 2 114/;
my @time2 = (qw/33 22 11 11 2/, (localtime(time))[5]);
if(DateLocale::change_locale('ru_RU.UTF-8')){
	is(DateLocale::strftime('%OB %B', @time), 'март марта', 'Month name');
	is(DateLocale::strftime( '%Y-%m-%d', @time), '2014-03-11', 'Numeric date');
	is(DateLocale::strftime("%d %B %Y", @time), '11 марта 2014', 'Full date');
	is(DateLocale::strftime("%d %B", @time), '11 марта', 'Date without year');
	is(DateLocale::strftime("%d %B %Y %H:%M", @time), '11 марта 2014 11:22', 'Full date with time');
	is(DateLocale::strftime("%d %B %H:%M", @time), '11 марта 11:22', 'Date with time without year');
	is(DateLocale::period_name( -2, \@time, ''), 'послезавтра в 11:22', 'period_name -2');
	is(DateLocale::period_name( -2, \@time, 'old_notime'), 'послезавтра в 11:22', 'period_name -2 old_notime');
	is(DateLocale::period_name( -1, \@time, ''), 'завтра в 11:22', 'period_name -1');
	is(DateLocale::period_name( -1, \@time, 'old_notime'), 'завтра в 11:22', 'period_name -1 old_notime');
	is(DateLocale::period_name( 0, \@time, ''), 'сегодня в 11:22', 'period_name 0');
	is(DateLocale::period_name( 0, \@time, 'old_notime'), 'сегодня в 11:22', 'period_name 0 old_notime');
	is(DateLocale::period_name( 1, \@time, ''), 'вчера в 11:22', 'period_name 1');
	is(DateLocale::period_name( 1, \@time, 'old_notime'), 'вчера в 11:22', 'period_name 1 old_notime');
	is(DateLocale::period_name( 2, \@time, ''), '11 марта в 11:22', 'period_name 2');
	is(DateLocale::period_name( 2, \@time, 'old_notime'), '11 марта', 'period_name 2 old_notime');
	is(DateLocale::period_name( 200, \@time, ''), '11 марта 2014 в 11:22', 'period_name 2');
	is(DateLocale::period_name( 200, \@time, 'old_notime'), '11 марта 2014', 'period_name 2 old_notime');
	is_deeply(DateLocale::format_date_ext(0, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'только что', long_tooltip => 'только что', short => '11:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 65, \@time, ['long', 'long_tooltip', 'short']), {long => '1 мин', long_tooltip => '1 минуту назад', short => '11:22'}, 'date_ext 1 min and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605, \@time, ['long', 'long_tooltip', 'short']), {long => '1 час', long_tooltip => '1 час назад', short => '11:22'}, 'date_ext 1 hour and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*2, \@time, ['long', 'long_tooltip', 'short']), {long => '2 часа', long_tooltip => '2 часа назад', short => '11:22'}, 'date_ext 2 hours and 10 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*5, \@time, ['long', 'long_tooltip', 'short']), {long => '5 часов', long_tooltip => '5 часов назад', short => '11:22'}, 'date_ext 5 hours and 25 sec');
	is_deeply(DateLocale::format_date_ext(1, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'вчера в 11:22', long_tooltip => 'вчера в 11:22', short => 'вчера'}, 'date_ext 1 day and 5 sec');
	is_deeply(DateLocale::format_date_ext($_, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'вторник', long_tooltip => 'вторник в 11:22',short => '11 марта'}, 'date_ext '.$_.' days and 5 sec') for qw /2 3 4/;
	is_deeply(DateLocale::format_date_ext(5, 5, \@time2, ['long', 'long_tooltip', 'short']), {long => '11 марта', long_tooltip => '11 марта в 11:22',short => '11 марта'}, 'date_ext 5 days and 5 sec');
	is_deeply(DateLocale::format_date_ext(200, 5, \@time, ['long', 'long_tooltip', 'short']), {long => POSIX::strftime("%d %b %y", 0, 0, 0, 11, 2, 2014), long_tooltip => '11 марта 2014 в 11:22',short => '11.03.2014'}, 'date_ext 200 days and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 5, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 65, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*2, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*5, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	$count_test += 34;
}
else {
	warn "ru_RU.UTF-8 not found: skip";
}


if(DateLocale::change_locale('uk_UA.UTF-8')){
	is(DateLocale::strftime('%OB %B', @time), 'березень березня', 'Month name');
	is(DateLocale::strftime( '%Y-%m-%d', @time), '2014-03-11', 'Numeric date');
	is(DateLocale::strftime("%d %B %Y", @time), '11 березня 2014', 'Full date');
	is(DateLocale::strftime("%d %B", @time), '11 березня', 'Date without year');
	is(DateLocale::strftime("%d %B %Y %H:%M", @time), '11 березня 2014 11:22', 'Full date with time');
	is(DateLocale::strftime("%d %B %H:%M", @time), '11 березня 11:22', 'Date with time without year');
	is(DateLocale::period_name( -2, \@time, ''), 'пiслязавтра о 11:22', 'period_name -2');
	is(DateLocale::period_name( -2, \@time, 'old_notime'), 'пiслязавтра о 11:22', 'period_name -2 old_notime');
	is(DateLocale::period_name( -1, \@time, ''), 'завтра о 11:22', 'period_name -1');
	is(DateLocale::period_name( -1, \@time, 'old_notime'), 'завтра о 11:22', 'period_name -1 old_notime');
	is(DateLocale::period_name( 0, \@time, ''), 'сьогоднi о 11:22', 'period_name 0');
	is(DateLocale::period_name( 0, \@time, 'old_notime'), 'сьогоднi о 11:22', 'period_name 0 old_notime');
	is(DateLocale::period_name( 1, \@time, ''), 'вчора о 11:22', 'period_name 1');
	is(DateLocale::period_name( 1, \@time, 'old_notime'), 'вчора о 11:22', 'period_name 1 old_notime');
	is(DateLocale::period_name( 2, \@time, ''), '11 березня о 11:22', 'period_name 2');
	is(DateLocale::period_name( 2, \@time, 'old_notime'), '11 березня', 'period_name 2 old_notime');
	is(DateLocale::period_name( 200, \@time, ''), '11 березня 2014 о 11:22', 'period_name 2');
	is(DateLocale::period_name( 200, \@time, 'old_notime'), '11 березня 2014', 'period_name 2 old_notime');
	is_deeply(DateLocale::format_date_ext(0, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'тільки що', long_tooltip => 'тільки що', short => '11:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 65, \@time, ['long', 'long_tooltip', 'short']), {long => '1 хв', long_tooltip => '1 хвилину тому', short => '11:22'}, 'date_ext 1 min and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605, \@time, ['long', 'long_tooltip', 'short']), {long => '1 година', long_tooltip => '1 година тому', short => '11:22'}, 'date_ext 1 hour and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*2, \@time, ['long', 'long_tooltip', 'short']), {long => '2 години', long_tooltip => '2 години тому', short => '11:22'}, 'date_ext 2 hours and 10 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*5, \@time, ['long', 'long_tooltip', 'short']), {long => '5 годин', long_tooltip => '5 годин тому', short => '11:22'}, 'date_ext 5 hours and 25 sec');
	is_deeply(DateLocale::format_date_ext(1, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'вчора о 11:22', long_tooltip => 'вчора о 11:22', short => 'вчора'}, 'date_ext 1 day and 5 sec');
	is_deeply(DateLocale::format_date_ext($_, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'вівторок', long_tooltip => 'вівторок о 11:22', short => '11 березня'}, 'date_ext '.$_.' days and 5 sec') for qw /2 3 4/;
	is_deeply(DateLocale::format_date_ext(5, 5, \@time2, ['long', 'long_tooltip', 'short']), {long => '11 березня', long_tooltip => '11 березня о 11:22', short => '11 березня'}, 'date_ext 5 days and 5 sec');
	is_deeply(DateLocale::format_date_ext(200, 5, \@time, ['long', 'long_tooltip', 'short']), {long => POSIX::strftime("%d %b %y", 0, 0, 0, 11, 2, 2014), long_tooltip => '11 березня 2014 о 11:22', short => '11.03.2014'}, 'date_ext 200 days and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 5, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 65, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*2, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*5, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	$count_test += 34;
}
else {
	warn "uk_UA.UTF-8 not found: skip";
}


if(DateLocale::change_locale('kk_KZ.UTF-8')){
	is(DateLocale::strftime('%OB %B', @time), 'наурыз наурызы', 'Month name');
	is(DateLocale::strftime( '%Y-%m-%d', @time), '2014-03-11', 'Numeric date');
	is(DateLocale::strftime("%d %B %Y", @time), '11 наурызы 2014', 'Full date');
	is(DateLocale::strftime("%d %B", @time), '11 наурызы', 'Date without year');
	is(DateLocale::strftime("%d %B %Y %H:%M", @time), '11 наурызы 2014 11:22', 'Full date with time');
	is(DateLocale::strftime("%d %B %H:%M", @time), '11 наурызы 11:22', 'Date with time without year');
	is(DateLocale::period_name( -2, \@time, ''), 'бүрсігүні, 11:22', 'period_name -2');
	is(DateLocale::period_name( -2, \@time, 'old_notime'), 'бүрсігүні, 11:22', 'period_name -2 old_notime');
	is(DateLocale::period_name( -1, \@time, ''), 'ертең, 11:22', 'period_name -1');
	is(DateLocale::period_name( -1, \@time, 'old_notime'), 'ертең, 11:22', 'period_name -1 old_notime');
	is(DateLocale::period_name( 0, \@time, ''), 'бүгін, 11:22', 'period_name 0');
	is(DateLocale::period_name( 0, \@time, 'old_notime'), 'бүгін, 11:22', 'period_name 0 old_notime');
	is(DateLocale::period_name( 1, \@time, ''), 'кеше, 11:22', 'period_name 1');
	is(DateLocale::period_name( 1, \@time, 'old_notime'), 'кеше, 11:22', 'period_name 1 old_notime');
	is(DateLocale::period_name( 2, \@time, ''), '11 наурызы, 11:22', 'period_name 2');
	is(DateLocale::period_name( 2, \@time, 'old_notime'), '11 наурызы', 'period_name 2 old_notime');
	is(DateLocale::period_name( 200, \@time, ''), '11 наурызы 2014, 11:22', 'period_name 2');
	is(DateLocale::period_name( 200, \@time, 'old_notime'), '11 наурызы 2014', 'period_name 2 old_notime');
	is_deeply(DateLocale::format_date_ext(0, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'жаңа ғана', long_tooltip => 'жаңа ғана', short => '11:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 65, \@time, ['long', 'long_tooltip', 'short']), {long => '1 мин', long_tooltip => '1 минут бұрын', short => '11:22'}, 'date_ext 1 min and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605, \@time, ['long', 'long_tooltip', 'short']), {long => '1 сағат', long_tooltip => '1 сағат бұрын', short => '11:22'}, 'date_ext 1 hour and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*2, \@time, ['long', 'long_tooltip', 'short']), {long => '2 сағат', long_tooltip => '2 сағат бұрын', short => '11:22'}, 'date_ext 2 hours and 10 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*5, \@time, ['long', 'long_tooltip', 'short']), {long => '5 сағат', long_tooltip => '5 сағат бұрын', short => '11:22'}, 'date_ext 5 hours and 25 sec');
	is_deeply(DateLocale::format_date_ext(1, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'кеше, 11:22', long_tooltip => 'кеше, 11:22', short => 'кеше'}, 'date_ext 1 day and 5 sec');
	is_deeply(DateLocale::format_date_ext($_, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'сейсенбі', long_tooltip => 'сейсенбі, 11:22', short => '11 наурызы'}, 'date_ext '.$_.' days and 5 sec') for qw /2 3 4/;
	is_deeply(DateLocale::format_date_ext(5, 5, \@time2, ['long', 'long_tooltip', 'short']), {long => '11 наурызы', long_tooltip => '11 наурызы, 11:22', short => '11 наурызы'}, 'date_ext 5 days and 5 sec');
	is_deeply(DateLocale::format_date_ext(200, 5, \@time, ['long', 'long_tooltip', 'short']), {long => POSIX::strftime("%d %b %y", 0, 0, 0, 11, 2, 2014), long_tooltip => '11 наурызы 2014, 11:22', short => '11.03.2014'}, 'date_ext 200 days and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 5, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 65, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*2, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*5, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	$count_test += 34;
}
else {
	warn "kk_KZ.UTF-8 not found: skip";
}


if(DateLocale::change_locale('en_US.UTF-8')){
	is(DateLocale::strftime('%OB %B', @time), 'March March', 'Month name');
	is(DateLocale::strftime( '%Y-%m-%d', @time), '2014-03-11', 'Numeric date');
	is(DateLocale::strftime("%d %B %Y", @time), '11 March 2014', 'Full date');
	is(DateLocale::strftime("%d %B", @time), '11 March', 'Date without year');
	is(DateLocale::strftime("%d %B %Y %H:%M", @time), '11 March 2014 11:22', 'Full date with time');
	is(DateLocale::strftime("%d %B %H:%M", @time), '11 March 11:22', 'Date with time without year');
	is(DateLocale::period_name( -2, \@time, ''), 'day after tommorow at 11:22', 'period_name -2');
	is(DateLocale::period_name( -2, \@time, 'old_notime'), 'day after tommorow at 11:22', 'period_name -2 old_notime');
	is(DateLocale::period_name( -1, \@time, ''), 'tommorow at 11:22', 'period_name -1');
	is(DateLocale::period_name( -1, \@time, 'old_notime'), 'tommorow at 11:22', 'period_name -1 old_notime');
	is(DateLocale::period_name( 0, \@time, ''), 'today at 11:22', 'period_name 0');
	is(DateLocale::period_name( 0, \@time, 'old_notime'), 'today at 11:22', 'period_name 0 old_notime');
	is(DateLocale::period_name( 1, \@time, ''), 'yesterday at 11:22', 'period_name 1');
	is(DateLocale::period_name( 1, \@time, 'old_notime'), 'yesterday at 11:22', 'period_name 1 old_notime');
	is(DateLocale::period_name( 2, \@time, ''), '11 March at 11:22', 'period_name 2');
	is(DateLocale::period_name( 2, \@time, 'old_notime'), '11 March', 'period_name 2 old_notime');
	is(DateLocale::period_name( 200, \@time, ''), '11 March 2014 at 11:22', 'period_name 2');
	is(DateLocale::period_name( 200, \@time, 'old_notime'), '11 March 2014', 'period_name 2 old_notime');
	is_deeply(DateLocale::format_date_ext(0, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'recently', long_tooltip => 'recently', short => '11:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 65, \@time, ['long', 'long_tooltip', 'short']), {long => '1 min', long_tooltip => '1 minute ago', short => '11:22'}, 'date_ext 1 min and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605, \@time, ['long', 'long_tooltip', 'short']), {long => '1 hour', long_tooltip => '1 hour ago', short => '11:22'}, 'date_ext 1 hour and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*2, \@time, ['long', 'long_tooltip', 'short']), {long => '2 hours', long_tooltip => '2 hours ago', short => '11:22'}, 'date_ext 2 hours and 10 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*5, \@time, ['long', 'long_tooltip', 'short']), {long => '5 hours', long_tooltip => '5 hours ago', short => '11:22'}, 'date_ext 5 hours and 25 sec');
	is_deeply(DateLocale::format_date_ext(1, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'yesterday at 11:22', long_tooltip => 'yesterday at 11:22', short => 'yesterday'}, 'date_ext 1 day and 5 sec');
	is_deeply(DateLocale::format_date_ext($_, 5, \@time, ['long', 'long_tooltip', 'short']), {long => 'tuesday', long_tooltip => 'tuesday at 11:22', short => '11 March'}, 'date_ext '.$_.' days and 5 sec') for qw /2 3 4/;
	is_deeply(DateLocale::format_date_ext(5, 5, \@time2, ['long', 'long_tooltip', 'short']), {long => '11 March', long_tooltip => '11 March at 11:22', short => '11 March'}, 'date_ext 5 days and 5 sec');
	is_deeply(DateLocale::format_date_ext(200, 5, \@time, ['long', 'long_tooltip', 'short']), {long => '11 mar 14', long_tooltip => '11 March 2014 at 11:22', short => '11.03.2014'}, 'date_ext 200 days and 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 5, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 65, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*2, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	is_deeply(DateLocale::format_date_ext(0, 3605*5, \@time1, ['short']), {short => ' 7:22'}, 'date_ext 5 sec');
	$count_test += 34;
}
else {
	warn "en_US.UTF-8 not found: skip";
}
done_testing($count_test);

