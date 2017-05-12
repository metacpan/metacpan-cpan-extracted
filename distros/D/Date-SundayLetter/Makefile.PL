use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Date::SundayLetter',
    VERSION_FROM => 'lib/Date/SundayLetter.pm', # finds $VERSION
    AUTHOR       => 'Rich Bowen (rbowen@rcbowen.com)',
    ABSTRACT     => 'Calculates the Sunday Letters for a given year',
    PREREQ_PM    => { Date::Leapyear => 0,
                      Test::More     => 0,
                    },
);
