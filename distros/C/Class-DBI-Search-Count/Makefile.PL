use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'      => 'Class::DBI::Search::Count',
	'AUTHOR' => 'Tony Bowden <tmtm@cpan.org>',
	'ABSTRACT_FROM' => 'lib/Class/DBI/Search/Count.pm',
	'VERSION_FROM' => 'lib/Class/DBI/Search/Count.pm',
	'PREREQ_PM' => {
		'Class::DBI' => '3.0.4',
	},
);
