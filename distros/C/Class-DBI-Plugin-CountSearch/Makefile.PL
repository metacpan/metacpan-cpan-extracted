use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'      => 'Class::DBI::Plugin::CountSearch',
	'VERSION_FROM' => 'lib/Class/DBI/Plugin/CountSearch.pm',
	'PREREQ_PM' => {
		'Class::DBI' => '0.95',
	},
);