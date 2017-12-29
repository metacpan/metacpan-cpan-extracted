use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Generate a set of CGI::Application-based classes',
		) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CGI-Application-Bouquet-Rose-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Application-Bouquet-Rose',
	NAME      => 'CGI::Application::Bouquet::Rose',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Carp'				=> 0,
		'Config::IniFiles'	=> 0,
		'File::Copy'		=> 0,
		'File::Path'		=> 0,
		'File::Spec'		=> 0,
		'Getopt::Long'		=> 0,
		'HTML::Template'	=> 0,
		'Moo'				=> 0,
		'Pod::Usage'		=> 0,
		'strict'			=> 0,
		'Types::Standard'	=> 0,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.001002,
		'Test::Pod' => 1.48,
	},
	VERSION_FROM => 'lib/CGI/Application/Bouquet/Rose.pm',
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
		resources =>
		{
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Garden-Design',
			},
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/CGI-Application-Bouquet-Rose.git',
				web  => 'https://github.com/ronsavage/CGI-Application-Bouquet-Rose',
			},
		},
	};
}

if ($ExtUtils::MakeMaker::VERSION ge '6.48')
{
	$params{MIN_PERL_VERSION} = 5.005_62;
}

WriteMakefile(%params);
