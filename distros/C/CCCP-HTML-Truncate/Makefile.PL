use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CCCP::HTML::Truncate',
    VERSION_FROM      => 'lib/CCCP/HTML/Truncate.pm', # finds $VERSION
    PREREQ_PM         => {
    	'XML::LibXML' => 0,
    	'Encode' => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CCCP/HTML/Truncate.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Sivirinov') : ()),
);
