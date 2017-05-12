
require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Algorithm::BreakOverlappingRectangles',
               VERSION_FROM => 'lib/Algorithm/BreakOverlappingRectangles.pm',
               PREREQ_PM => { 'Algorithm::RectanglesContainingDot' => 0, # only for testing
                              'Test::More' => 0 },
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS => [''],
               DEFINE => '',
               INC => '-I.',
               # OPTIMIZE => "-g -O0",
             );
