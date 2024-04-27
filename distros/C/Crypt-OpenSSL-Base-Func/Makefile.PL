use strict;
use warnings;

use ExtUtils::MakeMaker;
#use Config;
use Crypt::OpenSSL::Guess;

# This is similar to what Crypt::OpenSSL::EC, Crypt::OpenSSL::RSA does.

WriteMakefile(
    NAME              => 'Crypt::OpenSSL::Base::Func',
    AUTHOR             => 'Pan Lanlan <abbypan@gmail.com>',
    VERSION_FROM      => 'Func.pm',
    ABSTRACT  => 'Crypt Base Functions, using the OpenSSL libraries', 
    'LICENSE'  => 'Mozilla_2_0', 
    'DISTNAME'         => 'Crypt-OpenSSL-Base-Func',
    PREREQ_PM         => { 
        'Carp' => 0.01,
        'Crypt::OpenSSL::Bignum' => 0.09,
        'Crypt::OpenSSL::EC' => 1.31,
        'Crypt::OpenSSL::Guess' => 0.12,
        'Math::BigInt' => 1.999815,
        'Test' => 0.01,
        'Test::More' => 0.01,
        'bignum' => 0.52, 
    }, 
    EXE_FILES => [ 'bin/ec_conv.pl' ], 
    'LIBS'   => [openssl_lib_paths() . ' -lssl -lcrypto'],
    DEFINE            => '-DPERL5 -DOPENSSL_NO_KRB5',
    'INC' => openssl_inc_paths(),    # e.g., '-I/usr/include/other'
    'MIN_PERL_VERSION' => 5.006,

    DEFINE            => '-DPERL5 -DOPENSSL_NO_KRB5',
    'dist'  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'clean' => { FILES    => 'Crypt-OpenSSL-Base-Func-*' },

    (
        $ExtUtils::MakeMaker::VERSION >= 6.46
        ? (
            'META_MERGE' => {
                recommends => {
                    'Crypt::OpenSSL::Bignum' => 0.09,
                },
                configure_requires => {
                    'Crypt::OpenSSL::Guess' => 0.12,
                },
                build_requires => {
                    'Test' => 0,    # For testing
                    'Carp' => 0.01,
                    'Crypt::OpenSSL::Bignum' => 0.09,
                    'Crypt::OpenSSL::EC' => 1.31,
                    'Crypt::OpenSSL::Guess' => 0.12,
                    'Math::BigInt' => 1.999815,
                    'Test' => 0.01,
                    'Test::More' => 0.01,
                    'bignum' => 0.52, 
                },
                resources => {
                    'license'    => 'http://dev.perl.org/licenses/',
                    'homepage'   => 'http://github.com/abbypan/Crypt-OpenSSL-Base-Func',
                    'bugtracker' => 'https://github.com/abbypan/Crypt-OpenSSL-Base-Func/issues',
                    'repository' => 'http://github.com/abbypan/Crypt-OpenSSL-Base-Func',
                }
            }
        )
        : ()
    ),
);
