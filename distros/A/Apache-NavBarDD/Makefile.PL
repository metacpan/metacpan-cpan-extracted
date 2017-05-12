use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Apache::NavBarDD',
    'DISTNAME'          => 'Apache-NavBarDD',
    'VERSION_FROM'	=> 'NavBarDD.pm',
    'PREREQ_PM'		=> {Apache::Constants => '1.09',
                            Apache::File => '1.01',
                            Apache::URI => '1.00'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'NavBarDD.pm', # retrieve abstract from module
       AUTHOR     => 'Panos Louridas <louridas@acm.org>') : ()),
);
