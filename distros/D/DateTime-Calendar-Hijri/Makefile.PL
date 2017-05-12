use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'DateTime::Calendar::Hijri',
    VERSION_FROM => 'lib/DateTime/Calendar/Hijri.pm',
    AUTHOR       => 'Eugene van der Pijll (pijll@gmx.net)',
    ABSTRACT     => 'DateTime objects in the Hijri (Islamic) calendar',
    PREREQ_PM    => {
                     'Test::More' => 0,
                     'Date::Hijri' => 0.02,
                    },
);
