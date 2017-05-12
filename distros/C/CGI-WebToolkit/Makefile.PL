use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::WebToolkit',
    VERSION_FROM      => 'lib/CGI/WebToolkit.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
		'CGI'         => 0,
		'CGI::Carp'   => 0,
		'Data::Dump'  => 0,
		'DBI'         => 0,
		'Digest::MD5' => 0,   
    },
    PMLIBDIRS 		  => [ 'lib', $BASEEXT, 'lib/CGI/WebToolkit' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/WebToolkit.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Kirchner <tk@apple.com>') : ()),
);
