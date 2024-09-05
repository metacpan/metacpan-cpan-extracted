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
    NAME                => 'DateTime::TimeZone::Catalog::Extend',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/DateTime/TimeZone/Catalog/Extend.pm',
    ABSTRACT_FROM       => 'lib/DateTime/TimeZone/Catalog/Extend.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'strict'        => 0,
        'warnings'      => 0,
        'DateTime::TimeZone::Alias' => '0.06',
        # 'Nice::Try'     => 'v1.3.1',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => '1.302162',
        'DateTime::TimeZone' => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', },
    clean               => { FILES => 'DateTime-TimeZone-Catalog-Extend-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/DateTime-TimeZone-Catalog-Extend.git',
                web         => 'https://gitlab.com/jackdeguest/DateTime-TimeZone-Catalog-Extend',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/DateTime-TimeZone-Catalog-Extend/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
