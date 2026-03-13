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
    NAME                => 'App::mailmake',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/App/mailmake.pm',
    ABSTRACT_FROM       => 'lib/App/mailmake.pm',
    PL_FILES            => {},
    EXE_FILES           => [qw( scripts/mailmake )],
    PREREQ_PM           => {
        'open'                      => 0,
        'parent'                    => 0,
        'strict'                    => 0,
        'utf8'                      => 0,
        'vars'                      => 0,
        'warnings'                  => 0,
        'Encode'                    => '3.21',
        'Getopt::Class'             => 'v1.1.4',
        'Mail::Make'                => 'v0.21.0',
        'Module::Generic'           => 'v1.2.1',
        'Pod::Usage'                => '2.01',
        'Term::ANSIColor::Simple'   => '0.10',
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'IO::Select'        => 0,
        'IPC::Open3'        => 0,
        'Test::More'        => '1.302162',
        'Test::Pod'         => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.28.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'App-mailmake-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/App-mailmake.git',
                web         => 'https://gitlab.com/jackdeguest/App-mailmake',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/App-mailmake/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

