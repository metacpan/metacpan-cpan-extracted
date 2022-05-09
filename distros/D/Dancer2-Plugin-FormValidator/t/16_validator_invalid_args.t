use strict;
use warnings;

use Test::More tests => 2;

use Dancer2::Plugin::FormValidator::Validator;
use Dancer2::Plugin::FormValidator::Config;

package Validator {
    use Moo;
}

my $config = Dancer2::Plugin::FormValidator::Config->new(
    config => {
        session  => {
            namespace => '_form_validator'
        }
    },
);

# Test 1 test Validator profile.

eval {
    Dancer2::Plugin::FormValidator::Validator->new(
        config            => $config,
        input             => {},
        extensions        => [],
        validator_profile => Validator->new,
    );
};

like(
    $@,
    qr/did not pass type constraint \(not DOES Dancer2::Plugin::FormValidator::Role::Profile\)/,
    'Check validator params',
);

# Test 2 test Validator input.

eval {
    Dancer2::Plugin::FormValidator::Validator->new(
        config            => $config,
        input             => '',
        extensions        => [],
        validator_profile => Validator->new,
    );
};

like(
    $@,
    qr/did not pass type constraint "HashRef"/,
    'Check validator params',
);