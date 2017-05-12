use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Serializer::Sereal',
    AUTHOR              => q{James Rouzier <rouzier@gmail.com>},
    VERSION_FROM        => 'lib/Data/Serializer/Sereal.pm',
    ABSTRACT_FROM       => 'lib/Data/Serializer/Sereal.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Sereal::Decoder' => 0,
        'Sereal::Encoder' => 0,
        'Data::Serializer' => 0,
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/rouzier/Data-Serializer-Sereal.git',
                web  => 'https://github.com/rouzier/Data-Serializer-Sereal'
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Serializer-Sereal-*' },
);
