use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Agents::Platform',
    AUTHOR              => 'Roger Hall <rogerhall@cpan.org>',
    VERSION_FROM        => 'lib/Agents/Platform.pm',
    ABSTRACT_FROM       => 'lib/Agents/Platform.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Agents-Platform-*' },
);
