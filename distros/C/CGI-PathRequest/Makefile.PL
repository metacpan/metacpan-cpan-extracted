use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'CGI::PathRequest',
   VERSION_FROM => 'lib/CGI/PathRequest.pm',
   

   # gen /usr/bin/pmused by Tue Apr 28 11:44:49 EDT 2009 
   PREREQ_PM => {
      'CGI'                               => '3',
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'File::MMagic'                      => '1.27',
      'File::PathInfo::Ext'               => '1.27',
      'HTML::Entities'                    => '1.35',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [],
);


