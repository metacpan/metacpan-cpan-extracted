use ExtUtils::MakeMaker;
WriteMakefile(   
   VERSION => '0.01',
   NAME => 'CGI::Application::Tutorial::Namegame',
   PREREQ_PM => {
      'CGI::Application' => 0,
      'Lingua::EN::Namegame' => 0,
      'CGI::Application::Plugin::AutoRunmode' => 0,
      'CGI::Application::Plugin::Feedback' => 0,
      'CGI::Application::Plugin::Forward' => 0,
      'CGI::Application::Plugin::Session' => 0,
      'Carp' => 0,
   },
);
