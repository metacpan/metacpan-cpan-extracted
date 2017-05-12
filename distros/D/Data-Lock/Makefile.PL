#
# $Id: Makefile.PL,v 1.0 2013/04/03 06:49:25 dankogai Exp $
#
use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Lock',
    AUTHOR              => 'Dan Kogai <dankogai+cpan@gmail.com>',
    VERSION_FROM        => 'lib/Data/Lock.pm',
    ABSTRACT_FROM       => 'lib/Data/Lock.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Lock-*' },
);
