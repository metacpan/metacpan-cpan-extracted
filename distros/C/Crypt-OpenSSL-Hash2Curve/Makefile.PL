use strict;
use warnings;

use ExtUtils::MakeMaker;
#use Config;
use Crypt::OpenSSL::Guess;

# This is similar to what Crypt::OpenSSL::EC, Crypt::OpenSSL::RSA does.

WriteMakefile(
    NAME              => 'Crypt::OpenSSL::Hash2Curve',
    AUTHOR             => 'Pan Lanlan <abbypan@gmail.com>',
    VERSION_FROM      => 'Hash2Curve.pm',
    ABSTRACT  => 'hash to curve', 
    'LICENSE'  => 'Mozilla_2_0', 
    'DISTNAME'         => 'Crypt-OpenSSL-Hash2Curve',
    PREREQ_PM         => { 
        'Crypt::OpenSSL::Guess' => 0.12,
        'Crypt::OpenSSL::Bignum' => 0.09,
        'Crypt::OpenSSL::EC' => 1.31,
        'Crypt::OpenSSL::Base::Func' => 0.03,
        'Math::BigInt' => 1.999815,
        'Carp' => 0.01,
        'Test::More' => 0.01,
        'Test' => 0.01,
        'bignum' => 0.52, 
                          }, 
    'LIBS'   => [openssl_lib_paths() . ' -lssl -lcrypto'],
    DEFINE            => '-DPERL5 -DOPENSSL_NO_KRB5',
    'INC' => openssl_inc_paths(),    # e.g., '-I/usr/include/other'
    'MIN_PERL_VERSION' => 5.006,

    DEFINE            => '-DPERL5 -DOPENSSL_NO_KRB5',
    'dist'  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'clean' => { FILES    => 'Crypt-OpenSSL-Hash2Curve-*' },

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
                    'Crypt::OpenSSL::Guess' => 0.12,
                },
                resources => {
                    'license'    => 'http://dev.perl.org/licenses/',
                    'homepage'   => 'http://github.com/abbypan/Crypt-OpenSSL-Hash2Curve',
                    'bugtracker' => 'https://github.com/abbypan/Crypt-OpenSSL-Hash2Curve/issues',
                    'repository' => 'http://github.com/abbypan/Crypt-OpenSSL-Hash2Curve',
                }
            }
        )
        : ()
    ),
);
