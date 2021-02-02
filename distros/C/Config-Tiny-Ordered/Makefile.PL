use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'Read/Write ordered .ini style files with as little code as possible',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Config-Tiny-Ordered-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX	=> 'gz'
	},
	DISTNAME	=> 'Config-Tiny-Ordered',
	LICENSE		=> 'perl',
	NAME		=> 'Config::Tiny::Ordered',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Config::Tiny'	=> 2.12,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.001002,
	},
	VERSION_FROM => 'lib/Config/Tiny/Ordered.pm',
	INSTALLDIRS		=> 'site',
	EXE_FILES		=> [],
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources   =>
		{
			bugtracker =>
			{
				web => 'https://github.com/ronsavage/Config-Tiny-Ordered/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Config-Tiny-Ordered.git',
				web		=> 'https://github.com/ronsavage/Config-Tiny-Ordered',
			},
		},
	};
}

WriteMakefile(%params);
