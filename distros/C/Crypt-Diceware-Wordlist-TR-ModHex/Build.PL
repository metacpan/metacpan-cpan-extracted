# -*- cperl; cperl-indent-level: 4 -*-
use 5.016;
use strict;
use warnings;
use Module::Build;
use lib 'inc';
use Crypt::Diceware::Wordlist::TR::ModHex::Module::Build;

our $VERSION = v0.0.2;

Crypt::Diceware::Wordlist::TR::ModHex::Module::Build->new(
    'module_name' => 'Crypt::Diceware::Wordlist::TR::ModHex',
    'license'     => 'perl',
    'dist_author' => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    'requires'    => {
        'perl'     => '5.16.0',
        'Readonly' => 1.03,
    },
    'build_requires' => {},
    'test_requires'  => {
        'Test::More' => 0.86,
    },
    'meta_merge' => {
        'resources' => {
            'repository' => 'https://bitbucket.org/rolandvanipenburg/'
              . 'crypt-diceware-wordlist-tr-modhex',
            'bugtracker' => 'https://bitbucket.org/rolandvanipenburg/'
              . 'crypt-diceware-wordlist-tr-modhex/issues',
        },
        'x_authority' => 'cpan:IPENBURG',
    },
    'sign' => 1,
)->create_build_script;
