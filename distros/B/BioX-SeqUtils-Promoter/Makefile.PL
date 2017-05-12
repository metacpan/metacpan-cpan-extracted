use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BioX::SeqUtils::Promoter',
    AUTHOR              => 'Charles Stephen Embry <cstephene@cpan.org>',
   VERSION_FROM        => 'lib/BioX/SeqUtils/Promoter.pm',
     ABSTRACT            => 'lib/BioX/SeqUtils/Promoter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
     dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BioX-SeqUtils-Promoter-*' },
    );

