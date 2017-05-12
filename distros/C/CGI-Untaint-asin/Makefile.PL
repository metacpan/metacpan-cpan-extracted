use ExtUtils::MakeMaker;
WriteMakefile(
	AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
	NAME          => 'CGI::Untaint::asin',
	ABSTRACT_FROM => 'lib/CGI/Untaint/asin.pm',
	VERSION_FROM  => 'lib/CGI/Untaint/asin.pm',
	PREREQ_PM     => {
		CGI::Untaint => 0.07,
		Test::More   => 0.11,
		Test::CGI::Untaint => 1.10,
	},
);
