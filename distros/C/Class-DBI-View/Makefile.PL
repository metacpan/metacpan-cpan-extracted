use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Class::DBI::View',
    'VERSION_FROM' => 'lib/Class/DBI/View.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	UNIVERSAL::require => 0,
	Class::DBI => 0.94,
    },
);
