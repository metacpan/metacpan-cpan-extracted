use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Authentication::Credential::MultiFactor',
    VERSION_FROM      => 'lib/Catalyst/Authentication/Credential/MultiFactor.pm', # finds $VERSION
    PREREQ_PM         => {'Moose' => 0, 'namespace::autoclean' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Cédric Jeanneret <cpan@tengu.ch>') : ()),
);
