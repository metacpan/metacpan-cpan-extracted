use ExtUtils::MakeMaker;
use strict;
use warnings;

sub MY::distsignature
{
    return << 'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

my %WriteMakefileArgs = (
    NAME                => 'DateTime::Format::Intl',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/DateTime/Format/Intl.pm',
    ABSTRACT_FROM       => 'lib/DateTime/Format/Intl.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'parent'                        => 0,
        'strict'                        => 0,
        'vars'                          => 0,
        'warnings'                      => 0,
        'warnings::register'            => 0,
        # 2008-02-29
        'DateTime'                      => '0.42',
        'DateTime::Locale::FromCLDR'    => 'v0.6.0',
        'DateTime::Format::Unicode'     => 'v0.1.5',
        'Locale::Intl'                  => 'v0.1.2',
        'Locale::Unicode::Data'         => 'v1.3.0',
        'Scalar::Util'                  => 0,
        # Version compatible with perl v5.10.1
        'Want'                          => '0.17',
    },
    TEST_REQUIRES =>
    {
        'lib'               => '0.63',
        'open'              => 0,
        'utf8'              => 0,
        # Released 2017-11-30
        'Test::More'        => '1.302120',
        'Test::Pod'         => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.10.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'DateTime-Format-Intl-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/DateTime-Format-Intl.git',
                web         => 'https://gitlab.com/jackdeguest/DateTime-Format-Intl',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/DateTime-Format-Intl/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

