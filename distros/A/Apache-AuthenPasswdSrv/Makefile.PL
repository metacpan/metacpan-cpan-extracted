use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::AuthenPasswdSrv',
    'VERSION_FROM' => 'AuthenPasswdSrv.pm', # finds $VERSION
    dist => {
	SUFFIX => 'gz',
	COMPRESS => 'gzip -9',
    }
);
