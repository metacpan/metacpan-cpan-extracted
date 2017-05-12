use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Validate::MySQL',
    VERSION_FROM      => 'lib/Data/Validate/MySQL.pm', # finds $VERSION
    PREREQ_PM         => {
    						Carp			=> '',
    						Data::Validate	=> 0.06,
    						Math::BigFloat	=> '',
    
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Validate/MySQL.pm', # retrieve abstract from module
       AUTHOR         => 'Richard Sonnen <sonnen@frii.com>') : ()),
);
