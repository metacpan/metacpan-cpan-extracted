#!perl
use warnings;
use strict;
use lib qw(./lib);

use Test::More tests => 8;

use_ok('Bot::BasicBot::Pluggable::Module::Magic8Ball');
use_ok('Bot::BasicBot::Pluggable::Module::Dice');
use_ok('Bot::BasicBot::Pluggable::Module::Botsnack');
use_ok('Bot::BasicBot::Pluggable::Module::Excuse');
use_ok('Bot::BasicBot::Pluggable::Module::Nickometer');
use_ok('Bot::BasicBot::Pluggable::Module::Zippy');
use_ok('Bot::BasicBot::Pluggable::Module::Summon');
use_ok('Bot::BasicBot::Pluggable::Module::Insult');

