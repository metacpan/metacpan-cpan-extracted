use strict;
use warnings;
use Test::More tests => 27;
use DateTime::Format::TauStation;

# don't test per-second accuracy - many test report failures

{
    my $dt = DateTime::Format::TauStation->parse_datetime('000.00/00:000 GCT');
    is($dt->year,            1964, 'year');
    is($dt->month,             01, 'month');
    is($dt->day,               22, 'day');
    is($dt->hour,              00, 'hour');
    is($dt->minute,            00, 'minute');

    is($dt->gct_sign,          '', 'gct_sign');
    is($dt->gct_cycle,        000, 'gct_cycle');
    is($dt->gct_day,           00, 'gct_day');
    is($dt->gct_segment,       00, 'gct_segment');
}

{
    my $dt = DateTime::Format::TauStation->parse_datetime('198.15/03:973 GCT');
    is($dt->year,            2018, 'year');
    is($dt->month,             04, 'month');
    is($dt->day,               23, 'day');
    is($dt->hour,              00, 'hour');
    is($dt->minute,            57, 'minute');

    is($dt->gct_sign,          '', 'gct_sign');
    is($dt->gct_cycle,        198, 'gct_cycle');
    is($dt->gct_day,           15, 'gct_day');
    is($dt->gct_segment,       03, 'gct_segment');
}

{
    my $dt = DateTime::Format::TauStation->parse_datetime('-0.0/01:000 GCT');
    is($dt->year,            1964, 'year');
    is($dt->month,             01, 'month');
    is($dt->day,               21, 'day');
    is($dt->hour,              23, 'hour');
    is($dt->minute,            46, 'minute');

    is($dt->gct_sign,         '-', 'gct_sign');
    is($dt->gct_cycle,        000, 'gct_cycle');
    is($dt->gct_day,           00, 'gct_day');
    is($dt->gct_segment,       01, 'gct_segment');
}
