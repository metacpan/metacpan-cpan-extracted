use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker 6.48;
use Crypt::OpenSSL::Guess qw(openssl_inc_paths openssl_lib_paths);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'             => 'Crypt::OpenSSL::RSA',
    'AUTHOR'           => 'Ian Robertson <iroberts@cpan.org>',
    'VERSION_FROM'     => 'RSA.pm',                              # finds $VERSION
    'DISTNAME'         => 'Crypt-OpenSSL-RSA',
    'ABSTRACT_FROM'    => 'RSA.pm',
    'MIN_PERL_VERSION' => 5.006,
    'PL_FILES'         => {},
    'LICENSE'          => 'perl',
    'PREREQ_PM' => {
        'Crypt::OpenSSL::Random' => 0,
        'Test::More'             => 0,
    },
    'OBJECT' => 'RSA.o',
    'LIBS'   => [openssl_lib_paths() . ' -lssl -lcrypto'],
    'DEFINE' => '-DPERL5 -DOPENSSL_NO_KRB5',

    # perl-5.8/gcc-3.2 needs -DPERL5, and redhat9 likes -DOPENSSL_NO_KRB5
    'INC' => openssl_inc_paths(),    # e.g., '-I/usr/include/other'

    'dist'  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'clean' => { FILES    => 'Crypt-OpenSSL-RSA-*' },
    'META_MERGE' => {
        recommends => {
            'Crypt::OpenSSL::Bignum' => 0,
        },
        configure_requires => {
            'Crypt::OpenSSL::Guess' => '0.11',
        },
        build_requires => {
            'Test' => 0,    # For testing
        },
        resources => {
            'license'    => 'http://dev.perl.org/licenses/',
            'homepage'   => 'http://github.com/toddr/Crypt-OpenSSL-RSA',
            'bugtracker' => 'https://github.com/toddr/Crypt-OpenSSL-RSA/issues',
            'repository' => 'http://github.com/toddr/Crypt-OpenSSL-RSA',
        }
    }
);
