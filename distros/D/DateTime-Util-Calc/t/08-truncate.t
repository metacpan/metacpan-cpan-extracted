#!perl
use strict;
use Test::More (tests => 6);

BEGIN
{
    use_ok("DateTime::Util::Calc", "truncate_to_midday");
}

my $dt = DateTime->now;
my $t  = truncate_to_midday($dt);

is($t->hour, 12);
is($t->minute, 0);
is($t->second, 0);
is($t->nanosecond, 0);
is($t->time_zone->name, 'UTC');
