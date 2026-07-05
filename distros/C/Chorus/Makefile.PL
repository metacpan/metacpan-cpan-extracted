use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Chorus',
    AUTHOR           => 'Christophe Ivorra <ch.ivorra@free.fr>',
    VERSION_FROM     => 'lib/Chorus.pm',
    ABSTRACT_FROM    => 'lib/Chorus.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',

    PREREQ_PM => {
        'YAML'          => '0',
        'Scalar::Util'  => '0',
        'Digest::MD5'   => '0',
        'Exporter'      => '0',
    },

    TEST_REQUIRES => {
        'Test::More'          => '0',
        'Test::Warn'          => '0',
        'File::Temp'          => '0',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        keywords    => [qw(
            inference-engine expert-system rule-engine compliance
            symbolic-ai llm yaml frames
        )],
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/civorra/Chorus.git',
                web  => 'https://github.com/civorra/Chorus',
            },
            bugtracker => {
                web => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chorus',
            },
        },
        provides    => {
            'Chorus' => {
                file    => 'lib/Chorus.pm',
                version => '2.0.1',
            },
            'Chorus::Engine' => {
                file    => 'lib/Chorus/Engine.pm',
                version => '2.0.1',
            },
            'Chorus::Expert' => {
                file    => 'lib/Chorus/Expert.pm',
                version => '2.0.1',
            },
            'Chorus::Frame' => {
                file    => 'lib/Chorus/Frame.pm',
                version => '2.0.1',
            },
            'Chorus::Collection::List' => {
                file    => 'lib/Chorus/Collection/List.pm',
                version => '2.0.1',
            },
            'Chorus::Collection::Filter' => {
                file    => 'lib/Chorus/Collection/Filter.pm',
                version => '2.0.1',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'Chorus-*' },
);
