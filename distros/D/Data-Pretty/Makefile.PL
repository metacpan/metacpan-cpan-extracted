use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Data::Pretty',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Data/Pretty.pm',
    ABSTRACT_FROM       => 'lib/Data/Pretty.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'overload'      => 0,
        'parent'        => 0,
        'strict'        => 0,
        'subs'          => 0,
        'vars'          => 0,
        'warnings'      => 0,
        'Symbol'        => 0,
    },
    TEST_REQUIRES =>
    {
        'lib'           => 0,
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.006',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Data-Pretty-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Data-Pretty.git',
                web         => 'https://gitlab.com/jackdeguest/Data-Pretty',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Data-Pretty/issues',
            },
        },
        recommends => {
           'MIME::Base64' => 0,
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

