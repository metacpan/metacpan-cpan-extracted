use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Alister::Base::Sums',
   VERSION_FROM => 'lib/Alister/Base/Sums.pm',
   ABSTRACT_FROM => 'lib/Alister/Base/Sums.pod',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   
   

   # gen /usr/bin/pmused by Mon Jul 27 19:24:48 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'LEOCHARRE::Debug'                  => '1.02',
      'Test::Simple'                      => '0',
      'YAML::DBH'                         => '1.06',
   },

   
   LICENSE => 'perl',
   
   
   
);


