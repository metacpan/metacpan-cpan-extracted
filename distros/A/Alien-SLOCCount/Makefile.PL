use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
  ABSTRACT     => 'Build and make available the sloccount tool',
  NAME         => 'Alien::SLOCCount',
  DISTNAME     => 'Alien-SLOCCount',
  VERSION_FROM => 'lib/Alien/SLOCCount.pm',
  AUTHOR       => 'Joenio Costa <joenio@joenio.me>',
  META_MERGE   => {
    resources => {
      repository => 'https://github.com/joenio/alien-sloccount'
    }
  },
  LICENSE      => 'perl',
));
 
sub MY::postamble {
  $abmm->mm_postamble;
}
