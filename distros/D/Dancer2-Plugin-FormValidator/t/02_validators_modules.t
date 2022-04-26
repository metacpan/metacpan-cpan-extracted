use strict;
use warnings;
use Test::More tests => 14;

# TEST 1.
use_ok('Dancer2::Plugin::FormValidator::Validator::Required');

# TEST 2.
use_ok('Dancer2::Plugin::FormValidator::Validator::Email');

# TEST 3.
use_ok('Dancer2::Plugin::FormValidator::Validator::EmailDns');

# TEST 4.
use_ok('Dancer2::Plugin::FormValidator::Validator::Same');

# TEST 5.
use_ok('Dancer2::Plugin::FormValidator::Validator::Enum');

# TEST 6.
use_ok('Dancer2::Plugin::FormValidator::Validator::Numeric');

# TEST 7.
use_ok('Dancer2::Plugin::FormValidator::Validator::Alpha');

# TEST 8.
use_ok('Dancer2::Plugin::FormValidator::Validator::AlphaNum');

# TEST 9.
use_ok('Dancer2::Plugin::FormValidator::Validator::Integer');

# TEST 10.
use_ok('Dancer2::Plugin::FormValidator::Validator::Min');

# TEST 11.
use_ok('Dancer2::Plugin::FormValidator::Validator::Max');

# TEST 12.
use_ok('Dancer2::Plugin::FormValidator::Validator::LengthMin');

# TEST 13.
use_ok('Dancer2::Plugin::FormValidator::Validator::LengthMax');

# TEST 14.
use_ok('Dancer2::Plugin::FormValidator::Validator::Accepted');
