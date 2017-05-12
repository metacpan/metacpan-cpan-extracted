
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Algorithm::RectanglesContainingDot',
               VERSION_FROM => 'lib/Algorithm/RectanglesContainingDot.pm',
               PREREQ_PM => { Test::More => 0 },
               ABSTRACT_FROM => 'lib/Algorithm/RectanglesContainingDot.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>');
