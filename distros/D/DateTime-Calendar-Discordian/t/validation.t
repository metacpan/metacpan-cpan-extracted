#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use English qw( -no_match_vars );
use DateTime;
use DateTime::Calendar::Discordian;

eval{
    DateTime::Calendar::Discordian->new
    (day => q{St. Tib's day}, season => 'Chaos', year => 3166);
};
ok($EVAL_ERROR,  'St. Tibs and season');

eval{
    DateTime::Calendar::Discordian->new
    (day => 0, season => 'Chaos', year => 3166);
};
ok($EVAL_ERROR,  'day < 1');

eval{
    DateTime::Calendar::Discordian->new
    (day => 74, season => 'Chaos', year => 3166);
};
ok($EVAL_ERROR,  'day > 73');

eval{
    DateTime::Calendar::Discordian->new
    (day => 1, season => 'Order', year => 3166);
};
ok($EVAL_ERROR,  'invalid season');

eval{
    DateTime::Calendar::Discordian->new(day => 1, year => 3166);
};
ok($EVAL_ERROR,  'missing season');

done_testing();
