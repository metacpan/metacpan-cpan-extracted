use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Agents::Bureau',
    AUTHOR              => 'Roger Hall <rogerhall@cpan.org>',
    VERSION_FROM        => 'lib/Agents/Bureau.pm',
    ABSTRACT_FROM       => 'lib/Agents/Bureau.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Agents-Bureau-*' },
);
