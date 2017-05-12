use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Bvec',
    VERSION_FROM      => 'lib/Data/Bvec.pm', # finds $VERSION
    PREREQ_PM         => {
        'Math::Int2Base' =>  0.03,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Bvec.pm', # retrieve abstract from module
       AUTHOR         => 'Brad Baxter <bmb@galib.uga.edu>') : ()),
);
