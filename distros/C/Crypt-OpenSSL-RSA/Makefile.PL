use strict;
use warnings;
use Config;

use 5.006;
use ExtUtils::MakeMaker 6.48;
use Crypt::OpenSSL::Guess qw(openssl_inc_paths openssl_lib_paths openssl_version);

my ($major, $minor, $patch) = openssl_version(); 
print "OpenSSL version: $major.$minor $patch", "\n";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $libs = ' -lssl -lcrypto';
if ( $Config{osname} eq 'aix' ) {
  $libs = $libs . ' -lz';
}

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
    'LIBS'   => [openssl_lib_paths() . $libs],
    'LDDLFLAGS' => openssl_lib_paths() . ' ' . $Config{lddlflags},
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
            'homepage'   => 'http://github.com/cpan-authors/Crypt-OpenSSL-RSA',
            'bugtracker' => 'https://github.com/cpan-authors/Crypt-OpenSSL-RSA/issues',
            'repository' => 'http://github.com/cpan-authors/Crypt-OpenSSL-RSA',
        }
    }
);
