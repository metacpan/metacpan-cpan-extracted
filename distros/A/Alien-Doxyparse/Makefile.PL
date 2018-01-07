use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
  ABSTRACT     => 'Build and make available the doxyparse tool',
  NAME         => 'Alien::Doxyparse',
  DISTNAME     => 'Alien-Doxyparse',
  VERSION_FROM => 'lib/Alien/Doxyparse.pm',
  AUTHOR       => 'Joenio Costa <joenio@joenio.me>',
  META_MERGE   => {
    resources => {
      repository => 'http://github.com/joenio/alien-doxyparse'
    }
  },
  LICENSE      => 'perl',
));
 
sub MY::postamble {
  $abmm->mm_postamble;
}
