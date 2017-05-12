use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Date::Chinese',
    VERSION_FROM => 'lib/Date/Chinese.pm', # finds $VERSION
    AUTHOR       => 'Rich Bowen (rbowen@rcbowen.com)',
    ABSTRACT     => 'Calculate dates in the Chinese calendar',
    PREREQ_PM    => {
        Test::More => 0,
        },

);
