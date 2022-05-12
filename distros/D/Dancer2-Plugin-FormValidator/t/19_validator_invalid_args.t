use strict;
use warnings;

use Test::More tests => 2;

use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Input;
use Dancer2::Plugin::FormValidator::Processor;

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

my $input = Dancer2::Plugin::FormValidator::Input->new(input => {});

# Test 1 test Validator profile.

eval {
    Dancer2::Plugin::FormValidator::Processor->new(
        config   => $config,
        input    => $input,
        profile  => Validator->new,
        registry => [],
    );
};

like(
    $@,
    qr/did not pass type constraint \(not DOES Dancer2::Plugin::FormValidator::Role::Profile\)/,
    'Check validator params',
);

# Test 2 test Validator input.

eval {
    Dancer2::Plugin::FormValidator::Processor->new(
        config   => $config,
        profile  => Validator->new,
        input    => '',
        registry => [],
    );
};

like(
    $@,
    qr/not isa Dancer2::Plugin::FormValidator::Input/,
    'Check validator params',
);
