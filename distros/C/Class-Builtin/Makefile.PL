#
# $Id: Makefile.PL,v 0.3 2009/07/29 09:03:04 dankogai Exp $
#
use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Class::Builtin',
    AUTHOR        => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM  => 'lib/Class/Builtin.pm',
    ABSTRACT_FROM => 'lib/Class/Builtin.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'   => 0,
        'Encode'       => 0,
        'Data::Dumper' => 0,
        'Scalar::Util' => 0,
        'List::Util'   => 0,
    },
    ( $ExtUtils::MakeMaker::VERSION >= 6.46
        ? ( META_MERGE => { resources => {
            repository => 'http://github.com/dankogai/p5-class-builtin' } } )
        : () ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Class-Builtin-*' },
);
