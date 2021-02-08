use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'Convert SQL to 2 linked HTML popup menus',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-HTML-LinkedMenus-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'DBIx-HTML-LinkedMenus',
	LICENSE		=> 'perl',
	NAME		=> 'DBIx::HTML::LinkedMenus',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'strict'	=> 0,
		'warnings'	=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001014,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM	=> 'lib/DBIx/HTML/LinkedMenus.pm',
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
				web => 'https://github.com/ronsavage/DBIx-HTML-LinkedMenus/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/DBIx-HTML-LinkedMenus.git',
				web		=> 'https://github.com/ronsavage/DBIx-HTML-LinkedMenus',
			},
		},
	};
}

WriteMakefile(%params);
