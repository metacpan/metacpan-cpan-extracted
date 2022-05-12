use strict;
use warnings;

use Test::More tests => 3;
use FindBin;
use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Registry;
use Dancer2::Plugin::FormValidator::Input;
use Dancer2::Plugin::FormValidator::Validator;

require "$FindBin::Bin/lib/validator.pl";

my $config = Dancer2::Plugin::FormValidator::Config->new(
    config => {
        session => {
            namespace => '_form_validator'
        },
    }
);

my $registry = Dancer2::Plugin::FormValidator::Registry->new;

my $input = Dancer2::Plugin::FormValidator::Input->new(input => {
    name  => 'alex',
    email => 'alex@cpan.org',
    fraud => '123',
});

my $profile = Validator->new(profile_hash =>
    {
        name  => [qw(required)],
        email => [qw(required email)],
    }
);

my $validator = Dancer2::Plugin::FormValidator::Validator->new(
    config   => $config,
    registry => $registry,
);

my ($success, $valid, $invalid) = $validator->validate($profile, $input->get);

is(
    $success,
    1,
    'TEST 1: Check success',
);

is_deeply(
    [sort { $a cmp $b } @$valid],
    ['email', 'name'],
    'TEST 2: Check valid fields'
);

is_deeply(
    $invalid,
    [],
    'TEST 3: invalid'
);
