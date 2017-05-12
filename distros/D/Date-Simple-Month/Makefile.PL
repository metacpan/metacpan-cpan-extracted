use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Date::Simple::Month',
    'VERSION_FROM' => 'lib/Date/Simple/Month.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    Date::Range => 0,
    Date::Simple => 0,
    },
);
