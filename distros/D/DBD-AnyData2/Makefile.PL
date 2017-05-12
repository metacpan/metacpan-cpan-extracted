use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker;

my %RUN_DEPS = (
    "AnyData2"        => "0.002",
    "Carp"            => 0,
    "DBD::File"       => "0.44",
    "DBI"             => "1.633",
    "Module::Runtime" => 0,
    "SQL::Statement"  => "1.405",
);
my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker' => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Test::More' => 0.90,
);

WriteMakefile1(
    META_ADD => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://metacpan.org/release/DBD-AnyData2',
            repository => {
                url  => 'git@github.com:perl5-dbi/DBD-AnyData2.git',
                web  => 'https://github.com/perl5-dbi/DBD-AnyData2',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=DBD-AnyData2',
                mailto => 'bug-dbd-anydata2@rt.cpan.org',
            },
            license => 'http://dev.perl.org/licenses/',
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::CPAN::Changes'                 => 0,
                    'Test::CheckManifest'                 => 0,
                    'Module::CPANTS::Analyse'             => '0.96',
                    'Test::Kwalitee'                      => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                    'Test::Spelling'                      => 0,
                },
            },
            configure => {
                requires => {%CONFIGURE_DEPS},
            },
            build   => { requires => {%BUILD_DEPS} },
            test    => { requires => {%TEST_DEPS} },
            runtime => {
                recommends => {},
                requires   => { %RUN_DEPS, },
            },
        },
    },
    NAME             => 'DBD::AnyData2',
    AUTHOR           => q{Jens Rehsack <rehsack@cpan.org>},
    VERSION_FROM     => 'lib/DBD/AnyData2.pm',
    ABSTRACT_FROM    => 'lib/DBD/AnyData2.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    PREREQ_PM        => \%RUN_DEPS,
    BUILD_REQUIRES   => \%BUILD_DEPS,
    TEST_REQUIRES    => \%TEST_DEPS,
    test             => { TESTS => 't/*.t xt/*.t' },
    dist             => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => { FILES => 'DBD-AnyData2-*' },
);

sub WriteMakefile1
{    # originally written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if ( exists( $params{EXTRA_META} ) );
    die "License not specified"    if ( !exists( $params{LICENSE} ) );
    $params{TEST_REQUIRES}
      and $eumm_version < 6.6303
      and $params{BUILD_REQUIRES} =
      $params{BUILD_REQUIRES} ? { %{ $params{BUILD_REQUIRES} }, %{ $params{TEST_REQUIRES} } } : delete $params{TEST_REQUIRES};
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{BUILD_REQUIRES}
      and $eumm_version < 6.5503
      and $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ delete $params{BUILD_REQUIRES} } };
    delete $params{CONFIGURE_REQUIRES}    if ( $eumm_version < 6.52 );
    delete $params{MIN_PERL_VERSION}      if ( $eumm_version < 6.48 );
    delete $params{META_MERGE}            if ( $eumm_version < 6.46 );
    delete $params{META_ADD}{prereqs}     if ( $eumm_version < 6.58 );
    delete $params{META_ADD}{'meta-spec'} if ( $eumm_version < 6.58 );
    delete $params{META_ADD}              if ( $eumm_version < 6.46 );
    delete $params{LICENSE}               if ( $eumm_version < 6.31 );
    delete $params{AUTHOR}                if ( $] < 5.005 );
    delete $params{ABSTRACT_FROM}         if ( $] < 5.005 );
    delete $params{BINARY_LOCATION}       if ( $] < 5.005 );

    # more or less taken from Moose' Makefile.PL
    if ( $params{CONFLICTS} )
    {
        my $ok = CheckConflicts(%params);
        exit(0) if ( $params{PREREQ_FATAL} and not $ok );
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ( $cpan_smoker || $ENV{PERL_MM_USE_DEFAULT} )
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
