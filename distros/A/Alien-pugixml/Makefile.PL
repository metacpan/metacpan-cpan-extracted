use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME             => 'Alien::pugixml',
    DISTNAME         => 'Alien-pugixml',
    VERSION_FROM     => 'lib/Alien/pugixml.pm',
    ABSTRACT         => 'Find or build pugixml C++ XML parser library',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',

    CONFIGURE_REQUIRES => {
        'Alien::Build::MM'          => 0,
        'Alien::Build::Plugin::Build::CMake' => 0,
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
                url  => 'https://github.com/vividsnow/perl5-alien-pugixml.git',
                web  => 'https://github.com/vividsnow/perl5-alien-pugixml',
            },
        },
    },
));

sub MY::postamble {
    $abmm->mm_postamble;
}
