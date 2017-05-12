use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::ActionDispatch',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/ActionDispatch.pm',
    PREREQ_PM         => { 
							'CGI::Application' => '4.0',
							'Class::Inspector' => '0',
							'Attribute::Handlers' => '0',
						},
	INSTALLDIRS		  => 'site',
	PL_FILES		  => {}
);
