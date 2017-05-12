use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
               NAME          => "Algorithm::Metric::Chessboard",
               ABSTRACT_FROM => "lib/Algorithm/Metric/Chessboard.pm",
               VERSION_FROM  => "lib/Algorithm/Metric/Chessboard.pm",
               PREREQ_PM     => {
                                  Carp => 0,
                                },
             );
