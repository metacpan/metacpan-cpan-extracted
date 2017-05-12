use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Date::DayOfWeek',
    'VERSION_FROM'	=> 'lib/Date/DayOfWeek.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
        Date::Leapyear => 0,
        Test::More => '0.40',
        },
);

sub MY::postamble {
    package MY;
    "\npredist: all\n" .
    "\tcvs2cl -r -b -t -f Changes\n";
}

