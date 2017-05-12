use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Class::DBI::Oracle',
    'VERSION_FROM'	=> 'lib/Class/DBI/Oracle.pm', 
    'PREREQ_PM'		=> { 
                             'Class::DBI' => 0.36, 
                             'Test::More' => 0.05, 
                           },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'lib/Class/DBI/Oracle.pm', 
       AUTHOR     => 'Ted Zlatanov <tzz@lifelogs.com>') : ()),
);
