use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker;

my %RUN_DEPS = ($] < 5.007003 ? ('Clone::PP' => 0) : ('Storable' => 0));

my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker' => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Test::More'            => 0.90,
    'Test::Without::Module' => 0,
);

if (-d 'Sandbox')
{
    unless (grep { $_ eq '.' } @INC)
    {
        use lib '.';
    }
    eval "use Sandbox::Tumble ();";
    $@ and die $@;
    eval "use File::Path ();";
    File::Path->import;
    -d 't/Auto'     and rmtree('t/Auto');
    -d 't/Clone'    and rmtree('t/Clone');
    -d 't/Storable' and rmtree('t/Storable');
    -d 't/ClonePP'  and rmtree('t/ClonePP');
    Sandbox::Tumble->tumble(qw(t));
}

WriteMakefile1(
    MIN_PERL_VERSION => '5.008001',
    META_MERGE       => {
        'meta-spec'    => {version => 2},
        dynamic_config => 1,
        resources      => {
            homepage   => 'https://metacpan.org/release/Clone-Choose',
            repository => {
                url  => 'https://github.com:perl5-utils/Clone-Choose.git',
                web  => 'https://github.com/perl5-utils/Clone-Choose',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Clone-Choose',
                mailto => 'bug-Clone-Choose@rt.cpan.org',
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
                    'Test::Perl::Critic'                  => 0,
                    'Test::PerlTidy'                      => 0,
                    'Test::WriteVariants'                 => '0.014',
                },
            },
            configure => {
                requires => {%CONFIGURE_DEPS},
            },
            build => {requires => {%BUILD_DEPS}},
            test  => {
                requires => {%TEST_DEPS},
                suggests => {
                    'Clone'     => 0.10,
                    'Clone::PP' => 0,
                    'Storable'  => 0
                }
            },
            runtime => {
                requires => {
                    %RUN_DEPS,
                    perl => '5.8.1',
                },
                recommends => {
                    'Module::Runtime' => 0,
                },
            },
        },
    },
    NAME               => 'Clone::Choose',
    VERSION_FROM       => 'lib/Clone/Choose.pm',
    ABSTRACT_FROM      => 'lib/Clone/Choose.pm',
    LICENSE            => 'perl',
    AUTHOR             => [q{Jens Rehsack <rehsack@cpan.org>}, q{Stefan Hermes <hermes@cpan.org>}],
    CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
    PREREQ_PM          => \%RUN_DEPS,
    BUILD_REQUIRES     => \%BUILD_DEPS,
    TEST_REQUIRES      => \%TEST_DEPS,
    test => {TESTS => join(' ', 't/Auto/*/*.t', 't/*.t', 't/Clone/*/*.t', 't/Storable/*/*.t', 't/ClonePP/*/*.t', 'xt/*.t')},
    (-d "Sandbox" ? (realclean => {FILES => join(' ', 't/Auto/', 't/Clone', 't/Storable', 't/ClonePP', 'M*.bak')}) : ()),
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
