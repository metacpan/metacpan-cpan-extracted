use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'DateTime::Format::Roman',
    VERSION_FROM => 'lib/DateTime/Format/Roman.pm',
    PREREQ_PM    => { DateTime => 0.12,
                      Roman    => 0,
                      Test::More => 0,
                       },
    AUTHOR       => 'Eugene van der Pijll (pijll@gmx.net)',
    ABSTRACT     => 'Roman day names (kalends, ides, nones) for DateTime objects',
);
