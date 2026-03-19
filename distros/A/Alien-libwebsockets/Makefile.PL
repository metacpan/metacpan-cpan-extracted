use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME             => 'Alien::libwebsockets',
    DISTNAME         => 'Alien-libwebsockets',
    VERSION_FROM     => 'lib/Alien/libwebsockets.pm',
    ABSTRACT         => 'Find or build libwebsockets C library',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',

    CONFIGURE_REQUIRES => {
        'Alien::Build'                       => '2.37',
        'Alien::Build::MM'                   => '2.37',
        'Alien::Build::Plugin::Build::CMake' => '0.99',
    },
    PREREQ_PM => {
        'Alien::Base'  => '2.37',
        'Alien::Build' => '2.37',
    },
    TEST_REQUIRES => {
        'Test::More'  => 0,
        'Test::Alien' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'Alien::libwebsockets' => {
                file    => 'lib/Alien/libwebsockets.pm',
                version => MM->parse_version('lib/Alien/libwebsockets.pm'),
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-alien-libwebsockets.git',
                web  => 'https://github.com/vividsnow/perl5-alien-libwebsockets',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-alien-libwebsockets/issues',
            },
        },
    },
));

sub MY::postamble {
    $abmm->mm_postamble;
}
