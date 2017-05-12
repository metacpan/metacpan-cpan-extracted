use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Date::Horoscope',
    'VERSION_FROM' => 'Horoscope.pm', # finds $VERSION
	      'PREREQ_PM' => { 'Date::Manip' }
);
