#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Data::Money',
    AUTHOR             => q{Corey Watson <gphat@cpan.org>},
    VERSION_FROM       => 'lib/Data/Money.pm',
    ABSTRACT_FROM      => 'lib/Data/Money.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'      => '1.001014',
        'Test::utf8'      => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'Moo'                      => '2.000000',
        'namespace::clean'         => '0.24',
        'Moo::Role'                => '2.000000',
        'Throwable'                => 0,
        'Math::BigFloat'           => '1.999704',
        'Locale::Currency'         => '2.07',
        'Locale::Currency::Format' => '1.22',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Money-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides  => {
            'Data::Money'                                       => { file => 'lib/Data/Money.pm',                                     version => '0.19' },
            'Data::Money::BaseException'                        => { file => 'lib/Data/Money/BaseException.pm',                       version => '0.19' },
            'Data::Money::BaseException::ExcessivePrecision'    => { file => 'lib/Data/Money/BaseException/ExcessivePrecision.pm',    version => '0.19' },
            'Data::Money::BaseException::InvalidCurrencyCode'   => { file => 'lib/Data/Money/BaseException/InvalidCurrencyCode.pm',   version => '0.19' },
            'Data::Money::BaseException::InvalidCurrencyFormat' => { file => 'lib/Data/Money/BaseException/InvalidCurrencyFormat.pm', version => '0.19' },
            'Data::Money::BaseException::MismatchCurrencyType'  => { file => 'lib/Data/Money/BaseException/MismatchCurrencyType.pm',  version => '0.19' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Data-Money.git',
                web  => 'https://github.com/manwar/Data-Money',
            },
        }})
     : ()
    ),
);
