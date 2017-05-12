use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Config::Crontab',
    'VERSION_FROM'	=> 'Crontab.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.006_001 ?
      (ABSTRACT_FROM => 'Crontab.pm', # retrieve abstract from module
       AUTHOR     => 'Scott Wiersdorf <scott@perlcode.org>') : ()),
);
