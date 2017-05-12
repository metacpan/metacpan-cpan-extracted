use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::DBI::Plugin::MultiDatabases',
    'VERSION_FROM'	=> 'lib/Class/DBI/Plugin/MultiDatabases.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	Test::More => 0,
    	Class::DBI => 0.94,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Class/DBI/Plugin/MultiDatabases.pm', # retrieve abstract from module
       AUTHOR     => 'Makamaka <makamaka[at]cpan.org>') : ()),
);
