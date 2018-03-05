use v5.22;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Date::Lectionary',
    AUTHOR             => q{Michael Wayne Arnold <marmanold@cpan.org>},
    VERSION_FROM       => 'lib/Date/Lectionary.pm',
    ABSTRACT           => 'Date::Lectionary - Readings for the Christian Lectionary',
    LICENSE            => 'freebsd',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.022000,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => '0.11'
    },
    BUILD_REQUIRES => {
        'Test::More'          => '1.302040',
        'Test::CheckManifest' => '0.9',
        'Test::Exception'     => '0.43',
    },
    PREREQ_PM => {
        'Carp'                         => '1.38',
        'Try::Tiny'                    => '0.24',
        'Time::Piece'                  => '1.31',
        'Time::Seconds'                => '1.31',
        'Moose'                        => '2.1804',
        'Moose::Util::TypeConstraints' => '2.1804',
        'MooseX::Aliases'              => '0.11',
        'Date::Advent'                 => '1.20160727',
        'Date::Easter'                 => '1.22',
        'Date::Lectionary::Time'       => '1.20160809',
        'namespace::autoclean'         => '0.28',
        'File::Share'                  => '0.25',
        'XML::LibXML'                  => '2.0128',
        'MooseX::StrictConstructor'    => '0.21',
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/marmanold/Date-Lectionary.git',
                web  => 'https://github.com/marmanold/Date-Lectionary',
            },
        },
        provides => {
            'Date::Lectionary' => {
                file    => 'lib/Date/Lectionary.pm',
                version => '1.20180302',
            },
            'Date::Lectionary::Day' => {
                file    => 'lib/Date/Lectionary/Day.pm',
                version => '1.20180302',
            },
            'Date::Lectionary::Year' => {
                file    => 'lib/Date/Lectionary/Year.pm',
                version => '1.20180302',
            },
        },
        keywords  => [qw/ lectionary rcl acna readings christian liturgical /],
        x_twitter => 'https://www.twitter.com/marmanold/',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Date-Lectionary-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);
