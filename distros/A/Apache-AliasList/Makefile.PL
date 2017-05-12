use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::AliasList',
    'VERSION_FROM'	=> 'AliasList.pm', # finds $VERSION
    'PREREQ_PM'		=> {Apache::Constants => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'AliasList.pm',
       AUTHOR     => 'Jon Allen <jj@jonallen.info>') : ()),
);
