# $Id: Makefile.PL,v 1.2 2001/03/22 20:23:03 btrott Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Data::Buffer',
    DISTNAME => 'Data-Buffer',
    VERSION_FROM => 'Buffer.pm',
    AUTHOR => 'Benjamin Trott <ben@rhumba.pair.com>',
    ABSTRACT => 'Read/write buffer class',
);
