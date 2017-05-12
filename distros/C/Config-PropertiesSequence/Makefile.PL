use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Config::PropertiesSequence',
    VERSION         => 1.003,
    PREREQ_PM         => {"Config::Properties" => 0.56,
                            "Carp::Assert" => 0.17 }, # e.g., Module::Name => 1.1
#    DISTNAME => q(Config::PropertiesSequence.pm),
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Config/PropertiesSequence.pm', # retrieve abstract from module
       AUTHOR         => 'Mark Clements <mark.clements@kcl.ac.uk>') : ()),
    'linkext'   => { LINKTYPE=>'' },   
    'dist'      => {'COMPRESS'=>'gzip --best', 'SUFFIX' => 'gz', },
    XS => {},

);
