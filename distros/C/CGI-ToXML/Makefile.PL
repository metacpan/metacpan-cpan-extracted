use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::ToXML',
    'VERSION_FROM'	=> 'ToXML.pm', # finds $VERSION
    'PREREQ_PM'		=> { XML::Simple => 0, CGI => 2.0 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ToXML.pm', # retrieve abstract from module
       AUTHOR     => 'Michael K. Neylon <mneylon-pm@masemware.com>') : ()),
);
