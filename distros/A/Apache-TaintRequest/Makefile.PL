use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Apache::TaintRequest',
    'VERSION_FROM'	=> 'TaintRequest.pm',
    'PREREQ_PM'		=> {Taint=> 0.09},
);
