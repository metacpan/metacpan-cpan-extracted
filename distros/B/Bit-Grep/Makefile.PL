
use ExtUtils::MakeMaker;

WriteMakefile( NAME         => 'Bit::Grep',
               VERSION_FROM => 'lib/Bit/Grep.pm',
               PREREQ_PM    => { Test::More => 0 },
               AUTHOR       => 'Salvador Fandino <sfandino@yahoo,com>',
               INC          => '-I.'
             );
