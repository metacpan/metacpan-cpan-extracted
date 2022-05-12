use strict;
use warnings;
use Test::More tests => 14;

# TEST 1.
use_ok('Dancer2::Plugin::FormValidator');

# TEST 2.
use_ok('Dancer2::Plugin::FormValidator::Validator');

# TEST 3.
use_ok('Dancer2::Plugin::FormValidator::Config');

# TEST 4.
use_ok('Dancer2::Plugin::FormValidator::Processor');

# TEST 5.
use_ok('Dancer2::Plugin::FormValidator::Registry');

# TEST 6.
use_ok('Dancer2::Plugin::FormValidator::Result');

# TEST 7.
use_ok('Dancer2::Plugin::FormValidator::Role::Profile');

# TEST 8.
use_ok('Dancer2::Plugin::FormValidator::Role::HasMessages');

# TEST 9.
use_ok('Dancer2::Plugin::FormValidator::Role::ProfileHasMessages');

# TEST 10.
use_ok('Dancer2::Plugin::FormValidator::Role::Validator');

# TEST 11.
use_ok('Dancer2::Plugin::FormValidator::Role::Extension');

# TEST 12.
use_ok('Dancer2::Plugin::FormValidator::Factory::Extensions');

# TEST 13.
use_ok('Dancer2::Plugin::FormValidator::Factory::Messages');

# TEST 14.
use_ok('Dancer2::Plugin::FormValidator::Input');
