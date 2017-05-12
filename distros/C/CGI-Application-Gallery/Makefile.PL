use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'CGI::Application::Gallery',
	VERSION_FROM => 'lib/CGI/Application/Gallery.pm',
	PREREQ_PM => {
      'LEOCHARRE::DEBUG' => 0,
		'CGI::Application' => 0,
		'CGI::Application::Plugin::Session' => 0,
		'CGI::Application::Plugin::Session' => 0,
		'CGI::Application::Plugin::AutoRunmode' => 0,
		'CGI::Application::Plugin::Forward' => 0,
      'CGI::Application::Plugin::Stream' => 0,
      
		'CGI::Application::Plugin::Feedback' => 0,      
      'CGI::Application::Plugin::TmplInnerOuter' => 0,
      'CGI::Application::Plugin::Thumbnail' => 0,
		'Data::Page' => 0,
		'Carp' => 0,
		'File::PathInfo::Ext' => '1',	
	},

);
