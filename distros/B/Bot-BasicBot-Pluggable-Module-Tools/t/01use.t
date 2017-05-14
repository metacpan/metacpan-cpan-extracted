#!perl
use warnings;
use strict;
use lib qw(./lib);

use Test::More tests => 8;

use_ok('Bot::BasicBot::Pluggable::Module::Status');
use_ok('Bot::BasicBot::Pluggable::Module::Translate');
use_ok('Bot::BasicBot::Pluggable::Module::Convert');
use_ok('Bot::BasicBot::Pluggable::Module::Maths');
use_ok('Bot::BasicBot::Pluggable::Module::Spell');
use_ok('Bot::BasicBot::Pluggable::Module::Stockquote');
use_ok('Bot::BasicBot::Pluggable::Module::Funcs');
use_ok('Bot::BasicBot::Pluggable::Module::LongURLs');

