use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Luis E. Munoz <luismunoz@cpan.org>',
		ABSTRACT	=> 'Provide interoperable MD5-based crypt() functions',
	   ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Crypt-PasswdMD5-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'Crypt-PasswdMD5',
	LICENSE		=> 'perl',
	NAME		=> 'Crypt::PasswdMD5',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Digest::MD5'	=> 2.53,
		'strict'		=> 0,
		'warnings'		=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.001002,
	},
	VERSION_FROM	=> 'lib/Crypt/PasswdMD5.pm',
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
				web => 'https://github.com/ronsavage/Crypt-PasswdMD5/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Crypt-PasswdMD5.git',
				web		=> 'https://github.com/ronsavage/Crypt-PasswdMD5',
			},
		},
	};
}

WriteMakefile(%params);
