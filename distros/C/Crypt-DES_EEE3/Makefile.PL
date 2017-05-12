# $Id: Makefile.PL,v 1.1.1.1 2001/09/15 03:24:02 btrott Exp $

use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
    NAME => 'Crypt::DES_EEE3',
    DISTNAME => 'Crypt-DES_EEE3',
    VERSION_FROM => 'lib/Crypt/DES_EEE3.pm',
    AUTHOR => 'Benjamin Trott <ben@rhumba.pair.com>',
    ABSTRACT => 'Triple-DES EEE encryption/decryption',
    PREREQ_PM => {
        'Crypt::DES' => 0,
        'Crypt::DES_EDE3' => 0,
    },
);
