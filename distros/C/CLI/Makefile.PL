use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'CLI',
    VERSION        => '0.24',
    DISTNAME       => 'CLI',
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    BUILD_REQUIRES => { 'Astro::Time' => 0 }
);
