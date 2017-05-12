use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Chart::Scientific',
    VERSION_FROM      => 'lib/Chart/Scientific.pm', # finds $VERSION
    PREREQ_PM         => {
                            PDL                   => 0,
                            PDL::NiceSlice        => 0,
                            PDL::Graphics::PGPLOT => 0,
                            PGPLOT                => 0,
                            Tie::IxHash           => 0,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Chart/Scientific.pm', # retrieve abstract from module
       AUTHOR         => 'Kester Allen <kester@gmail.com>') : ()),
);
