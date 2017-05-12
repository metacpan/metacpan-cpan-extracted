######################################################################
# Makefile.PL for Acme::Prereq::B
# 2004, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Acme::Prereq::B',
    'VERSION_FROM' => 'lib/Acme/Prereq/B.pm', # finds $VERSION
    'PREREQ_PM'    => {
                        'Acme::Prereq::A' => 0,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Acme/Prereq/B.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
