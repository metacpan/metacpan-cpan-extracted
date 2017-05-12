use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::NEXUS::Import',
    AUTHOR              => 'LIMAONE <limaone@cpan.org>',
    VERSION_FROM        => 'lib/Bio/NEXUS/Import.pm',
    ABSTRACT_FROM       => 'lib/Bio/NEXUS/Import.pm',
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
            ('LICENSE'  => 'perl')         : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Bio::NEXUS'    => 0.67,
    },
    (   ( ExtUtils::MakeMaker->VERSION() gt '6.46' )
        ? ( META_MERGE => {
                resources => {
                    repository => 'http://github.com/lima1/p5-bio-nexus-import',
                },
            }
            )
        : ()
    ),
    EXE_FILES           => [ 
                  'bin/phylip2nex.pl',
                           ],

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-NEXUS-Import-*' },
);
