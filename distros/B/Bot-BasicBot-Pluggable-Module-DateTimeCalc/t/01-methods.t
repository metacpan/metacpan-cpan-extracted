#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Bot::BasicBot::Pluggable::Module::DateTimeCalc';

my $bot = new_ok 'Bot::BasicBot::Pluggable::Module::DateTimeCalc';

can_ok $bot, 'help';
can_ok $bot, 'said';
can_ok $bot, 'run';

done_testing();
