use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME          => 'Alien::Wslay',
    DISTNAME      => 'Alien-Wslay',
    VERSION_FROM  => 'lib/Alien/Wslay.pm',
    CONFIGURE_REQUIRES => {
        'Alien::Build::MM' => '0.32',
    },
    BUILD_REQUIRES => {
        'Alien::Build::MM' => '0.32',
    },
    PREREQ_PM => {
        'Alien::Base' => '0.038',
    },
));

sub MY::postamble {
    $abmm->mm_postamble;
}
