use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'CGI::Untaint::url',
	VERSION_FROM  => 'lib/CGI/Untaint/url.pm',
	ABSTRACT_FROM => 'lib/CGI/Untaint/url.pm',
	PREREQ_PM     => {
		'CGI::Untaint'                    => 0.07,
		'URI::Find::Schemeless::Stricter' => 0.01,
	},
	AUTHOR => 'Tony Bowden <kasei@tmtm.com>',
);
