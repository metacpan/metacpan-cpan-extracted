use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.3 2003/10/30 19:33:13 cmdrwalrus Exp $

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::Auth',
    'VERSION_FROM'	=> 'Auth.pm', # finds $VERSION
#	CGI is no longer a prerequisite, but one of CGI or CGI::Simple is needed.  How could I specify that?
#    'PREREQ_PM'		=> {CGI => 2.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT	  => 'Simple session-based password authentication for CGI applications',
       AUTHOR     => 'Chad Wallace <cmdrwalrus@canada.com>') : ()),
);
