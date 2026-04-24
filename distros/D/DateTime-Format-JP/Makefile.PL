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
    NAME                => 'DateTime::Format::JP',
    VERSION_FROM        => 'lib/DateTime/Format/JP.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT_FROM       => 'lib/DateTime/Format/JP.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'parent'        => 0,
        'strict'        => 0,
        'utf8'          => 0,
        'warnings'      => 0,
        # 2026-04-24
        'DateTime::Lite' => '0.6.4',
    },
    TEST_REQUIRES =>
    {
        'utf8'          => 0,
        # 2011-05-15
        'open'          => '1.08',
        # 2011-02-23
        'Test::More'    => '0.98',
        # 2011-03-09
        'Test::Pod'     => '1.45',
    },
    LICENSE             => 'perl_5',
    # 2011-05-14
    MIN_PERL_VERSION    => 'v5.14.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'DateTime-Format-JP-*' },
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
