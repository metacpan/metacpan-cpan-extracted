use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker;

BEGIN
{
    eval "use File::ShareDir::Install;";
    $@ and eval "use lib qw,inc/File-ShareDir-Install,; use File::ShareDir::Install;";
    $@ and die $@;
}

use File::ShareDir::Install 0.03;

my %RUN_DEPS = (
    'Carp'                    => 0,
    'LaTeX::Table'            => '1.0.6',
    'Hash::MoreUtils'         => 0,
    'Math::Complex'           => '1.56',
    'Math::Prime::Util'       => 0,
    'Module::Runtime'         => 0,
    'MooX::Cmd'               => '0.007',
    'MooX::Options'           => '4.000',
    'Template'                => '2.25',
    'Template::Plugin::Latex' => '3.01',
);

my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker'     => 0,
    'File::ShareDir::Install' => '0.03'
);

my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'MooX::Cmd::Tester' => '0.007',
    'Test::More'        => '0.90',
);

install_share 'share';

WriteMakefile1(
    MIN_PERL_VERSION => '5.008001',
    META_ADD         => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://metacpan.org/release/App-Math-Tutor',
            repository => {
                url  => 'git@github.com:rehsack/App-Math-Tutor.git',
                web  => 'https://github.com/rehsack/App-Math-Tutor',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=App-Math-Tutor',
                mailto => 'app-math-tutor@rt.cpan.org',
            },
            license => 'http://dev.perl.org/licenses/',
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
            build   => { requires => {%BUILD_DEPS} },
            test    => { requires => {%TEST_DEPS} },
            runtime => {
                requires => {
                    %RUN_DEPS,
                    perl => '5.8.1',
                },
            },
        },
    },
    NAME               => 'App::Math::Tutor',
    VERSION_FROM       => 'lib/App/Math/Tutor.pm',
    ABSTRACT_FROM      => 'lib/App/Math/Tutor.pm',
    LICENSE            => 'perl',
    AUTHOR             => q{Jens Rehsack <rehsack@cpan.org>},
    EXE_FILES          => [qw(bin/mtut)],
    PREREQ_PM          => \%RUN_DEPS,
    CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
    BUILD_REQUIRES     => \%BUILD_DEPS,
    TEST_REQUIRES      => \%TEST_DEPS,
    test               => { TESTS => 't/*.t xt/*.t' },
);

sub WriteMakefile1
{    # originally written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if ( exists( $params{EXTRA_META} ) );
    die "License not specified"    if ( !exists( $params{LICENSE} ) );
    if ( $params{TEST_REQUIRES} and ( $eumm_version < 6.6303 ) )
    {
        if ( $params{BUILD_REQUIRES} )
        {
            $params{BUILD_REQUIRES} = { %{ $params{BUILD_REQUIRES} }, %{ $params{TEST_REQUIRES} } };
        }
        else
        {
            $params{BUILD_REQUIRES} = delete $params{TEST_REQUIRES};
        }
    }
    if ( $params{BUILD_REQUIRES} and ( $eumm_version < 6.5503 ) )
    {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }
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

package MY;

use File::ShareDir::Install qw(postamble);

1;
