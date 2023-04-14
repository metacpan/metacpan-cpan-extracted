use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	("$]" >= '5.005') ?
	(
		AUTHOR		=> 'Adam Kennedy <adamk@cpan.org>',
		ABSTRACT	=> 'Read/Write .ini style files with as little code as possible',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Config-Tiny-*',
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz',
	},
	BUILD_REQUIRES =>
	{
		# Skip on Windows to avoid breaking ActivePerl PPMs
		# 0.47 means 5.6.2 or newer, which everyone on Win32 has.
		($^O eq 'MSWin32' ? () : ('Test::More' => '0.47') ),
	},
	DISTNAME			=> 'Config-Tiny',
	EXE_FILES			=> [],
	MIN_PERL_VERSION	=> '5.008001',
	NAME				=> 'Config::Tiny',
	PL_FILES			=> {},
	PREREQ_PM			=>
	{
		'File::Spec'	=> '3.30',
		'File::Temp'	=> '0.22',
		'strict'		=> '0',
		'utf8'			=> '0',
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> '1.001002',
	},
	VERSION_FROM => 'lib/Config/Tiny.pm',
);

if (eval{ExtUtils::MakeMaker->VERSION('6.30')})
{
	$params{LICENSE} = 'perl';
}

if (eval{ExtUtils::MakeMaker->VERSION('6.46')})
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
				web => 'https://github.com/ronsavage/Config-Tiny/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Config-Tiny.git',
				web		=> 'https://github.com/ronsavage/Config-Tiny',
			},
		},
	};
}

WriteMakefile(%params);
