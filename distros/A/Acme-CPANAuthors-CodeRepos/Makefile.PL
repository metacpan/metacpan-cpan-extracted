use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Acme::CPANAuthors::CodeRepos',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Acme/CPANAuthors/CodeRepos.pm',
    ABSTRACT_FROM => 'lib/Acme/CPANAuthors/CodeRepos.pm',
    PREREQ_PM => {
        'Acme::CPANAuthors'   => '0.02',
        'Test::More'          => '0.47',
        'Test::UseAllModules' => '0.09',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.31
        ? ( LICENSE => 'perl' )
        : ()
    ),
);
