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

WriteMakefile
(
	($] ge '5.005') ?
	(
	 AUTHOR   => 'Luis E. Muñoz <luismunoz@cpan.org>',
	 ABSTRACT => 'Provide interoperable MD5-based crypt() functions',
	   ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Crypt-PasswdMD5-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Crypt-PasswdMD5',
	NAME      => 'Crypt::PasswdMD5',
	LICENSE   => 'perl',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Digest::MD5' => 2.53,
		'strict'      => 0,
		'Test::More'  => 0.94,
#		'Test::Pod'   => 1.45, # Make it optional. See t/pod.t
		'warnings'    => 0,
	},
	VERSION_FROM => 'lib/Crypt/PasswdMD5.pm',
);
