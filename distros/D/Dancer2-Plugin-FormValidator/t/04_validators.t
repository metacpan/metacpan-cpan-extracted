use strict;
use warnings;
use utf8::all;
use Test::More tests => 72;

use Dancer2::Plugin::FormValidator::Validator::Accepted;
use Dancer2::Plugin::FormValidator::Validator::Alpha;
use Dancer2::Plugin::FormValidator::Validator::AlphaNum;
use Dancer2::Plugin::FormValidator::Validator::Enum;
use Dancer2::Plugin::FormValidator::Validator::Email;
use Dancer2::Plugin::FormValidator::Validator::EmailDns;
use Dancer2::Plugin::FormValidator::Validator::Integer;
use Dancer2::Plugin::FormValidator::Validator::LengthMax;
use Dancer2::Plugin::FormValidator::Validator::LengthMin;
use Dancer2::Plugin::FormValidator::Validator::Max;
use Dancer2::Plugin::FormValidator::Validator::Min;
use Dancer2::Plugin::FormValidator::Validator::Numeric;
use Dancer2::Plugin::FormValidator::Validator::Required;
use Dancer2::Plugin::FormValidator::Validator::Same;

my $validator;

# TEST 1.
## Check Dancer2::Plugin::FormValidator::Validators::Required.

$validator = Dancer2::Plugin::FormValidator::Validator::Required->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 1: Dancer2::Plugin::FormValidator::Validator::Required messages hash'
);

is(
    $validator->stop_on_fail,
    1,
    'TEST 1: Dancer2::Plugin::FormValidator::Validator::Required stop_on_fail',
);

isnt(
    $validator->validate('email', {}),
    1,
    'TEST 1: Dancer2::Plugin::FormValidator::Validator::Required not valid',
);

isnt(
    $validator->validate('email', {email => ''}),
    1,
    'TEST 1: Dancer2::Plugin::FormValidator::Validator::Required not valid',
);

is(
    $validator->validate('email', {email => 'alex'}),
    1,
    'TEST 1: Dancer2::Plugin::FormValidator::Validator::Required valid',
);

# TEST 2.
## Check Dancer2::Plugin::FormValidator::Validators::Email.

$validator = Dancer2::Plugin::FormValidator::Validator::Email->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 2: Dancer2::Plugin::FormValidator::Validator::Email messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 2: Dancer2::Plugin::FormValidator::Validator::Email stop_on_fail',
);

isnt(
    $validator->validate('email', {email => 'alexpan.org'}),
    1,
    'TEST 2: Dancer2::Plugin::FormValidator::Validator::Email not valid',
);

is(
    $validator->validate('email', {email => 'alex@cpan.org'}),
    1,
    'TEST 2: Dancer2::Plugin::FormValidator::Validator::Email valid',
);

# TEST 3.
## Check Dancer2::Plugin::FormValidator::Validators::EmailDns.

$validator = Dancer2::Plugin::FormValidator::Validator::EmailDns->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 3: Dancer2::Plugin::FormValidator::Validator::EmailDns messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 3: Dancer2::Plugin::FormValidator::Validator::EmailDns stop_on_fail',
);

isnt(
    $validator->validate('email', {email => 'alexpan@crfssfd.com'}),
    1,
    'TEST 3: Dancer2::Plugin::FormValidator::Validator::EmailDns not valid',
);

is(
    $validator->validate('email', {email => 'alex@cpan.org'}),
    1,
    'TEST 3: Dancer2::Plugin::FormValidator::Validator::EmailDns valid',
);

# TEST 4.
## Check Dancer2::Plugin::FormValidator::Validators::Same.

$validator = Dancer2::Plugin::FormValidator::Validator::Same->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 4: Dancer2::Plugin::FormValidator::Validators::Same messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 4: Dancer2::Plugin::FormValidator::Validators::Same stop_on_fail',
);

isnt(
    $validator->validate(
        'password',
        {password => 'pass', password_cnf => ''},
        'password_cnf'
    ),
    1,
    'TEST 4: Dancer2::Plugin::FormValidator::Validators::Same not valid',
);

