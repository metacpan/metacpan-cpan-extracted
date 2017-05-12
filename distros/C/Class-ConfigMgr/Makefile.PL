use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::ConfigMgr',
    'VERSION_FROM'	=> 'lib/Class/ConfigMgr.pm',
    'PREREQ_PM'		=> { Class::ErrorHandler=>0 }, 
);
