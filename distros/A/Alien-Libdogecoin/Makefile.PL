use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
  ABSTRACT           => 'Discover or download and install libdogecoin',
  DISTNAME           => 'Alien-Libdogecoin',
  NAME               => 'Alien::Libdogecoin',
  VERSION_FROM       => 'lib/Alien/Libdogecoin.pm',
  LICENSE            => 'perl_5',
  CONFIGURE_REQUIRES => {
    'Alien::Build::MM' => 0,
  },
  BUILD_REQUIRES => {
    'Alien::Build::MM' => 0,
    'Alien::Autotools' => 1.07,
  },
  PREREQ_PM => {
    'Alien::Base' => 0,
  },
  TEST_REQUIRES => {
    'Test::Alien' => 0,
    'Test2::V0'   => 0,
  },
));

sub MY::postamble {
  $abmm->mm_postamble;
}
