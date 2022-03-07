use 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CLASS',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/CLASS.pm',
    ABSTRACT_FROM       => 'lib/CLASS.pm',
    PL_FILES            => {},
    PREREQ_PM           => {},
    TEST_REQUIRES =>
    {
        'Test::More'    => '0.07',
    },
    LICENSE             => 'perl_5',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CLASS-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@github.com:jackdeguest/CLASS.git',
                web         => 'https://github.com/jackdeguest/CLASS',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jackdeguest/CLASS/issues',
            },
        },
    }) : ()),
);
