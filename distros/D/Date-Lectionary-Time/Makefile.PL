use v5.22;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Date::Lectionary::Time',
    AUTHOR       => q{Michael Wayne Arnold <marmanold@cpan.org>},
    VERSION_FROM => 'lib/Date/Lectionary/Time.pm',
    ABSTRACT =>
'Working in the liturgical time of the lectionary means tracking time relative to Sundays.  This is a quick utility to find the next, previous, or the closest Sunday to a given date.',
    LICENSE            => 'perl_5',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.022000,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'          => '1.302040',
        'Test::CheckManifest' => '0.9',
        'Test::Exception'     => '0.43',
    },
    PREREQ_PM => {
        'Carp'           => '1.38',
        'Try::Tiny'      => '0.24',
        'Time::Piece'    => '1.31',
        'Time::Seconds'  => '1.31',
        'Exporter::Easy' => '0.18',
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/marmanold/Date-Lectionary-Time.git',
                web  => 'https://github.com/marmanold/Date-Lectionary-Time',
            },
        },
        provides => {
            'Date::Lectionary::Time' => {
                file => 'lib/Date/Lectionary/Time.pm',
                version => '1.20170311',
            },
        },
        keywords  => [qw/ lectionary christian liturgical /],
        x_twitter => 'https://www.twitter.com/marmanold/',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Date-Lectionary-Time-*' },
);
