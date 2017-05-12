use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => "CGI::Application::Plugin::Feedback",
   VERSION_FROM => 'lib/CGI/Application/Plugin/Feedback.pm',
   PREREQ_PM => {
		'CGI::Session' => 0,
      'CGI::Application::Plugin::Session' => 0,
      'CGI::Application' => 0,
   },
);

