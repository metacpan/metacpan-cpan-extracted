use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Date::Range::Birth',
    'VERSION_FROM' => 'lib/Date/Range/Birth.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Date::Range => 0.01,
	Date::Calc => 0,
    },
);
