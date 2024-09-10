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
    NAME                => 'DateTime::Locale::FromCLDR',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/DateTime/Locale/FromCLDR.pm',
    ABSTRACT_FROM       => 'lib/DateTime/Locale/FromCLDR.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => 
    {
        # available in perl v5.10
        'overload'              => '1.06',
        # available in perl v5.10
        'strict'                => 0,
        'vars'                  => 0,
        'warnings'              => 0,
        'warnings::register'    => 0,
        'Locale::Unicode'       => 'v0.3.6',
        'Locale::Unicode::Data' => 'v1.0.0',
        'Scalar::Util'          => 0,
        # Version compatible with perl v5.10
        'Want'                  => '0.17',
    },
    TEST_REQUIRES =>
    {
        'lib'           => '0.63',
        'utf8'          => 0,
        'version'       => 0,
        # 2008-02-29
        'DateTime'      => '0.42',
        # Foreign key constraints since SQLite v3.6.19 (2009-10-14)
        # DBD::SQLite 1.27 (2009-11-23)
        'DBD::SQLite'   => '1.27',
        'File::Find'    => 0,
        # Released 2017-11-30
        'Test::More'    => '1.302120',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    # 2007-12-18
    MIN_PERL_VERSION    => 'v5.10',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'DateTime-Locale-FromCLDR-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/DateTime-Locale-FromCLDR.git',
                web         => 'https://gitlab.com/jackdeguest/DateTime-Locale-FromCLDR',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/DateTime-Locale-FromCLDR/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
