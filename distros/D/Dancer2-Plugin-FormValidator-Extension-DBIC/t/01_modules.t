use strict;
use warnings;
use Test::More tests => 2;

# TEST 1.
use_ok('Dancer2::Plugin::FormValidator::Extension::DBIC');

# TEST 2.
use_ok('Dancer2::Plugin::FormValidator::Extension::DBIC::Unique');
