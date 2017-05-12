use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'      => 'Class::DBI::Search::LIMITed',
	'AUTHOR' => 'Tony Bowden <tmtm@cpan.org>',
	'ABSTRACT_FROM' => 'lib/Class/DBI/Search/LIMITed.pm',
	'VERSION_FROM' => 'lib/Class/DBI/Search/LIMITed.pm',
	'PREREQ_PM' => {
		'Class::DBI' => '3.0.4',
	},
);
