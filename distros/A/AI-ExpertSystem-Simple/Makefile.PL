use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'AI::ExpertSystem::Simple',
    VERSION_FROM => 'lib/AI/ExpertSystem/Simple.pm',
    EXE_FILES    => [
						'bin/simpleshell',
						'bin/consult'
					],
    PREREQ_PM    => {
        'XML::Twig' => 0,
    },
);
