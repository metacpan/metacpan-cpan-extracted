use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'CGI::Application::Plugin::Thumbnail',
   VERSION_FROM => 'lib/CGI/Application/Plugin/Thumbnail.pm',
   

   # gen /usr/bin/pmused by Tue Apr 28 12:23:20 EDT 2009 
   PREREQ_PM => {
      'CGI::Application'                  => '4.06',
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'File::Path'                        => '2.07',
      'File::PathInfo'                    => '1.25',
      'Image::Thumbnail'                  => '0.63',
      'LEOCHARRE::DEBUG'                  => '1.13',
      'Test::Simple'                      => '0',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [],
);


