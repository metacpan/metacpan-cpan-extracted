use ExtUtils::MakeMaker;
use strict;
use warnings;

my %WriteMakefileArgs = (
    NAME                => 'Changes',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/Changes.pm',
    ABSTRACT_FROM       => 'lib/Changes.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'overload'      => 0,
        'parent'        => 0,
        'strict'        => 0,
        'vars'          => 0,
        'version'       => 0,
        'warnings'      => 0,
        'DateTime'      => '1.57',
        'Module::Generic'    => 'v0.29.1',
        'Nice::Try'     => 'v1.3.1',
        'Want'          => '0.29',
    },
    TEST_REQUIRES =>
    {
        'open'          => 0,
        'utf8'          => 0,
        'Test::More'    => '1.302162',
        'Test::Time'    => 0,
        'DateTime::Format::Strptime' => '1.79',
        'DateTime::Format::JP' => 'v0.1.3',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Changesc-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Changes.git',
                web         => 'https://gitlab.com/jackdeguest/Changes',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Changes/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
