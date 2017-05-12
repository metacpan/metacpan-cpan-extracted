use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Class::DBI::Plugin::Iterator',
	VERSION_FROM	=> 'lib/Class/DBI/Plugin/Iterator.pm',
	PREREQ_PM	=> {
		Class::DBI => undef,
	},
);
