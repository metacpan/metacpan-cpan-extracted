# use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::AxKit::Language::LibXSLTEnhanced',
    VERSION_FROM      => 'lib/Apache/AxKit/Language/LibXSLTEnhanced.pm', # finds $VERSION
    PREREQ_PM         => {
			    AxKit         => "1.6.1",
			    LibXSLT	  => "1.53" 
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache/AxKit/Language/LibXSLTEnhanced.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Schindl <tom@localdomain>') : ()),
);
