use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bundle::HollyKing',
    VERSION_FROM      => 'HollyKing.pm',
    PREREQ_PM         => {}, 
    dist              => {
        SUFFIX       => ".gz",
        DIST_DEFAULT => 'all tardist',
        COMPRESS     => "gzip -9f",
        ZIP_FLAGS    => '-pr9'
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'HollyKing.pm', # retrieve abstract from module
       AUTHOR         => 'Brendan "HollyKing" Leber <brendan@hollyking.org>') : ()),


);
