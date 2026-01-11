use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME               => 'Alien::nghttp2',
    DISTNAME           => 'Alien-nghttp2',
    VERSION_FROM       => 'lib/Alien/nghttp2.pm',
    ABSTRACT_FROM      => 'lib/Alien/nghttp2.pm',
    AUTHOR             => 'Your Name <your@email.com>',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.016',
    CONFIGURE_REQUIRES => {
        'Alien::Build::MM' => '0.32',
        'Alien::Build'     => '2.37',
        'ExtUtils::MakeMaker' => '6.52',
    },
    BUILD_REQUIRES => {
        'Alien::Build' => '2.37',
        'Alien::Build::Plugin::Build::CMake' => '0.99',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.96',
        'Test::Alien' => '0',
    },
    PREREQ_PM => {
        'Alien::Base' => '2.37',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/yourname/Alien-nghttp2.git',
                web  => 'https://github.com/yourname/Alien-nghttp2',
            },
            bugtracker => {
                web => 'https://github.com/yourname/Alien-nghttp2/issues',
            },
        },
    },
));

sub MY::postamble {
    $abmm->mm_postamble;
}
