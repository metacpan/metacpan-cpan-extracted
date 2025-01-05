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
    NAME                => 'DateTime::Format::Unicode',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/DateTime/Format/Unicode.pm',
    ABSTRACT_FROM       => 'lib/DateTime/Format/Unicode.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'parent'                        => 0,
        'strict'                        => 0,
        'vars'                          => 0,
        'warnings'                      => 0,
        'warnings::register'            => 0,
        'DateTime::Locale::FromCLDR'    => 'v0.6.1',
        'Locale::Unicode'               => 'v0.3.11',
        'POSIX'                         => 0,
        'Scalar::Util'                  => 0,
        # Version compatible with perl v5.10
        'Want'                          => '0.17',
    },
    TEST_REQUIRES =>
    {
        'lib'           => '0.63',
        'utf8'          => 0,
        'version'       => 0,
        # Foreign key constraints since SQLite v3.6.19 (2009-10-14)
        # DBD::SQLite 1.27 (2009-11-23)
        'DBD::SQLite'   => '1.27',
        'File::Find'    => 0,
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.10.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'DateTime-Format-Unicode-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/DateTime-Format-Unicode.git',
                web         => 'https://gitlab.com/jackdeguest/DateTime-Format-Unicode',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/DateTime-Format-Unicode/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

