use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Generic',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/Class/Generic.pm',
    ABSTRACT_FROM       => 'lib/Class/Generic.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'parent'        => 0,
        'strict'        => 0,
        'version'       => 0,
        'warnings'      => 0,
        'Module::Generic'   => 'v0.21.7',
    },
    TEST_REQUIRES =>
    {
        'File::Find'    => 0,
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Generic-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Class-Generic.git',
                web         => 'https://git.deguest.jp/jack/Class-Generic',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://git.deguest.jp/jack/Class-Generic/issues',
            },
        },
    }) : ()),
);
