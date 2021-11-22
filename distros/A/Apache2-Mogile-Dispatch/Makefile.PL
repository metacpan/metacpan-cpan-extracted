use ExtUtils::MakeMaker;
use strict;
use warnings;

my %WriteMakefileArgs = (
    NAME                => 'Apache2::Mogile::Dispatch',
    VERSION_FROM        => 'lib/Apache2/Mogile/Dispatch.pm',
    AUTHOR              => 'Nick Gerakines <nick@socklabs.com>',
    ABSTRACT_FROM       => 'lib/Apache2/Mogile/Dispatch.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'MogileFS'      => 0,
        'English'       => 0,
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => 0,
        'Test::Group'   => 0,
        'YAML::Syck'    => 0,
        'LWP::UserAgent' => 0,
        'Cache::Memcached' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache2-Mogile-Dispatch-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Apache2-Mogile-Dispatch.git',
                web         => 'https://git.deguest.jp/jack/Apache2-Mogile-Dispatch',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Apache2-Mogile-Dispatch',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
