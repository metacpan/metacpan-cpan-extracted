use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Class::DBI::Sybase',
    'VERSION_FROM'	=> 'Sybase.pm', 
    'PREREQ_PM'		=> { 
                             'Class::DBI' => 3.0.11, 
                             'Test::More' => 0.05, 
                           },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Sybase.pm', 
       AUTHOR     => 'Michael Wojcikiewicz <theothermike@gmail.com>') : ()),
);
