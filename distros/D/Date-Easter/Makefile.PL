use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Date::Easter',
    'VERSION_FROM' => 'lib/Date/Easter.pm', # finds $VERSION
    'PREREQ_PM' => {
        Test::More => 0,
    },
    AUTHOR => 'Rich Bowen (rbowen@rcbowen.com)',
    ABSTRACT => 'Calculate the date of Easter',

    EXE_FILES => [ 'bin/easter' ],
);
