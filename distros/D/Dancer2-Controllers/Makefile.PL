#!/usr/bin/env perl
use strict;
use warnings;

use utf8;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Dancer2::Controllers',
    VERSION_FROM => 'lib/Dancer2/Controllers.pm',
    ABSTRACT     =>
      qq{A module to allow Spring-Boot esq route declarations in Dancer2},
    license    => 'mit',
    META_MERGE => {
        dynamic_config => 0,
        'meta-spec'    => { version   => 2 },
        no_index       => { directory => [ 'examples', 't' ] },
        prereqs        => { runtime   => { requires => { perl => '5.024' } } },
        resources      => {
            bugtracker => {
                web =>
                  'https://github.com/rawleyfowler/Dancer2-Controllers/issues'
            },
            license    => [qq{http://www.opensource.org/licenses/mit}],
            repository => {
                type => 'git',
                url  => 'https://github.com/rawleyfowler/Dancer2-Controllers'
            }
        },
    },
    TEST_REQUIRES => {
        'Test::Simple'          => '1.302195',
        'HTTP::Request::Common' => '6.45',
        'Test::Exception'       => '0.43'
    },
    PREREQ_PM => {
        'Dancer2'                  => '1.1.0',
        'MooseX::MethodAttributes' => '0.32',
        'Moose'                    => '2.2207',
        'Attribute::Handlers'      => '0.99',
        'namespace::clean'         => '0.27'
    },
    test => { TESTS => 't/*.t t/*/*.t it/*.t it/*/*.t' }
);
