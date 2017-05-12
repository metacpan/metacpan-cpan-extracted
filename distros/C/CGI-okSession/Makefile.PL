#use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::okSession',
    'VERSION_FROM'	=> 'okSession.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Storable	=> 1.013,
		Time::HiRes	=> 1.2,
		Digest::MD5	=> 2.27,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'okSession.pm', # retrieve abstract from module
       AUTHOR     => 'O. A. Kobyakovskiy <ok@dinos.net>') : ()),
);
