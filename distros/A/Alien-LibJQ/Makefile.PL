use ExtUtils::MakeMaker;
use strict;
use warnings;

# ignore system library, force a build from source code
BEGIN { $ENV{ALIEN_INSTALL_TYPE} = 'share'; }

use File::Spec;
use Alien::Build;
use Alien::Build::MM;

my $alien_build_version   = '2.37';
my $ext_makemaker_version = '7.46';

my %WriteMakefileArgs = (
    NAME                => 'Alien::LibJQ',
    DISTNAME            => 'Alien-LibJQ',
    VERSION_FROM        => 'lib/Alien/LibJQ.pm',
    AUTHOR              => 'Dongxu Ma (dongxu __at__ cpan.org)',
    ABSTRACT            => 'Build libjq library (https://stedolan.github.io/jq/)',
    BUILD_REQUIRES      => {
        'Alien::Build'        => $alien_build_version,
        'ExtUtils::MakeMaker' => $ext_makemaker_version,
        'Alien::cmake3'       => '0.05',
    },
    CONFIGURE_REQUIRES  => {
        'Alien::Build'        => $alien_build_version,
        'ExtUtils::MakeMaker' => $ext_makemaker_version,
        'File::Spec'          => 0,
    },
    # TEST_REQUIRES       => {
    #     'Test2::V0'           => 0,
    #     'Test::Alien'         => 0,
    # },
    LICENSE             => 'mit',
    MIN_PERL_VERSION    => '5.008001',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'Alien::Base'  => $alien_build_version,
    },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage    => undef,
            repository  => {
                url         => 'git@github.com:dxma/perl5-alien-libjq.git',
                web         => 'https://github.com/dxma/perl5-alien-libjq',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/dxma/perl5-alien-libjq/issues',
            },
        },
    })),
);

my $abmm = Alien::Build::MM->new;
WriteMakefile($abmm->mm_args(%WriteMakefileArgs));

sub MY::postamble {
    $abmm->mm_postamble;
}