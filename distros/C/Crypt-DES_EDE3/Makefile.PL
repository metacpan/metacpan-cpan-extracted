# $Id: Makefile.PL,v 1.1.1.1 2001/09/15 03:24:02 btrott Exp $

use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
    NAME => 'Crypt::DES_EDE3',
    DISTNAME => 'Crypt-DES_EDE3',
    VERSION_FROM => 'lib/Crypt/DES_EDE3.pm',
    AUTHOR => 'Benjamin Trott <ben@rhumba.pair.com>',
    ABSTRACT => 'Triple-DES EDE encryption/decryption',
    PREREQ_PM => {
        'Crypt::DES' => 0,
    },
);
