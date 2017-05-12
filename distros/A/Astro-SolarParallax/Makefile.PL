use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Astro::SolarParallax',
    VERSION_FROM      => 'lib/Astro/SolarParallax.pm', # finds $VERSION
    PREREQ_PM         => {
      Time::Piece => 0,
      Math::Trig  => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Astro/SolarParallax.pm', # retrieve abstract from module
       AUTHOR         => 'Kjetil Kjernsmo <kjetilk@cpan.org>') : ()),
);
