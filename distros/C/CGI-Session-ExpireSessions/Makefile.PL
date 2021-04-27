use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# ----------------------

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'Expires CGI::Session db-based and file-based sessions',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CGI-Session-ExpireSessions-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'CGI-Session-ExpireSessions',
	LICENSE		=> 'perl',
	NAME		=> 'CGI::Session::ExpireSessions',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Carp'			=> 0,
		'CGI::Session'	=> 4.14,
		'File::Spec'	=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.001002,
	},
	VERSION_FROM	=> 'lib/CGI/Session/ExpireSessions.pm',
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
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Session-ExpireSessions',
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/CGI-Session-ExpireSessions.git',
				web  => 'https://github.com/ronsavage/CGI-Session-ExpireSessions',
			},
		},
	};
}

WriteMakefile(%params);
