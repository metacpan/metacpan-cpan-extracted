use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'	     => 'AFS::Cell',
              'VERSION_FROM' => 'Cell.pm', # finds $VERSION
              'PREREQ_PM'    => {}, # e.g., Module::Name => 1.1
              ($] >= 5.005 ?
               (AUTHOR   => 'Norbert E Gruener <nog@MPA-Garching.MPG.de>',
                ABSTRACT => 'administer AFS Cells') : () ),
             );
