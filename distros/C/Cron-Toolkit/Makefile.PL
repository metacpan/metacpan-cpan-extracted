use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Cron::Toolkit',
    AUTHOR           => 'Nathaniel Graham <ngraham@cpan.org>',
    VERSION_FROM     => 'lib/Cron/Toolkit.pm',
    ABSTRACT_FROM    => 'lib/Cron/Toolkit.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.012',

    PL_FILES         => {},

    # Runtime dependencies (installed for ALL users automatically)
    PREREQ_PM        => {
        'Time::Moment'       => 0,
        'DateTime::TimeZone' => 0,
        'DateTime::Duration' => 0,
        'JSON::MaybeXS'      => 0,
        'List::Util'         => 0,
    },

    # Test-time only dependencies
    TEST_REQUIRES    => {
        'Test::More'          => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'JSON::PP'            => 0,
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'Cron-Toolkit-* MANIFEST' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/nathanielgraham/cron-toolkit-perl.git',
                web  => 'https://github.com/nathanielgraham/cron-toolkit-perl',
            },
            bugtracker => {
                web => 'https://github.com/nathanielgraham/cron-toolkit-perl/issues',
            },
        },
    },
);
