# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information

use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'App::MaMGal',
	VERSION_FROM  => 'lib/App/MaMGal.pm',
	EXE_FILES     => ['mamgal'],
	PREREQ_PM     => {
# Required for runtime
		'Carp' => 0,
		'Cwd' => 0,
		'Exception::Class' => 0,
		'Fcntl' => 0,
		'File::Basename' => 0,
		'File::stat' => 0,
		'File::Temp' => 0,
		'FileHandle' => 0,
		'HTML::Entities' => 0,
		'Image::EXIF::DateTime::Parser' => 0,
		'Image::Magick' => 0,
		'Locale::gettext' => 0,
		'POSIX' => 0,
		'Scalar::Util' => 0,
		'URI::file' => 0,
# Only one of these is necessary at runtime, but both are required for tests.
		'Image::ExifTool' => 0,
		'Image::Info' => 0,
# Required for tests only
		'Test::Class' => 0,
		'Test::Exception' => 0,
		'Test::Files' => 0,
		'Test::HTML::Content' => 0,
		'Test::MockObject' => 0,
		'Test::More' => 0,
		'Test::Warn' => 0,
	},
);
