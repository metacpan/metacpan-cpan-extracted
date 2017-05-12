

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'C::Analyzer',
    VERSION_FROM => 'lib/C/Analyzer.pm', # finds \$VERSION
    AUTHOR       => 'Sreekanth Kocharlakota (conflictanalyzer@gmail.com)',
    ABSTRACT     => 'C Static source code analyzer',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
