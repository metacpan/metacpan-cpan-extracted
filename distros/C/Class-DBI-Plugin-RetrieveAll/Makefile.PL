use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'      => 'Class::DBI::Plugin::RetrieveAll',
	'VERSION_FROM' => 'lib/Class/DBI/Plugin/RetrieveAll.pm',
	'PREREQ_PM' => {
		'Class::DBI' => '0.95',
	},
);
