use ExtUtils::MakeMaker;
use strict;
use warnings;

# Check for a C compiler. XS is optional: if unavailable, the pure-Perl
# fallback in DateTime::Lite::PP is used automatically.
my $has_cc = eval
{
    require ExtUtils::CBuilder;
    my $b = ExtUtils::CBuilder->new( quiet => 1 );
    $b->have_compiler;
};

# We attempt to detect DBD::SQLite availability
my $has_sqlite = eval
{
    require DBD::SQLite;
    DBD::SQLite->VERSION(1.27);
    1;
};

my $has_dbi = eval
{
    require DBI;
    DBI->VERSION(1.611);
    1;
};

# If neither DBD::SQLite / DBI or DateTime::TimeZone are available, then, we cannot use
# DateTime::Lite::TimeZone
if( !$has_sqlite || !$has_dbi )
{
    my $has_dt_tz = eval
    {
        require DateTime::TimeZone;
        DateTime::TimeZone->VERSION(2.44);
        1;
    };
    if( $has_dt_tz )
    {
        warn( "DBD::SQLite (>1.27) was not found, so we fallback to DateTime::TimeZone\n" );
    }
    else
    {
        warn( "Neither DBD::SQLite or DateTime::TimeZone is installed, so you will not be able to use DateTime::Lite::TimeZone\n" );
    }
}

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
    NAME             => 'DateTime::Lite',
    AUTHOR           => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM     => 'lib/DateTime/Lite.pm',
    ABSTRACT_FROM    => 'lib/DateTime/Lite.pm',
    INSTALLDIRS      => ( $] < 5.011 ? 'perl' : 'site' ),
    # 2009-08-23
    MIN_PERL_VERSION => 'v5.10.1',
    LICENSE          => 'perl_5',
    PREREQ_PM        =>
    {
        # Core modules
        'overload'                   => 0,
        'overloading'                => 0,
        'strict'                     => 0,
        'vars'                       => 0,
        # parse() reliable since at least from version 0.43 in 2005-06-06, predating our perl version requirements
        'version'                    => 0,
        'warnings'                   => 0,
        'warnings::register'         => 0,
        'Config'                     => 0,
        'Cwd'                        => 0,
        # Non-core runtime dependencies (minimal set)
        'DateTime::Locale::FromCLDR' => 'v0.8.0',
        # DBD::SQLite is used by DateTime::Lite::TimeZone for the bundled SQLite
        # timezone database. If unavailable, it falls back to DateTime::TimeZone
        # automatically.
        # Foreign key constraints since SQLite v3.6.19 (2009-10-14)
        # DBD::SQLite 1.27 (2009-11-23)
        # utf8 auto decoding from version 1.68 (2021-07-22)
        # 'DBD::SQLite'                => '1.27',
        # 2010-04-29
        # 'DBI'                        => '1.611',
        # DateTime::TimeZone is lazy loaded, and if neither SQLite nor this module is
        # available, this will complain and die.
        # 'DateTime::TimeZone'         => '2.44',
        # 2010-04-02
        'JSON'                       => '2.20',
        'Locale::Unicode'            => 'v0.4.0',
        'POSIX'                      => 0,
        'Scalar::Util'               => 0,
        # 'Storable'                   => 0,
        # Version compatible with perl v5.10
        'Wanted'                     => 'v0.1.0',
    },
    TEST_REQUIRES =>
    {
        'lib'           => '0',
        # Released 2017-11-30
        'Test::More'    => '1.302120',
        'Test::Pod'     => '1.52',
        # Core module
        'Time::Local'   => '0',
    },
    ( $has_cc
        ? (
            XS      => { 'DateTime-Lite.xs' => 'DateTime-Lite.c' },
            OBJECT  => 'DateTime-Lite$(OBJ_EXT)',
        )
        : ()
    ),
    INC    => '-I.',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    # Do not recurse into subdirectories (prevents old DateTime-Lite-vX.X.X/ directories from triggering a double execution of Makefile.PL)
    DIR    => [],
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean  => { FILES => 'DateTime-Lite-* DateTime-Lite.c DateTime-Lite$(OBJ_EXT)' },
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
                url  => 'git@gitlab.com:jackdeguest/DateTime-Lite.git',
                web  => 'https://gitlab.com/jackdeguest/DateTime-Lite',
                type => 'git',
            },
            bugtracker =>
            {
                web => 'https://gitlab.com/jackdeguest/DateTime-Lite/issues',
            },
        },
        x_contributors => [],
    }) : () ),
);

WriteMakefile( %WriteMakefileArgs );
