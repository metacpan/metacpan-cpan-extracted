#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'App::ValidateBankAccount',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/App/ValidateBankAccount.pm',
    ABSTRACT_FROM      => 'lib/App/ValidateBankAccount.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/validate-bank-account' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES      => {
        'Test::More'    => 0,
        'Capture::Tiny' => '0.28',
    },
    PREREQ_PM => {
        'Types::Standard'            => '1.000005',
        'MooX::Options'              => '4.023',
        'Moo'                        => '2.000000',
        'namespace::autoclean'       => '0.28',
        'BankAccount::Validator::UK' => '0.46',
        'Encode::Locale'             => '1.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-ValidateBankAccount-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'App::ValidateBankAccount'         => { file => 'lib/App/ValidateBankAccount.pm'       , version => '0.06' },
            'App::ValidateBankAccount::Option' => { file => 'lib/App/ValidateBankAccount/Option.pm', version => '0.06' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/App-ValidateBankAccount.git',
                web  => 'https://github.com/manwar/App-ValidateBankAccount',
            },
        }})
     : ()
    ),
);
