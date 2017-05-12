use ExtUtils::MakeMaker;

WriteMakefile (
   NAME => 'CGI::Application::Plugin::HelpMan',
   VERSION_FROM => 'lib/CGI/Application/Plugin/HelpMan.pm',
   PREREQ_PM => {
      'CGI::Application' => 0,
      'File::Which' => 0,
      'Pod::Simple::Search' => 0,
      'Pod::Html' => 0,
      'LEOCHARRE::DEBUG' => '1.02',
      'CGI::Application::Plugin::Session'          => 0,
      'CGI::Application::Plugin::Feedback'         => 0,
      'CGI::Application::Plugin::Forward'          => 0,
      'CGI::Application::Plugin::AutoRunmode'      => 0,
      'CGI::Application::Plugin::TmplInnerOuter'   => 0,      
      'File::Slurp' => 0,
      'Cwd' => 0,   
      'Test::Simple' => 0,
   },
);
