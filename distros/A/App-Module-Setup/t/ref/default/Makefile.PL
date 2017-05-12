use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Module::Setup',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/App/Module/Setup.pm',
    ABSTRACT_FROM       => 'lib/App/Module/Setup.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Module-Setup-*' },
);
