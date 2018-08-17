use strict;
use warnings;
use Test::More tests => 21;
use DateTime::Format::TauStation;

{
    my $dt = DateTime::Format::TauStation->parse_datetime('000.00/00:000 GCT');
    is($dt->year,            1964, 'year');
    is($dt->month,             01, 'month');
    is($dt->day,               22, 'day');
    is($dt->hour,              00, 'hour');
    is($dt->minute,            00, 'minute');
    is($dt->second,            27, 'second');
    is($dt->nanosecond,    689615, 'nanosecond');

    is($dt->gct_cycle,        000, 'gct_cycle');
    is($dt->gct_day,           00, 'gct_day');
    is($dt->gct_segment,       00, 'gct_segment');
    is($dt->gct_unit,          00, 'gct_unit');
}

{
    my $dt = DateTime::Format::TauStation->parse_datetime('198.15/03:973 GCT');
    is($dt->year,            2018, 'year');
    is($dt->month,             04, 'month');
    is($dt->day,               23, 'day');
    is($dt->hour,              00, 'hour');
    is($dt->minute,            57, 'minute');
    is($dt->second,            13, 'second');

    is($dt->gct_cycle,        198, 'gct_cycle');
    is($dt->gct_day,           15, 'gct_day');
    is($dt->gct_segment,       03, 'gct_segment');
    is($dt->gct_unit,         973, 'gct_unit');
}
