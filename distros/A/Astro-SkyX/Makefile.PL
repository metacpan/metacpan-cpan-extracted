use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Astro-SkyX',
    VERSION_FROM      => 'lib/Astro/SkyX.pm', # finds $VERSION
    PREREQ_PM         => {
                          'IO::Socket' => 1.31, 'Scalar::Util' => 1.22,

                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Astro/SkyX.pm', # retrieve abstract from module
       AUTHOR         => 'Robert Woodard <kayak.man@gmail.com>') : ()),
);