isnt(
    $validator->validate(
        'password',
        {password => [], password_cnf => ''},
        'password_cnf'
    ),
    1,
    'TEST 4: Dancer2::Plugin::FormValidator::Validators::Same not valid',
);

isnt(
    $validator->validate(
        'password',
        {password => 'pass'},
        'password_cnf'
    ),
    1,
    'TEST 4: Dancer2::Plugin::FormValidator::Validators::Same not valid',
);

is(
    $validator->validate(
        'password',
        {password => 12345, password_cnf => 12345},
        'password_cnf'),
    1,
    'TEST 4: Dancer2::Plugin::FormValidator::Validators::Same valid',
);

is(
    $validator->validate(
        'password',
        {password => 'pass', password_cnf => 'pass'},
        'password_cnf'),
    1,
    'TEST 4: Dancer2::Plugin::FormValidator::Validators::Same valid',
);

# TEST 5.
## Check Dancer2::Plugin::FormValidator::Validators::Enum.

$validator = Dancer2::Plugin::FormValidator::Validator::Enum->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 5: Dancer2::Plugin::FormValidator::Validator::Enum messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 5: Dancer2::Plugin::FormValidator::Validator::Enum stop_on_fail',
);

isnt(
    $validator->validate('type', {type => 'child'}, 'credit', 'debit'),
    1,
    'TEST 5: Dancer2::Plugin::FormValidator::Validator::Enum not valid',
);

is(
    $validator->validate('type', {type => 'credit'}, 'credit', 'debit'),
    1,
    'TEST 5: Dancer2::Plugin::FormValidator::Validator::Enum valid',
);

# TEST 6.
## Check Dancer2::Plugin::FormValidator::Validators::Numeric.

$validator = Dancer2::Plugin::FormValidator::Validator::Numeric->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 6: Dancer2::Plugin::FormValidator::Validator::Numeric messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 6: Dancer2::Plugin::FormValidator::Validator::Numeric stop_on_fail',
);

isnt(
    $validator->validate('price', {price => '0.13d'}),
    1,
    'TEST 6: Dancer2::Plugin::FormValidator::Validator::Numeric not valid',
);

is(
    $validator->validate('price', {price => '0.13'}),
    1,
    'TEST 6: Dancer2::Plugin::FormValidator::Validator::Numeric valid',
);

# TEST 7.
## Check Dancer2::Plugin::FormValidator::Validators::Alpha.

$validator = Dancer2::Plugin::FormValidator::Validator::Alpha->new;

is(
    $validator->stop_on_fail,
    0,
    'TEST 7: Dancer2::Plugin::FormValidator::Validator::Alpha stop_on_fail',
);

isnt(
    $validator->validate('username', {username => 'Ahмед23'}, 'u'),
    1,
    'TEST 7: Dancer2::Plugin::FormValidator::Validator::Alpha not valid',
);

is(
    $validator->validate('username', {username => 'Ahmed'}, 'u'),
    1,
    'TEST 7: Dancer2::Plugin::FormValidator::Validator::Alpha valid',
);

is_deeply(
    $validator->message,
    {
        en => '%s must contain only alphabetical symbols',
        ru => '%s должно содержать только символы алфавита',
        de => '%s darf nur alphabetische Zeichen enthalten',
    },
    'TEST 7: Dancer2::Plugin::FormValidator::Validator::Alpha messages hash'
);

# TEST 8.
## Check Dancer2::Plugin::FormValidator::Validators::AlphaNum.

$validator = Dancer2::Plugin::FormValidator::Validator::AlphaNum->new;

is(
    $validator->stop_on_fail,
    0,
    'TEST 8: Dancer2::Plugin::FormValidator::Validator::AlphaNum stop_on_fail',
);

isnt(
    $validator->validate('username', {username => 'Ahмед23-'}, 'u'),
    1,
    'TEST 8: Dancer2::Plugin::FormValidator::Validator::AlphaNum not valid',
);

