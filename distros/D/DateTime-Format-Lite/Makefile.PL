use ExtUtils::MakeMaker;
use strict;
use warnings;

# Check for a C compiler. XS is optional: if unavailable, the pure-Perl
# fallback is used automatically for _match_and_extract and format_datetime.
my $has_cc = eval
{
    require ExtUtils::CBuilder;
    my $b = ExtUtils::CBuilder->new( quiet => 1 );
    $b->have_compiler;
};

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

# Add inc/ to @INC during testing so stub modules are found.
sub MY::test_via_harness
{
    my( $self, $perl, $tests ) = @_;
    return( qq{\t$perl "-Iinc" "-Iblib/lib" "-Iblib/arch" }
          . qq{"-MExtUtils::Command::MM" "-MTest::Harness" }
          . qq{-e "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" }
          . qq{$tests\n} );
}

sub MY::test_via_script
{
    my( $self, $perl, $tests ) = @_;
    return( qq{\t$perl "-Iinc" "-Iblib/lib" "-Iblib/arch" $tests\n} );
}

my %WriteMakefileArgs = (
    NAME                => 'DateTime::Format::Lite',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/DateTime/Format/Lite.pm',
    ABSTRACT_FROM       => 'lib/DateTime/Format/Lite.pm',
    INSTALLDIRS      => ( $] < 5.011 ? 'perl' : 'site' ),
    MIN_PERL_VERSION    => 'v5.10.1',
    LICENSE             => 'perl_5',
    PL_FILES            => {},
    PREREQ_PM           =>
    {
        'strict'                     => 0,
        'vars'                       => 0,
        'warnings'                   => 0,
        'warnings::register'         => 0,
        # DateTime::Lite ecosystem
        'DateTime::Lite'             => 'v0.5.0',
        'DateTime::Locale::FromCLDR' => 'v0.8.2',
        'Exporter'                   => 0,
        'Locale::Unicode'            => 'v0.4.0',
        'POSIX'                      => 0,
        'Scalar::Util'               => 0,
        # Version compatible with perl v5.10
        'Wanted'                     => 'v0.1.0',
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'open'              => 0,
        'Test::More'        => '1.302162',
        'Test::Pod'         => '1.52',
    },
    ( $has_cc
        ? (
            XS     => { 'DateTime-Format-Lite.xs' => 'DateTime-Format-Lite.c' },
            OBJECT => 'DateTime-Format-Lite$(OBJ_EXT)',
        )
        : ()
    ),
    INC    => '-I.',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    # Do not recurse into subdirectories (prevents old DateTime-Lite-vX.X.X/ directories from triggering a double execution of Makefile.PL)
    DIR    => [],
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean  => { FILES => 'DateTime-Format-Lite-* DateTime-Format-Lite.c DateTime-Format-Lite$(OBJ_EXT)' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE =>
    {
        'meta-spec'    => { version => 2 },
        dynamic_config => 1,
        no_index       =>
        {
            directory => [ 't', 'inc' ],
        },
        resources =>
        {
            repository =>
            {
                url  => 'git@gitlab.com:jackdeguest/DateTime-Format-Lite.git',
                web  => 'https://gitlab.com/jackdeguest/DateTime-Format-Lite',
                type => 'git',
            },
            bugtracker =>
            {
                web => 'https://gitlab.com/jackdeguest/DateTime-Format-Lite/issues',
            },
        },
        x_contributors => [],
    }) : () ),
);

WriteMakefile(%WriteMakefileArgs);
