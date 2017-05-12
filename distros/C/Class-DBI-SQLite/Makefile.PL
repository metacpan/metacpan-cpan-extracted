use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Class::DBI::SQLite',
    'VERSION_FROM' => 'lib/Class/DBI/SQLite.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Class::DBI' => 0.85,
	'Ima::DBI'   => 0.27,
	'DBD::SQLite' => 0.07,
    },
);
