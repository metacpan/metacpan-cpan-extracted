use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bundle::COG',
    AUTHOR              => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM        => 'lib/Bundle/COG.pm',
    ABSTRACT_FROM       => 'lib/Bundle/COG.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bundle-COG-*' },
);
