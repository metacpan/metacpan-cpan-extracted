use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Date::Japanese::Era',
    'VERSION_FROM' => 'lib/Date/Japanese/Era.pm', # finds $VERSION
    'PREREQ_PM' => {
	Date::Calc => 4.3,
	Test::More => 0,
        Encode => 2.1,
        Lingua::JA::Numbers => 0.04,
    },
);
