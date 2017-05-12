use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::YAML',
    AUTHOR              => 'Shawn Boyette <mdxi@cpan.org>',
    VERSION_FROM        => 'lib/Config/YAML.pm',
    ABSTRACT_FROM       => 'lib/Config/YAML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0.35,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-YAML-*' },
);
