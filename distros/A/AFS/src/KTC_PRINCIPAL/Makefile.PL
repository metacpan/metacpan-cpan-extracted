use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'	     => 'AFS::KTC_PRINCIPAL',
              'VERSION_FROM' => 'KTC_PRINCIPAL.pm', # finds $VERSION
              'PREREQ_PM'    => {}, # e.g., Module::Name => 1.1
              ($] >= 5.005 ?
               (AUTHOR   => 'Norbert E Gruener <nog@MPA-Garching.MPG.de>',
                ABSTRACT => 'handle the AFS structure ktc_principal') : () ),
             );
