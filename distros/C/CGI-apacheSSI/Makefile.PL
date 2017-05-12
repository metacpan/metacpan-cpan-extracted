#use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::apacheSSI',
    VERSION_FROM      => 'lib/CGI/apacheSSI.pm', # finds $VERSION
    # PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    PREREQ_PM   => {
	'File::Spec::Functions'	=> '0',
	'HTTP::Response'	=> '0',
	'HTTP::Cookies'	=> '0',
	'Date::Format'	=> '0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/apacheSSI.pm', # retrieve abstract from module
       AUTHOR         => 'insaner <apacheSSI-PLEASE-NOSPAM@insaner.com>') : ()),
);
