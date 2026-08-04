use 5.026;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Audio::Scrobbler2',
    VERSION_FROM     => 'lib/Audio/Scrobbler2.pm',
    MIN_PERL_VERSION => '5.026',
    LICENSE          => 'perl_5',
    AUTHOR           => ['Pier Dolique (Perdolique) <baget@cpan.org>'],
    ABSTRACT         => 'Interface to the Last.fm scrobbling API',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'Carp'            => 0,
        'Digest::MD5'     => 0,
        'Encode'          => 0,
        'HTTP::Tiny'      => '0.084',
        'IO::Socket::SSL' => '1.56',
        'JSON::PP'        => 0,
        'Mozilla::CA'     => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        resources   => {
            bugtracker => {
                web => 'https://github.com/Perdolique/Audio-Scrobbler2/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/Perdolique/Audio-Scrobbler2.git',
                web  => 'https://github.com/Perdolique/Audio-Scrobbler2',
            },
        },
    },
);
