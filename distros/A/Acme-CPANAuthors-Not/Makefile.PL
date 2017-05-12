use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Acme::CPANAuthors::Not',
    AUTHOR        => 'Steve Fink <sfink@cpan.org>',
    VERSION_FROM  => 'lib/Acme/CPANAuthors/Not.pm',
    ABSTRACT_FROM => 'lib/Acme/CPANAuthors/Not.pm',
    PREREQ_PM => {
        'Acme::CPANAuthors'         => '0.01',
        'Test::More'                => '0.47',
        'Test::UseAllModules'       => '0.09',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.31
        ? ( LICENSE => 'perl' )
        : ()
    ),
);
