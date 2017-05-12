use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Precompress',
    'VERSION_FROM'	=> 'Precompress.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Compress::Zlib'	=>	1.0,
		'Apache::Log'		=>	0,
		'Apache::Constants'	=>	0,
		'Test::MockObject'	=>	0,
		'File::Temp'		=>	0,
		'File::Spec'		=>	0,
		'Cwd'				=>	0
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Apache::Preompress - Deliver already compressed files or decompress on the fly',
       AUTHOR     => 'Simon Proctor <cpan@simonproctor.com>') : ()),
);
