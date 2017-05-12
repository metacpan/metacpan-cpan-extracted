
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Algorithm::RectanglesContainingDot_XS',
               VERSION_FROM => 'lib/Algorithm/RectanglesContainingDot_XS.pm',
               PREREQ_PM => { Test::More => 0,
                              Algorithm::RectanglesContainingDot => '0.02' },
               ABSTRACT_FROM => 'lib/Algorithm/RectanglesContainingDot_XS.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS => [''],
               DEFINE => '',
               INC => '-I.' );
