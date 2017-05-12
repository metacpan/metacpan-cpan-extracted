#! /usr/local/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

my  $ENDIAN = ($Config{'byteorder'} eq '1234') ? 'LITTLE_ENDIAN' : 'BIG_ENDIAN';

WriteMakefile(
    'DISTNAME'     => 'Crypt-RIPEMD160',
    'NAME'                => 'Crypt::RIPEMD160',
    'AUTHOR'              => 'Christian H. Geuer-Pollmann',
    'VERSION_FROM'  => 'RIPEMD160.pm',
    'ABSTRACT_FROM' => 'RIPEMD160.pm',
    'PL_FILES'            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'Test::More' => 0,  # For testing
    },
    'dist'                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'clean'               => { FILES => 'Crypt-RIPEMD160-*' },

    'OBJECT'       => q[RIPEMD160$(OBJ_EXT) rmd160$(OBJ_EXT) wrap_160$(OBJ_EXT)],
    'CONFIG'       => ['byteorder'], # Used to determine 64-bitness
    'DEFINE'       => '-DPERL_BYTEORDER=$(BYTEORDER)',

    META_MERGE  => {
#        recommends => {
#            'Test::Pod::Coverage' => 1.04,
#            'Test::Pod' => 1.14,
#        },
        build_requires => {
            'Test::More' => 0,  # For testing
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/Crypt-RIPEMD160',
#            bugtracker => 'http://code.google.com/p/Crypt-RIPEMD160/issues/list',
            repository => 'http://github.com/toddr/Crypt-RIPEMD160/tree/master',
#            MailingList => 'http://groups.google.com/group/Crypt-RIPEMD160',
        },
    },
);

