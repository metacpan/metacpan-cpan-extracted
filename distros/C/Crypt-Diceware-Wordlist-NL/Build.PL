# -*- cperl; cperl-indent-level: 4 -*-
use 5.016;
use strict;
use warnings;
use Module::Build;
use lib 'inc';
use Crypt::Diceware::Wordlist::NL::Module::Build;

our $VERSION = v0.0.1;

Crypt::Diceware::Wordlist::NL::Module::Build->new(
    'module_name' => 'Crypt::Diceware::Wordlist::NL',
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
            'repository' =>
'https://bitbucket.org/rolandvanipenburg/crypt-diceware-wordlist-nl',
            'bugtracker' =>
'https://bitbucket.org/rolandvanipenburg/crypt-diceware-wordlist-nl/issues',
        },
        'x_authority' => 'cpan:IPENBURG',
    },
    'sign' => 1,
)->create_build_script;
