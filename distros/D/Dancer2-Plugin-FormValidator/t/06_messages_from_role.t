use strict;
use warnings;
use utf8::all;
use Test::More tests => 2;

use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Registry;
use Dancer2::Plugin::FormValidator::Processor;

package Validator {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::ProfileHasMessages';

    sub profile {
        return {
            name     => [ qw(required) ],
            email    => [ qw(required email) ],
            password => [ qw(required) ]
        };
    };

    sub messages {
        return {
            name => {
                required => {
                    en => '%s from profile is needed',
                    ru => 'Имя из профиля нужно',
                },
            },
            email => {
                required => {
                    en => '%s from profile is needed',
                    ru => 'Почта из профиля нужно',
                },
                email => {
                    en => '%s please use valid email',
                    ru => '%s пожалуйста укажи правильную почту',
                }
            }
        }
    }
}

my $config = Dancer2::Plugin::FormValidator::Config->new(
    config => {
        session  => {
            namespace => '_form_validator'
        },
        messages => {
            language => 'en',
            validators => {
                required => {
                    en => '%s is needed from config',
                    ru => '%s это нужно из конфига',
                },
                email    => {
                    en => '%s please use valid email from config',
                    ru => '%s пожалуйста укажи правильную почту из конфига',
                }
            }
        }
    }
);

my $validator = Validator->new;
my $registry  = Dancer2::Plugin::FormValidator::Registry->new;
my $input = {
    email => 'alexсpan.org',
};

my $processor = Dancer2::Plugin::FormValidator::Processor->new(
    input             => $input,
    registry          => $registry,
    config            => $config,
    validator_profile => $validator,
);


# TEST 1.
## Check user defined messages(en) from validator class.

is_deeply(
    $processor->result->messages,
    {
        'name'   => [
            'Name from profile is needed'
        ],
        'email'  => [
            'Email please use valid email'
        ],
        password => [
            'Password is needed from config'
        ],
    },
    'TEST 1: Check user defined messages(en) from validator class'
);

# TEST 2.
## Check user defined messages(ru) from validator class.

$config->language('ru');

is_deeply(
    $processor->result->messages,
    {
        'name' => [
            'Имя из профиля нужно'
        ],
        'email' => [
            'Email пожалуйста укажи правильную почту'
        ],
        password => [
            'Password это нужно из конфига'
        ],
    },
    'TEST 2: Check user defined messages(ru) from validator class'
);
