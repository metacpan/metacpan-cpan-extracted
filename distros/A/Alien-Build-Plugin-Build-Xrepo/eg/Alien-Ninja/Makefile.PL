use v5.40;
use lib '../../../lib';
use ExtUtils::MakeMaker;
use Alien::Build::MM 2.84;

# Alien::Build::MM loads the alienfile, folds its prereqs into WriteMakefile,
# and adds Makefile targets that probe/download/build the alien during install.
my $abmm = Alien::Build::MM->new;
WriteMakefile(
    $abmm->mm_args(
        ABSTRACT => 'Build & install ninja (binary) via the Build::Xrepo Alien::Build plugin',
        DISTNAME => 'Alien-Ninja',
        NAME     => 'Alien::Ninja',
        VERSION  => '0.001'
    )
);

sub MY::postamble {
    $abmm->mm_postamble(@_);
}

sub MY::install {
    $abmm->mm_install(@_);
}
