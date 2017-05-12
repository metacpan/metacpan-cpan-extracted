######################################################################
# Makefile.PL for Acme::Prereq::A
# 2004, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Acme::Prereq::A',
    'VERSION_FROM' => 'lib/Acme/Prereq/A.pm', # finds $VERSION
    'PREREQ_PM'    => {
                         'Acme::Prereq::B' => 0,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Acme/Prereq/A.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
