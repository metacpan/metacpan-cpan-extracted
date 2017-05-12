use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'CGI::Application::Plugin::TmplInnerOuter',
   VERSION_FROM => 'lib/CGI/Application/Plugin/TmplInnerOuter.pm',


   # gen /usr/bin/pmused by Tue Sep  9 11:39:17 EDT 2008 
   PREREQ_PM => {
      'CGI::Application'                  => '4',
      'Carp'                              => '1',
      'Data::Dumper'                      => '0',
      'Exporter'                          => '5',
      'HTML::Template::Default'           => '1.07',
      'Test::Simple'                      => '0',
   },


   EXE_FILES => [],
);


