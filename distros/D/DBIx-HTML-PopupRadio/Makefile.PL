use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'Convert db data to HTML popup menu or radio group',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-HTML-PopupRadio-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'DBIx-HTML-PopupRadio',
	NAME		=> 'DBIx::HTML::PopupRadio',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'HTML::Entities::Interpolate'	=> 1.00,
		'strict'						=> 0,
		'warnings'						=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001014,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM	=> 'lib/DBIx/HTML/PopupRadio.pm',
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
				web => 'https://github.com/ronsavage/DBIx-HTML-PopupRadio/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/DBIx-HTML-PopupRadio.git',
				web		=> 'https://github.com/ronsavage/DBIx-HTML-PopupRadio',
			},
		},
	};
}

WriteMakefile(%params);
