use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::LoggedAuthDBI',
    'VERSION_FROM' => 'LoggedAuthDBI.pm', # finds $VERSION
	'PREREQ_PM' => {
		'DBI'        => 1.00, 
		'Apache::AuthDBI' => 0.93,
		'Digest::MD5' => 2.20,
		'Digest::SHA1' => 2.01
	}
);
