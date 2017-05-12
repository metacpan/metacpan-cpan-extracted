use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Data::FR::Town',
    AUTHOR        => q{Arnaud (Arhuman) ASSAD <arhuman@gmail.com>},
    VERSION_FROM  => 'lib/Data/FR/Town.pm',
    ABSTRACT_FROM => 'lib/Data/FR/Town.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
       ? ( 'LICENSE' => 'perl' )
       : () ),
    PL_FILES   => {},
    PREREQ_PM  => { 'Test::More' => 0, },
    META_MERGE => { 
                    resources => { 
                        repository => 'https://github.com/arhuman/Data-FR-Town',
                        bugtracker => 'https://github.com/arhuman/Data-FR-Town/issues'
                    },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Data-FR-Town-*' },
);
