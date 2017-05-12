use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::Archive',
    'VERSION_FROM' => 'Archive.pm', # finds $VERSION
	'PREREQ_PM'	=>
	{
		'Archive::Tar'	=> 0.2,
		'Apache'	=> 1.2,
		'Compress::Zlib'=> 0,
	}
);
