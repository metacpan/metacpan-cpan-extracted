use ExtUtils::MakeMaker;
WriteMakefile(
	AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
	NAME          => 'Class::DBI::Untaint',
	ABSTRACT_FROM => 'lib/Class/DBI/Untaint.pm',
	VERSION_FROM  => 'lib/Class/DBI/Untaint.pm',
	PREREQ_PM     => {
		Class::DBI   => 0.95,
		CGI::Untaint => 1.00,
		Test::More   => 0.11,
	},
);
