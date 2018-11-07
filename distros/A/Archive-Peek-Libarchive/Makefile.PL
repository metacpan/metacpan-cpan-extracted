#!perl
use strict;
use warnings;

# use lib qw(inc);
use Config::AutoConf;
use ExtUtils::MakeMaker;
use File::Basename;
use File::Spec;
use Text::ParseWords;

my %RUN_DEPS = (
    'Object::Tiny' => 0,
    'XSLoader'     => 0,
);
my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker' => 0,
    'Capture::Tiny'       => '0.06',
    'ExtUtils::CBuilder'  => '0.27',
    'Config::AutoConf'    => '0.317',
    'File::Basename'      => 0,
    'File::Spec'          => 0,
    'parent'              => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Test::More' => 0.90,
);

my $autoconf = Config::AutoConf->new();
my @epf      = @{$autoconf->{extra_preprocess_flags}};
$autoconf->pkg_config_package_flags("libarchive");

my $have_libarchive = $autoconf->check_header("archive.h") and $autoconf->search_libs("archive_read_open_filename", ["archive"]);
$have_libarchive or die <<EOD;
*******************************************
Couldn't find libarchive, which is required
for this module.

To obtain it, go to
    http://www.libarchive.org/
*******************************************
EOD

my $xsfile = "Libarchive.xs";
WriteMakefile1(
    MIN_PERL_VERSION => '5.008001',
    META_ADD         => {
        license     => ['perl_5', 'bsd', 'cc0_1_0', 'freebsd'],
        'meta-spec' => {version => 2},
        resources   => {
            homepage   => 'https://metacpan.org/release/Archive-Peek-Libarchive',
            repository => {
                url  => 'https://github.com/rehsack/Archive-Peek-Libarchive.git',
                web  => 'https://github.com/rehsack/Archive-Peek-Libarchive',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Archive-Peek-Libarchive',
                mailto => 'bug-Archive-Peek-Libarchive@rt.cpan.org',
            },
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::CPAN::Changes'                 => 0,
                    'Test::CheckManifest'                 => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                },
            },
            configure => {
                requires => {%CONFIGURE_DEPS},
            },
            build   => {requires => {%BUILD_DEPS}},
            test    => {requires => {%TEST_DEPS}},
            runtime => {
                recommends => {},
                requires   => {
                    %RUN_DEPS,
                    perl => '5.8.1',
                },
            },
        },
    },
    NAME           => 'Archive::Peek::Libarchive',
    VERSION_FROM   => 'lib/Archive/Peek/Libarchive.pm',
    ABSTRACT_FROM  => 'lib/Archive/Peek/Libarchive.pm',
    LICENSE        => 'perl',
    AUTHOR         => ['Leon Brocard <acme@astray.com>'],
    XS             => {$xsfile => "Libarchive.c"},
    OBJECT         => q/$(O_FILES)/,
    INC            => $autoconf->_get_extra_compiler_flags,
    LIBS           => $autoconf->_get_extra_linker_flags,
    PREREQ_PM      => \%RUN_DEPS,
    BUILD_REQUIRES => {%BUILD_DEPS, %CONFIGURE_DEPS},
    TEST_REQUIRES  => \%TEST_DEPS,
    clean          => {FILES => "Archive-Peek-Libarchive-* *.o config.log"},
    test           => {TESTS => 't/*.t xt/*.t'},
);

sub WriteMakefile1
{    # originally written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if (exists($params{EXTRA_META}));
    die "License not specified"    if (!exists($params{LICENSE}));
    $params{TEST_REQUIRES}
      and $eumm_version < 6.6303
      and $params{BUILD_REQUIRES} = {%{$params{BUILD_REQUIRES} || {}}, %{delete $params{TEST_REQUIRES}}};
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{BUILD_REQUIRES}
      and $eumm_version < 6.5503
      and $params{PREREQ_PM} = {%{$params{PREREQ_PM} || {}}, %{delete $params{BUILD_REQUIRES}}};
    ref $params{AUTHOR}
      and "ARRAY" eq ref $params{AUTHOR}
      and $eumm_version < 6.5702
      and $params{AUTHOR} = join(", ", @{$params{AUTHOR}});
    delete $params{CONFIGURE_REQUIRES}    if ($eumm_version < 6.52);
    delete $params{MIN_PERL_VERSION}      if ($eumm_version < 6.48);
    delete $params{META_MERGE}            if ($eumm_version < 6.46);
    delete $params{META_ADD}{prereqs}     if ($eumm_version < 6.58);
    delete $params{META_ADD}{'meta-spec'} if ($eumm_version < 6.58);
    delete $params{META_ADD}              if ($eumm_version < 6.46);
    delete $params{LICENSE}               if ($eumm_version < 6.31);
    delete $params{AUTHOR}                if ($] < 5.005);
    delete $params{ABSTRACT_FROM}         if ($] < 5.005);
    delete $params{BINARY_LOCATION}       if ($] < 5.005);

    # more or less taken from Moose' Makefile.PL
    if ($params{CONFLICTS})
    {
        my $ok = CheckConflicts(%params);
        exit(0) if ($params{PREREQ_FATAL} and not $ok);
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ($cpan_smoker || $ENV{PERL_MM_USE_DEFAULT})
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
