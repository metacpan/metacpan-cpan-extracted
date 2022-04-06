use strict;
use warnings;
use utf8::all;
use Test::More tests => 15;

use Dancer2::Plugin::FormValidator::Extension::Password::Simple;
use Dancer2::Plugin::FormValidator::Extension::Password::Robust;
use Dancer2::Plugin::FormValidator::Extension::Password::Hard;

my $validator;

# TEST 1.
## Dancer2::Plugin::FormValidator::Extension::Password::Simple.

$validator = Dancer2::Plugin::FormValidator::Extension::Password::Simple->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 1: Dancer2::Plugin::FormValidator::Extension::Password::Simple messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 1: Dancer2::Plugin::FormValidator::Extension::Password::Simple stop_on_fail',
);

isnt(
    $validator->validate('password', {password => 'fg-Afqwdca@'}),
    1,
    'TEST 1: Dancer2::Plugin::FormValidator::Extension::Password::Simple not valid',
);

isnt(
    $validator->validate('password', {password => 'fsflAf'}),
    1,
    'TEST 1: Dancer2::Plugin::FormValidator::Extension::Password::Simple not valid',
);

is(
    $validator->validate('password', {password => 'fg12fasaf'}),
    1,
    'TEST 1: Dancer2::Plugin::FormValidator::Extension::Password::Simple valid',
);

# TEST 2.
## Dancer2::Plugin::FormValidator::Extension::Password::Robust.

$validator = Dancer2::Plugin::FormValidator::Extension::Password::Robust->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 2: Dancer2::Plugin::FormValidator::Extension::Password::Robust messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 2: Dancer2::Plugin::FormValidator::Extension::Password::Robust stop_on_fail',
);

isnt(
    $validator->validate('password', {password => 'fg12-Af'}),
    1,
    'TEST 2: Dancer2::Plugin::FormValidator::Extension::Password::Robust not valid',
);

isnt(
    $validator->validate('password', {password => 'fg12adsflAf'}),
    1,
    'TEST 2: Dancer2::Plugin::FormValidator::Extension::Password::Robust not valid',
);

is(
    $validator->validate('password', {password => 'fg12@afl'}),
    1,
    'TEST 2: Dancer2::Plugin::FormValidator::Extension::Password::Robust valid',
);

# TEST 3.
## Dancer2::Plugin::FormValidator::Extension::Password::Hard.

$validator = Dancer2::Plugin::FormValidator::Extension::Password::Hard->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 3: Dancer2::Plugin::FormValidator::Extension::Password::Hard messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 3: Dancer2::Plugin::FormValidator::Extension::Password::Hard stop_on_fail',
);

isnt(
    $validator->validate('password', {password => 'fg12@afl'}),
    1,
    'TEST 3: Dancer2::Plugin::FormValidator::Extension::Password::Hard not valid',
);

isnt(
    $validator->validate('password', {password => 'fg12adsflaf'}),
    1,
    'TEST 3: Dancer2::Plugin::FormValidator::Extension::Password::Hard not valid',
);

is(
    $validator->validate('password', {password => 'fg12@Afl'}),
    1,
    'TEST 3: Dancer2::Plugin::FormValidator::Extension::Password::Hard valid',
);
