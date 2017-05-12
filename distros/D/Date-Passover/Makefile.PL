use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Date::Passover',
    VERSION_FROM => 'lib/Date/Passover.pm', # finds $VERSION
    AUTHOR       => 'Rich Bowen (rbowen@rcbowen.com)',
    ABSTRACT     => 'When is Passover',
    PREREQ_PM    => {
        Date::ICal => 0,
        Test::More => 0,
        Date::DayOfWeek => 0,
        },
);
