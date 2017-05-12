use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Astro::SunTime',
  VERSION_FROM => 'SunTime.pm',
  PREREQ_PM =>
    {
      POSIX => 0,
    },
  BUILD_REQUIRES =>
    {
      Test => 0,
      Time::ParseDate => 0,
    },
  LICENSE => 'gpl_3',
);

