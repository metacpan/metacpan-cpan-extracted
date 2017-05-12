use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'CGI::Application::Plugin::Menu',
   VERSION_FROM => 'lib/CGI/Application/Plugin/Menu.pm',
   

   # gen /usr/bin/pmused by Tue May 12 16:52:40 EDT 2009 
   PREREQ_PM => {
      'CGI::Application'                  => '4.06',
      'Carp'                              => '1',
      'Exporter'                          => '5',
      'HTML::Template'                    => '2.9',
      'LEOCHARRE::DEBUG'                  => '1.13',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [],
);


