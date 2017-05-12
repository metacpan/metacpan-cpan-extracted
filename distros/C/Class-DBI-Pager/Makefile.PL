use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Class::DBI::Pager',
    'VERSION_FROM' => 'lib/Class/DBI/Pager.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Class::DBI' => 0.90,
	'Data::Page' => 0.13,
	'Exporter::Lite' => 0.01,
    },
);
