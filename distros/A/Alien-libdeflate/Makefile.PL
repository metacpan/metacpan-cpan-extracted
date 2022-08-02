use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
  NAME          => 'Alien::libdeflate',
  AUTHOR        => 'Roy Storey <kiwiroy@cpan.org>',
  LICENSE       => 'artistic_2',
  ABSTRACT_FROM => 'lib/Alien/libdeflate.pm',
  DISTNAME      => 'Alien-libdeflate',
  VERSION_FROM  => 'lib/Alien/libdeflate.pm',
  EXE_FILES     => [qw()],
  META_MERGE    => {
    resources => {
      bugtracker => 'https://github.com/kiwiroy/alien-libdeflate/issues',
      homepage   => 'https://github.com/kiwiroy/alien-libdeflate',
      repository => 'https://github.com/kiwiroy/alien-libdeflate.git',
    },
  },
  CONFIGURE_REQUIRES => {
    'Alien::Build'        => '1.41',
    'Alien::Build::MM'    => '1.41',
    'ExtUtils::MakeMaker' => '6.52',
  },
  BUILD_REQUIRES => {
    'Alien::Build'        => '1.41',
    'Alien::Build::MM'    => '1.41',
    'ExtUtils::MakeMaker' => '6.52',
  },
  PREREQ_PM => {
    'perl'        => '5.008009',
    'Alien::Base' => '0.038',
    'base'        => '0',
    'strict'      => '0',
    'warnings'    => '0',
  },
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
));

sub MY::postamble {
  $abmm->mm_postamble;
}
