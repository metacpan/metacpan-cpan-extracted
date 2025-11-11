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
    NAME                => 'App::jsonvalidate',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/App/jsonvalidate.pm',
    ABSTRACT_FROM       => 'lib/App/jsonvalidate.pm',
    PL_FILES            => {},
    EXE_FILES           => [qw( scripts/jsonvalidate )],
    PREREQ_PM           => {
        'open'                      => 0,
        'strict'                    => 0,
        'utf8'                      => 0,
        'vars'                      => 0,
        'warnings'                  => 0,
        'Getopt::Class'             => 'v1.1.4',
        'JSON'                      => '4.10',
        'JSON::Schema::Validate'    => 'v0.3.0',
        'Module::Generic'           => 'v1.1.3',
        'Pod::Usage'                => '2.01',
        'Term::ANSIColor::Simple'   => '0.10',
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'Test::More'        => '1.302162',
        'Test::Pod'         => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.16.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'App-jsonvalidate-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/App-jsonvalidate.git',
                web         => 'https://gitlab.com/jackdeguest/App-jsonvalidate',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/App-jsonvalidate/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

