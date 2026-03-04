use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME             => 'Alien::MariaDB',
    DISTNAME         => 'Alien-MariaDB',
    VERSION_FROM     => 'lib/Alien/MariaDB.pm',
    ABSTRACT         => 'Find or build libmariadb client library',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',

    CONFIGURE_REQUIRES => {
        'Alien::Build::MM' => 0,
    },
    BUILD_REQUIRES => {
        'Alien::Build::MM' => 0,
    },
    PREREQ_PM => {
        'Alien::Base' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'  => 0,
        'Test::Alien' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-alien-mariadb.git',
                web  => 'https://github.com/vividsnow/perl5-alien-mariadb',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-alien-mariadb/issues',
            },
        },
    },
));

sub MY::postamble {
    $abmm->mm_postamble;
}
