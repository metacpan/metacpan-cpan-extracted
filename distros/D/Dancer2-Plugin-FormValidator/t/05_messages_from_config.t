use strict;
use warnings;
use utf8::all;

use FindBin;
use Test::More tests => 2;
use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Registry;
use Dancer2::Plugin::FormValidator::Processor;

require "$FindBin::Bin/lib/validator.pl";

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

my $validator = Validator->new(profile_hash =>
    {
        name  => [qw(required)],
        email => [qw(required email)],
    }
);

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
        'name' => [
            'Name is needed from config'
        ],
        'email' => [
            'Email please use valid email from config'
        ]
    },
    'TEST 1: Check user defined messages(en) from config'
);

# TEST 2.
## Check user defined messages(ru) from validator class.

$config->language('ru');

is_deeply(
    $processor->result->messages,
    {
        'name' => [
            'Name это нужно из конфига'
        ],
        'email' => [
            'Email пожалуйста укажи правильную почту из конфига'
        ]
    },
    'TEST 2: Check user defined messages(ru) from config'
);