is(
    $validator->validate('username', {username => 'Ahмед_23'}, 'u'),
    1,
    'TEST 8: Dancer2::Plugin::FormValidator::Validator::AlphaNum valid',
);

is_deeply(
    $validator->message,
    {
        en => '%s must contain only alphabetical symbols and/or numbers 0-9',
        ru => '%s должно содержать только символы алфавита или/и цифры 0-9',
        de => '%s darf nur alphabetische Symbole und/oder Zahlen 0-9 enthalten',
    },
    'TEST 8: Dancer2::Plugin::FormValidator::Validator::AlphaNum messages hash'
);

# TEST 9.
## Check Dancer2::Plugin::FormValidator::Validators::Integer.

$validator = Dancer2::Plugin::FormValidator::Validator::Integer->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 9: Dancer2::Plugin::FormValidator::Validator::Integer messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 9: Dancer2::Plugin::FormValidator::Validator::Integer stop_on_fail',
);

isnt(
    $validator->validate('age', {age => '2a3'}),
    1,
    'TEST 9: Dancer2::Plugin::FormValidator::Validator::Integer: not valid',
);

isnt(
    $validator->validate('age', {age => '23.4'}),
    1,
    'TEST 9: Dancer2::Plugin::FormValidator::Validator::Integer not valid',
);

is(
    $validator->validate('age', {age => '23'}),
    1,
    'TEST 9: Dancer2::Plugin::FormValidator::Validator::Integer valid',
);

# TEST 10.
## Check Dancer2::Plugin::FormValidator::Validators::Min.

$validator = Dancer2::Plugin::FormValidator::Validator::Min->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 10: Dancer2::Plugin::FormValidator::Validator::Min messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 10: Dancer2::Plugin::FormValidator::Validator::Min stop_on_fail',
);

isnt(
    $validator->validate('age', {age => '23'}, '30'),
    1,
    'TEST 10: Dancer2::Plugin::FormValidator::Validator::Min not valid',
);

is(
    $validator->validate('age', {age => '23'}, '23'),
    1,
    'TEST 10: Dancer2::Plugin::FormValidator::Validator::Min valid',
);

# TEST 11.
## Check Dancer2::Plugin::FormValidator::Validators::Max.

$validator = Dancer2::Plugin::FormValidator::Validator::Max->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 11: Dancer2::Plugin::FormValidator::Validator::Max messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 11: Dancer2::Plugin::FormValidator::Validator::Max stop_on_fail',
);

isnt(
    $validator->validate('age', {age => '23'}, '18'),
    1,
    'TEST 11: Dancer2::Plugin::FormValidator::Validator::Max not valid',
);

is(
    $validator->validate('age', {age => '23'}, '30'),
    1,
    'TEST 11: Dancer2::Plugin::FormValidator::Validator::Max valid',
);

# TEST 12.
## Check Dancer2::Plugin::FormValidator::Validators::LengthMin.

$validator = Dancer2::Plugin::FormValidator::Validator::LengthMin->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 12: Dancer2::Plugin::FormValidator::Validator::LengthMin messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 12: Dancer2::Plugin::FormValidator::Validator::LengthMin stop_on_fail',
);

isnt(
    $validator->validate('name', {name => 'Вася'}, '5'),
    1,
    'TEST 12: Dancer2::Plugin::FormValidator::Validator::LengthMin not valid',
);

is(
    $validator->validate('name', {name => 'Вася'}, '4'),
    1,
    'TEST 12: Dancer2::Plugin::FormValidator::Validator::LengthMin valid',
);

# TEST 13.
## Check Dancer2::Plugin::FormValidator::Validators::LengthMax.

$validator = Dancer2::Plugin::FormValidator::Validator::LengthMax->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 13: Dancer2::Plugin::FormValidator::Validator::LengthMax messages hash'
);

