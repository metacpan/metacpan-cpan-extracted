use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Date::Japanese::Holiday',
    'VERSION_FROM' => 'lib/Date/Japanese/Holiday.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Time::JulianDay => 0.01,
	Date::Calc => 5.3,
	Date::Simple => 1.03,
    },
);
