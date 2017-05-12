
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	INSTALLDIRS  => 'site',
	NAME         => 'CGI::Application::Structured',
	VERSION_FROM => 'lib/CGI/Application/Structured.pm',
	AUTHOR       => 'Gordon Van Amburg (vanamburg@cpan.org)',
	ABSTRACT     => 'A web application framework.',
	PREREQ_PM    => {
		'CGI::Application'                       => 4,
		'Test::Simple'                           => 0.44,
		'CGI::Application::Server'               => 0,
		'CGI::Application::Dispatch'             => 0,
		'CGI::Application::Plugin::DBH'          => 0,
		'CGI::Application::Plugin::TT'           => 0,
		'CGI::Application::Plugin::Session'      => 0,
		'CGI::Application::Plugin::ConfigAuto'   => 0,
		'CGI::Application::Plugin::Forward'      => 0,
		'CGI::Application::Plugin::Redirect'     => 0,
		'CGI::Application::Plugin::FillInForm'   => 0,
		'CGI::Application::Plugin::ValidateRM'   => 0,
		'CGI::Application::Plugin::LogDispatch'  => 0,
		'CGI::Application::Plugin::DBIC::Schema' => 0,
		'CGI::Application::Plugin::SuperForm'    => 0,
	        'CGI::Application::Plugin::AutoRunmode'  => 0,
		'CGI::Application::Plugin::DebugScreen'  => 0,
                
	},
        LICENSE => 'perl',
);
