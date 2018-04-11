use v5.22;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Date::Lectionary::Daily',
    AUTHOR             => q{Michael Wayne Arnold <marmanold@cpan.org>},
    VERSION_FROM       => 'lib/Date/Lectionary/Daily.pm',
    ABSTRACT           => 'Date::Lectionary::Daily - Daily Readings for the Christian Lectionary',
    LICENSE            => 'freebsd',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.022000,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => '7.32',
        'File::ShareDir::Install' => '0.11'
    },
    BUILD_REQUIRES => {
        'Test::More'            => '1.302130',
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
        'Carp'                         => '1.38',
        'Try::Tiny::Tiny'              => '0.001',
        'Try::Catch'                   => '1.1.0',
        'Time::Piece'                  => '1.3204',
        'Time::Seconds'                => '1.3204',
        'Moose'                        => '2.2010',
        'Moose::Util::TypeConstraints' => '2.2010',
        'MooseX::Aliases'              => '0.11',
        'Date::Advent'                 => '1.20171223',
        'Date::Easter'                 => '1.22',
        'Date::Lectionary::Time'       => '1.20170311',
        'Date::Lectionary'             => '1.20180302',
        'Date::Lectionary::Day'        => '1.20180302',
        'namespace::autoclean'         => '0.28',
        'File::Share'                  => '0.25',
        'XML::LibXML'                  => '2.0132',
        'MooseX::StrictConstructor'    => '0.21',
        'version'                      => '0.9920',
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/marmanold/Date-Lectionary-Daily.git',
                web  => 'https://github.com/marmanold/Date-Lectionary-Daily',
            },
        },
        provides => {
            'Date::Lectionary::Daily' => {
                file    => 'lib/Date/Lectionary/Daily.pm',
                version => '1.20180410',
            },
        },
        keywords  => [qw/ lectionary rcl acna readings christian liturgical /],
        x_twitter => 'https://www.twitter.com/marmanold/',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Date-Lectionary-Daily*' },
);

package MY;
use File::ShareDir::Install qw(postamble);
