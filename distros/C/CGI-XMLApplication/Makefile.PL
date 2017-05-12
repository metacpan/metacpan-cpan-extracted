use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::XMLApplication',
    'VERSION_FROM'	=> 'XMLApplication.pm', # finds $VERSION
    'PREREQ_PM'		=> {XML::LibXML => 1.10, XML::LibXSLT => 1.08 }, 
);
