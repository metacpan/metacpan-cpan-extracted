use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Archive::Ar::Ng',
	'VERSION_FROM'	=> 'lib/Archive/Ar/Ng.pm', # finds $VERSION
	'PREREQ_PM'	=>
		{ 
			'Test::More' => '0',
			'Test::MockObject' => '0',
			'File::Spec' => '0',
			'File::Temp' => '0',
		},

	'dist'		=> 
		{
			COMPRESS => 'gzip -9',
			SUFFIX   => '.gz',
			DIST_DEFAULT => 'all tardist',
		},

	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(
			ABSTRACT_FROM	=> 'lib/Archive/Ar/Ng.pm', # retrieve abstract from module
			AUTHOR     	=> 'Jay Bonci <jay@bonci.com>') 
		: ()),

	META_MERGE	=>
		{
			'meta-spec' => { version => 2 },
			resources =>
				{
					repository =>
						{
							type => 'git',
							url  => 'https://github.com/Mithrandirkft/Archive-Ar-Ng.git',
							web  => 'https://github.com/Mithrandirkft/Archive-Ar-Ng',
						},
				},
		},
);

