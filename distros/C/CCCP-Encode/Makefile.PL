use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CCCP::Encode',
    VERSION_FROM      => 'lib/CCCP/Encode.pm', # finds $VERSION
    PREREQ_PM         => {
    	                   Encode => 0, # 2.23,
    	                   Text::Unidecode => 0, # 0.04
    	                   Carp => 0, # 1.08
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/CCCP/Encode.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Sivirinov') : ()),
);
