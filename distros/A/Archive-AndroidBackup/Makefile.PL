use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my(%params) =
(
	NAME      => 'Archive::AndroidBackup',
	VERSION_FROM => 'lib/Archive/AndroidBackup.pm',
	DISTNAME  => 'Archive-AndroidBackup',
	EXE_FILES  => ['bin/abk'],
	PREREQ_PM =>
	{
		'Test::Version'   => 0,
		'Moose'        => '0',
		'MooseX::NonMoose'        => '0',
    'Moose::Util::TypeConstraints' => '0',
	},
	dist => { COMPRESS => 'gzip', SUFFIX   => 'gz' },
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MANIFEST.bak Archive-AndroidBackup-*'
	},
	($] ge '5.005') ?
	(
		AUTHOR   => 'Nathaniel Lally <nll@cpan.org>',
		ABSTRACT => 'Subclass of Archive::Tar that deals with Android Backup files (adb backup / adb restore)',
    LICENSE => 'GPL-3',
	) : (),
);

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		resources =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Archive-AndroidBackup',
			license    => 'http://www.gnu.org/copyleft/gpl.html'
		},
	};
}

WriteMakefile(%params);