is(
    $validator->stop_on_fail,
    0,
    'TEST 13: Dancer2::Plugin::FormValidator::Validator::LengthMax stop_on_fail',
);

isnt(
    $validator->validate('name', {name => 'Вася'}, '3'),
    1,
    'TEST 13: Dancer2::Plugin::FormValidator::Validator::LengthMax not valid',
);

is(
    $validator->validate('name', {name => 'Вася'}, '4'),
    1,
    'TEST 13: Dancer2::Plugin::FormValidator::Validator::LengthMax valid',
);

# TEST 14.
## Check Dancer2::Plugin::FormValidator::Validators::Accepted.

$validator = Dancer2::Plugin::FormValidator::Validator::Accepted->new;

is(
    ref $validator->message,
    'HASH',
    'TEST 14: Dancer2::Plugin::FormValidator::Validator::Accepted messages hash'
);

is(
    $validator->stop_on_fail,
    1,
    'TEST 14: Dancer2::Plugin::FormValidator::Validator::Accepted stop_on_fail',
);

isnt(
    $validator->validate('consent', {consent => '0'}),
    1,
    'TEST 14: Dancer2::Plugin::FormValidator::Validator::Accepted not valid',
);

isnt(
    $validator->validate('consent', {consent => 'no'}),
    1,
    'TEST 14: Dancer2::Plugin::FormValidator::Validator::Accepted not valid',
);

is(
    $validator->validate('consent', {consent => '1'}),
    1,
    'TEST 14: Dancer2::Plugin::FormValidator::Validator::Accepted valid',
);

is(
    $validator->validate('consent', {consent => 'yes'}),
    1,
    'TEST 14: Dancer2::Plugin::FormValidator::Validator::Accepted valid',
);


is(
    $validator->validate('consent', {consent => 'on'}),
    1,
    'TEST 14: Dancer2::Plugin::FormValidator::Validator::Accepted valid',
);

# TEST 15.
## Check Dancer2::Plugin::FormValidator::Validators::AlphaAscii.

$validator = Dancer2::Plugin::FormValidator::Validator::Alpha->new;

is(
    $validator->stop_on_fail,
    0,
    'TEST 15: Dancer2::Plugin::FormValidator::Validator::Alpha stop_on_fail',
);

isnt(
    $validator->validate('username', {username => 'Ahмед'}),
    1,
    'TEST 15: Dancer2::Plugin::FormValidator::Validator::Alpha not valid',
);

is(
    $validator->validate('username', {username => 'Ahmed'}),
    1,
    'TEST 15: Dancer2::Plugin::FormValidator::Validator::Alpha valid',
);

is_deeply(
    $validator->message,
    {
        en => '%s must contain only latin alphabetical symbols',
        ru => '%s должно содержать только символы латинского алфавита',
        de => '%s darf nur lateinische Zeichen enthalten',
    },
    'TEST 15: Dancer2::Plugin::FormValidator::Validator::Alpha messages hash'
);

# TEST 16.
## Check Dancer2::Plugin::FormValidator::Validators::AlphaNumAscii.

$validator = Dancer2::Plugin::FormValidator::Validator::AlphaNum->new;

is(
    $validator->stop_on_fail,
    0,
    'TEST 16: Dancer2::Plugin::FormValidator::Validator::AlphaNumAscii stop_on_fail',
);

isnt(
    $validator->validate('username', {username => 'Ahмед'}),
    1,
    'TEST 16: Dancer2::Plugin::FormValidator::Validator::AlphaNumAscii not valid',
);

is(
    $validator->validate('username', {username => 'Ahmed23'}),
    1,
    'TEST 16: Dancer2::Plugin::FormValidator::Validator::AlphaNumAscii valid',
);

is_deeply(
    $validator->message,
    {
        en => '%s must contain only latin alphabetical symbols',
        ru => '%s должно содержать только символы латинского алфавита',
        de => '%s darf nur lateinische Zeichen enthalten',
    },
    'TEST 16: Dancer2::Plugin::FormValidator::Validator::AlphaNumAscii messages hash'
);
