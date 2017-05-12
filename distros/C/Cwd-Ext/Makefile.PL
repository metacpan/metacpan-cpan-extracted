use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Cwd::Ext',
   VERSION_FROM => 'lib/Cwd/Ext.pm',
   ABSTRACT_FROM => 'lib/Cwd/Ext.pod',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   
   

   # gen /usr/bin/pmused by Wed Aug 26 13:31:36 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'Test::Simple'                      => '0',
   },

   
   LICENSE => 'perl',
   
   
   
);


