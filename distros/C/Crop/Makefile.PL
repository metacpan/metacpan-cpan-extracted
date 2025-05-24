use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Crop',
    VERSION_FROM => 'lib/Crop.pm',
    AUTHOR       => 'Alex <alextechnologies@gmail.com>',
    ABSTRACT     => 'A configuration management module for Crop framework',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Test::More' => 0,
        'XML::LibXML' => 0,
        'Time::Stamp' => 0,
        'Clone' => 0,
        'XML::LibXSLT' => 0,
        'JSON' => 0,
        'CGI::Cookie' => 0,
        'CGI::Fast' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/alextech7/crop',
            bugtracker => 'hhttps://github.com/alextech7/crop/issues',
        },
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        DIST_DEFAULT => 'all tardist',
    },
);
