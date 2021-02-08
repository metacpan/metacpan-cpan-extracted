use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'Read a database table into a hash',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Table2Hash-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'DBIx-Table2Hash',
	LICENSE		=> 'perl',
	NAME		=> 'DBIx::Table2Hash',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Carp'		=> 0,
		'strict'	=> 0,
		'warnings'	=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 0,
		'Test::Pod'		=> 0,
	},
	VERSION_FROM	=> 'lib/DBIx/Table2Hash.pm',
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
				web => 'https://github.com/ronsavage/DBIx-Table2Hash/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/DBIx-Table2Hash.git',
				web		=> 'https://github.com/ronsavage/DBIx-Table2Hash',
			},
		},
	};
}

WriteMakefile(%params);
