use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AudioFile::Info::Audio::WMA',
    AUTHOR              => 'Markus <holli.holzer@googlemail.com>',
    VERSION_FROM        => 'lib/AudioFile/Info/Audio/WMA.pm',
    ABSTRACT_FROM       => 'lib/AudioFile/Info/Audio/WMA.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Audio::WMA' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AudioFile-Info-Audio-WMA-*' },
);
