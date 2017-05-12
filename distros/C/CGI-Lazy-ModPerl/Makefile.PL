use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Lazy::ModPerl',
    VERSION_FROM      => 'lib/CGI/Lazy/ModPerl.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
    				'CGI::Lazy' => 0.01,  
    				'Apache2::Const' => 2.0,
				'Apache2::RequestUtil' => 2.0,
			},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'mod_perl utilities for CGI::Lazy', 
       AUTHOR         => 'Nik Ogura <nik.ogura@gmail.com>') : ()),
);
