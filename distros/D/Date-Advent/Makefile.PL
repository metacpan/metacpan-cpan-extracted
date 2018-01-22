use v5.22;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Date::Advent',
    AUTHOR             => q{Michael Wayne Arnold <marmanold@cpan.org>},
    VERSION_FROM       => 'lib/Date/Advent.pm',
    ABSTRACT           => 'Date::Advent takes a Time::Piece date and calculates all four Sundays of Advent for the current Christian liturgical year.',
    LICENSE            => 'freebsd',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.022000,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => {
        'Test::More'          => '1.302040',
        'Test::CheckManifest' => '0.9',
        'Test::Exception'     => '0.43',
    },
    PREREQ_PM => {
        'Carp'                      => '1.38',
        'Time::Piece'               => '1.31',
        'Moose'                     => '2.1804',
        'Date::Lectionary::Time'    => '1.20160727',
        'namespace::autoclean'      => '0.28',
        'MooseX::StrictConstructor' => '0.21',
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/marmanold/Date-Advent.git',
                web  => 'https://github.com/marmanold/Date-Advent',
            },
        },
        provides => {
            'Date::Advent' => {
                file    => 'lib/Date/Advent.pm',
                version => '1.20171223',
            },
        },
        keywords  => [qw/ advent christmas lectionary christian liturgical /],
        x_twitter => 'https://www.twitter.com/marmanold/',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Date-Advent-*' },
);
