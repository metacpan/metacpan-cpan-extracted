use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::Changelog',
    VERSION_FROM  => 'lib/App/Changelog.pm',
    PREREQ_PM     => {
        'Test::MockObject' => 0,
    },
    ABSTRACT      => 'Simple command-line CHANGELOG.md generator written in Perl',
    AUTHOR        => 'Luiz Felipe de Castro Vilas Boas <luizfelipecastrovb@gmail.com>',
    LICENSE       => 'MIT',
    META_MERGE    => {
        resources => {
            repository => 'https://gitlab.com/olooeez/app-changelog',
        },
    },
    INSTALLDIRS => 'site',
    EXE_FILES   => ['script/changelog'],
);
