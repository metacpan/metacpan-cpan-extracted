use strict;
use warnings;

#Modify From https://metacpan.org/pod/Crypt::OpenSSL::RSA

use ExtUtils::MakeMaker;
use Crypt::OpenSSL::Guess qw(openssl_inc_paths openssl_lib_paths);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'             => 'Crypt::OpenSSL::PKCS::Func',
    AUTHOR             => 'Lanlan Pan <abbypan@gmail.com>',
    'VERSION_FROM'     => 'Func.pm',                              # finds $VERSION
    'DISTNAME'         => 'Crypt-OpenSSL-PKCS-Func',
    'ABSTRACT'    => 'PKCS Functions, using the OpenSSL libraries',
    'MIN_PERL_VERSION' => 5.006,
    'PL_FILES'         => {},
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    'PREREQ_PM' => {
        'Test::More'             => 0,
    },
    'OBJECT' => 'Func.o',
    'LIBS'   => [openssl_lib_paths() . ' -lssl -lcrypto'],
    'DEFINE' => '-DPERL5 -DOPENSSL_NO_KRB5',

    # perl-5.8/gcc-3.2 needs -DPERL5, and redhat9 likes -DOPENSSL_NO_KRB5
    'INC' => openssl_inc_paths(),    # e.g., '-I/usr/include/other'

    'dist'  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'clean' => { FILES    => 'Crypt-OpenSSL-PKCS-*' },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.46
        ? (
            'META_MERGE' => {
                recommends => {
                    #'Crypt::OpenSSL::Bignum' => 0,
                },
                configure_requires => {
                    #'Crypt::OpenSSL::Guess' => '0.11',
                },
                build_requires => {
                    'Test' => 0,    # For testing
                },
                resources => {
                    'license'    => 'http://dev.perl.org/licenses/',
                    'homepage'   => 'http://github.com/abbypan/Crypt-OpenSSL-PKCS-Func',
                    'bugtracker' => 'https://github.com/abbypan/Crypt-OpenSSL-PKCS-Func/issues',
                    'repository' => 'http://github.com/abbypan/Crypt-OpenSSL-PKCS-Func',
                }
            }
          )
        : ()
    ),
);

