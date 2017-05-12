use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI-Builder-Auth',
    'VERSION_FROM'	=> 'lib/CGI/Builder/Auth.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Carp'          =>  0,
		'CGI::Builder'  =>  1.11,
		'Class::constr' =>  1.75,
		'Class::props'  =>  1.7,
		'Scalar::Util'  =>  0,
		'Digest::MD5 '  =>  0,
		'File::Basename'=>  0,
		'Test::More'    =>  0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/CGI/Builder/Auth.pm', # retrieve abstract from module
       AUTHOR     => 'Vincent Veselosky [[http://control-escape.com]]') : ()),
);
