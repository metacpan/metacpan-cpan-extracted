use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'A plugin which uses Config::Tiny with 1 of N sections',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Config-Plugin-TinyManifold-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
 },
	DISTNAME	=> 'Config-Plugin-TinyManifold',
	LICENSE		=> 'perl',
	NAME		=> 'Config::Plugin::TinyManifold',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Carp'			=> 1.01,
		'Config::Tiny'	=> 2.14,
		'strict'		=> 1.03,
		'vars'			=> 1.01,
		'warnings'		=> 1.03,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.001002,
	},
	VERSION_FROM	=> 'lib/Config/Plugin/TinyManifold.pm',
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
				web => 'https://github.com/ronsavage/Config-Plugin-TinyManifold/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Config-Plugin-TinyManifold.git',
				web		=> 'https://github.com/ronsavage/Config-Plugin-TinyManifold',
			},
		},
	};
}

WriteMakefile(%params);
