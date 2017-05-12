######################################################################
# Makefile.PL for Acme::Prereq::None
# 2007, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Acme::Prereq::None',
    'VERSION_FROM' => 'lib/Acme/Prereq/None.pm', # finds $VERSION
    'PREREQ_PM'    => {
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Acme/Prereq/None.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
