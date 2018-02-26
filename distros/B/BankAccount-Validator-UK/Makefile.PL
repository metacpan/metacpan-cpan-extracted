#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'BankAccount::Validator::UK',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/BankAccount/Validator/UK.pm',
    ABSTRACT_FROM      => 'lib/BankAccount/Validator/UK.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => '0.09',
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'autodie'              => '2.26',
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
        'File::Share'          => '0.25',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'BankAccount-Validator-UK-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'BankAccount::Validator::UK'       => { file => 'lib/BankAccount/Validator/UK.pm'     , version => '0.36' },
            'BankAccount::Validator::UK::Rule' => { file => 'lib/BankAccount/Validator/UK/Rule.pm', version => '0.36' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/BankAccount-Validator-UK.git',
                web  => 'https://github.com/manwar/BankAccount-Validator-UK',
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';
