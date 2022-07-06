use ExtUtils::MakeMaker;
use strict;
use warnings;

my %WriteMakefileArgs = (
    NAME                => 'DateTime::Format::JP',
    VERSION_FROM        => 'lib/DateTime/Format/JP.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT_FROM       => 'lib/DateTime/Format/JP.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'parent'        => 0,
        'strict'        => '0.238',
        'utf8'          => 0,
        'warnings'      => '1.44',
        'DateTime'      => '1.54',
        'Nice::Try'     => 'v1.1.2',
    },
    TEST_REQUIRES =>
    {
        'utf8'          => 0,
        'open'          => '1.11',
        'Test::More'    => '1.302182',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.14.0',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-PO-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/DateTime-Format-JP.git',
                web         => 'https://gitlab.com/jackdeguest/DateTime-Format-JP',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/DateTime-Format-JP/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

__END__
