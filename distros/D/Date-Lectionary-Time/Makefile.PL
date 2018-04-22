use v5.22;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Date::Lectionary::Time',
    AUTHOR             => q{Michael Wayne Arnold <michael@rnold.info>},
    VERSION_FROM       => 'lib/Date/Lectionary/Time.pm',
    ABSTRACT           => 'Working in the liturgical time of the lectionary means tracking time relative to Sundays.  This is a quick utility to find the next, previous, or the closest Sunday to a given date.',
    LICENSE            => 'freebsd',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.022000,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => {
        'Test::More'            => '1.302040',
        'Test::DistManifest'    => '1.014',
        'Test::Exception'       => '0.43',
        'Pod::Markdown'         => '3.005',
        'Test::Pod'             => '1.51',
        'Test::Pod::Coverage'   => '1.10',
        'Test::MinimumVersion'  => '0.101082',
        'Test::Kwalitee::Extra' => '0.4.0',
        'Test::Kwalitee'        => '1.27',
        'Test::CPAN::Changes'   => '0.400002',
        'Test::Version'         => '2.07',
    },
    PREREQ_PM => {
        'Carp'            => '1.38',
        'Try::Tiny'       => '0.24',
        'Time::Piece'     => '1.31',
        'Time::Seconds'   => '1.31',
        'Exporter::Easy'  => '0.18',
        'Try::Catch'      => '1.1.0',
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
                file    => 'lib/Date/Lectionary/Time.pm',
                version => '1.20180422.1',
            },
        },
        keywords  => [qw/ lectionary christian liturgical /],
        x_twitter => 'https://www.twitter.com/marmanold/',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Date-Lectionary-Time-*' },
);
