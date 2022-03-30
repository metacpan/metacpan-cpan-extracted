use strict;
use warnings;
use Test::More tests => 7;

# TEST 1.
## Dancer2::Plugin::FormValidator.

use_ok('Dancer2::Plugin::FormValidator');

# TEST 2.
## Dancer2::Plugin::FormValidator::Config.

use_ok('Dancer2::Plugin::FormValidator::Config');

# TEST 3.
## Dancer2::Plugin::FormValidator::Processor.

use_ok('Dancer2::Plugin::FormValidator::Processor');

# TEST 4.
## Dancer2::Plugin::FormValidator::Result.

use_ok('Dancer2::Plugin::FormValidator::Result');

# TEST 5.
## Dancer2::Plugin::FormValidator::Role::Validator.

use_ok('Dancer2::Plugin::FormValidator::Role::HasProfile');

# TEST 6.
## Dancer2::Plugin::FormValidator::Role::HasMessages.

use_ok('Dancer2::Plugin::FormValidator::Role::HasMessages');

# TEST 7.
## Dancer2::Plugin::FormValidator::Role::HasAll.

use_ok('Dancer2::Plugin::FormValidator::Role::HasProfileMessages');

