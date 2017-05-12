use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'CGI::Application::Plugin::AbstractCallback',
	VERSION_FROM => 'lib/CGI/Application/Plugin/AbstractCallback.pm', # finds $VERSION
	PREREQ_PM => { 
		'CGI::Application' => undef 
	}, # e.g., Module::Name => 1.1
	(
		$] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(
			ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/AbstractCallback.pm', # retrieve abstract from module
			AUTHOR => 'Toru Yamaguchi <zigorou@cpan.org>'
		) : ()
	),
);
