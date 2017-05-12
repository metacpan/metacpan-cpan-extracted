use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'CGI::Session::Submitted',
	VERSION_FROM => 'lib/CGI/Session/Submitted.pm',
	PREREQ_PM	=> {
		'Carp' => undef,
		'CGI::Session' => undef,
	},
	ABSTRACT => ' Automatic session and persistence of query data.',
	AUTHOR => 'Leo Charre <leo@leocharre.com',
);
