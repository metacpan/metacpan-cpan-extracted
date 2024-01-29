use 5.008003;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME               => 'Cache::MemcachedBinary',
    VERSION_FROM       => 'lib/Cache/MemcachedBinary.pm',
    PREREQ_PM          => {
                             strict     => 0,
                             warnings   => 0,
                             IO::Socket => 0,
                             Encode     => 0
    },
    CONFIGURE_REQUIRES => {
                             "ExtUtils::MakeMaker" => 0
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM   => 'lib/Cache/MemcachedBinary.pm',
       AUTHOR          => 'Konstantin Titov <xmolex@cpan.org>') : ()),
);
