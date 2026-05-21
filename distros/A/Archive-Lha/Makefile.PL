use strict;
use warnings;
use ExtUtils::MakeMaker;

my $version = MM->parse_version('lib/Archive/Lha.pm');

WriteMakefile(
    NAME          => 'Archive::Lha',
    VERSION_FROM  => 'lib/Archive/Lha.pm',
    ABSTRACT_FROM => 'lib/Archive/Lha.pm',
    AUTHOR        => [
        'Kenichi Ishigaki <ishigaki@cpan.org>',
        'Nicolas Mendoza <mendoza@pvv.ntnu.no>',
    ],
    LICENSE       => 'perl',
    XSMULTI       => 1,
    PREREQ_PM     => {
        'Exporter::Lite'  => 0,
        'POSIX'           => 0,
        'Encode'          => 0,
        'File::Basename'  => 0,
        'File::Path'      => 0,
        'Getopt::Long'    => 0,
        'Time::Moment'    => 0,
    },
    TEST_REQUIRES => {
        'Test::More'          => '0.47',
        'Test::UseAllModules' => '0.09',
        'Time::Moment'        => 0,
        'File::Slurp'         => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/nicomen/archive-lha.git',
                web  => 'https://github.com/nicomen/archive-lha',
            },
            bugtracker => {
                web => 'https://github.com/nicomen/archive-lha/issues',
            },
        },
        provides => {
            'Archive::Lha'                 => { file => 'lib/Archive/Lha.pm', version => $version },
            'Archive::Lha::CRC'            => { file => 'lib/Archive/Lha/CRC.pm' },
            'Archive::Lha::Constants'      => { file => 'lib/Archive/Lha/Constants.pm' },
            'Archive::Lha::Decode'         => { file => 'lib/Archive/Lha/Decode.pm' },
            'Archive::Lha::Decode::Base'   => { file => 'lib/Archive/Lha/Decode/Base.pm' },
            'Archive::Lha::Decode::LH0'    => { file => 'lib/Archive/Lha/Decode/LH0.pm' },
            'Archive::Lha::Decode::LH5'    => { file => 'lib/Archive/Lha/Decode/LH5.pm' },
            'Archive::Lha::Decode::LH6'    => { file => 'lib/Archive/Lha/Decode/LH6.pm' },
            'Archive::Lha::Decode::LH7'    => { file => 'lib/Archive/Lha/Decode/LH7.pm' },
            'Archive::Lha::Header'         => { file => 'lib/Archive/Lha/Header.pm' },
            'Archive::Lha::Header::Base'   => { file => 'lib/Archive/Lha/Header/Base.pm' },
            'Archive::Lha::Header::Level0' => { file => 'lib/Archive/Lha/Header/Level0.pm' },
            'Archive::Lha::Header::Level1' => { file => 'lib/Archive/Lha/Header/Level1.pm' },
            'Archive::Lha::Header::Level2' => { file => 'lib/Archive/Lha/Header/Level2.pm' },
            'Archive::Lha::Header::Utils'  => { file => 'lib/Archive/Lha/Header/Utils.pm' },
            'Archive::Lha::Stream'         => { file => 'lib/Archive/Lha/Stream.pm' },
            'Archive::Lha::Stream::Base'   => { file => 'lib/Archive/Lha/Stream/Base.pm' },
            'Archive::Lha::Stream::File'   => { file => 'lib/Archive/Lha/Stream/File.pm' },
            'Archive::Lha::Stream::Hex'    => { file => 'lib/Archive/Lha/Stream/Hex.pm' },
            'Archive::Lha::Stream::String' => { file => 'lib/Archive/Lha/Stream/String.pm' },
        },
    },
    MIN_PERL_VERSION => '5.010',
    EXE_FILES        => ['tools/plha', 'tools/plhasa'],
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean            => { FILES => 'Archive-Lha-*' },
);
