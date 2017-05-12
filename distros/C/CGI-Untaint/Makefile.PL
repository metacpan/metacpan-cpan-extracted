use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'CGI::Untaint',
	'AUTHOR'        => 'Tony Bowden <tmtm@cpan.org>',
	'ABSTRACT_FROM' => 'lib/CGI/Untaint.pm',
	'VERSION_FROM'  => 'lib/CGI/Untaint.pm',
	'PREREQ_PM'     => {
		'Test::More'         => 0.11,
		'UNIVERSAL::require' => 0.01,
	},
);
