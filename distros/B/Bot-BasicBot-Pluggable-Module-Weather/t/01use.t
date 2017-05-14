#!perl
use warnings;
use strict;
use lib qw(./lib);

use Test::More tests => 2;

use_ok('Bot::BasicBot::Pluggable::Module::Aviation');
use_ok('Bot::BasicBot::Pluggable::Module::Weather');

