#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Bot::BasicBot::Pluggable::Module::DateTimeCalc';

my $obj = Bot::BasicBot::Pluggable::Module::DateTimeCalc->new();
isa_ok $obj, 'Bot::BasicBot::Pluggable::Module::DateTimeCalc';

done_testing();
