#!perl
use warnings;
use strict;
use lib qw(./lib);

use Test::More tests => 6;

use_ok('Bot::BasicBot::Pluggable::Module::Foldoc');
use_ok('Bot::BasicBot::Pluggable::Module::Hyperarchive');
use_ok('Bot::BasicBot::Pluggable::Module::Foldoc');
use_ok('Bot::BasicBot::Pluggable::Module::IMDB');
use_ok('Bot::BasicBot::Pluggable::Module::Websters');
use_ok('Bot::BasicBot::Pluggable::Module::Bash');

