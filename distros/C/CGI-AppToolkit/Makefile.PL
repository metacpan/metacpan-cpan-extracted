use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'CGI::AppToolkit',
	'VERSION_FROM'  => 'lib/CGI/AppToolkit.pm', # finds $VERSION
	'LIBS'          => [qw'-lstdc++'],   # e.g., '-lm'
	'CC'            => 'c++',
	'DIR'           => ['Template', 'Template/Template'],
	'PREREQ_PM' => { 
			'DBI'            => '0',
			'CGI'            => '0',
		},
);
