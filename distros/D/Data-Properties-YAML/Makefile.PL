use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Properties::YAML',
    VERSION_FROM      => 'lib/Data/Properties/YAML.pm', # finds $VERSION
    PREREQ_PM         => {
        YAML => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Properties/YAML.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@localdomain>') : ()),
);
