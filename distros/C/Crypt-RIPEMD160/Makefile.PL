#! /usr/local/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
    'DISTNAME'     => 'Crypt-RIPEMD160',
    'NAME'                => 'Crypt::RIPEMD160',
    'AUTHOR'              => 'Christian H. Geuer-Pollmann',
    'VERSION_FROM'  => 'lib/Crypt/RIPEMD160.pm',
    'ABSTRACT_FROM' => 'lib/Crypt/RIPEMD160.pm',
    'PL_FILES'            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'XSLoader'   => 0,
        'Test::More' => 0,  # For testing
    },
    'dist'                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'clean'               => { FILES => 'Crypt-RIPEMD160-*' },

    'OBJECT'       => q[RIPEMD160$(OBJ_EXT) rmd160$(OBJ_EXT) wrap_160$(OBJ_EXT)],

    META_MERGE  => {
        build_requires => {
            'Test::More' => 0,  # For testing
        },
        resources => {
            license => 'https://dev.perl.org/licenses/',
            homepage   => 'https://github.com/cpan-authors/Crypt-RIPEMD160',
            bugtracker => 'https://github.com/cpan-authors/Crypt-RIPEMD160/issues',
            repository => 'https://github.com/cpan-authors/Crypt-RIPEMD160',
        },
    },
);

