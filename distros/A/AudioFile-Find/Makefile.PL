use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'AudioFile::Find',
  AUTHOR              => 'Markus <holli.holzer@googlemail.com>',
  VERSION_FROM        => 'lib/AudioFile/Find.pm',
  ABSTRACT_FROM       => 'lib/AudioFile/Find.pm',
  EXE_FILES           => ['bin/findaudio'],
  PL_FILES            => {},
  PREREQ_PM => {
    'Test::More'       => 0,
		'AudioFile::Info'  => 1.09,
    'YAML'             => 0,
    'File::Find::Rule' => 0,
    'List::MoreUtils'  => 0,
  },	
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'AudioFile-Find-*' },
);
