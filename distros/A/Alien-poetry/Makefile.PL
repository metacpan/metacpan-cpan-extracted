use ExtUtils::MakeMaker;
use Alien::Build::MM;
 
my $abmm = Alien::Build::MM->new;
 
WriteMakefile($abmm->mm_args(
  ABSTRACT           => 'Download and install poetry',
  DISTNAME           => 'Alien-poetry',
  NAME               => 'Alien::poetry',
  VERSION_FROM       => 'lib/Alien/poetry.pm',
  CONFIGURE_REQUIRES => {
    'Alien::Build::MM' => 0,
  },
  BUILD_REQUIRES => {
    'Alien::Build::MM' => 0,
    'Path::Tiny' => '0.144',
    'File::ShareDir::Dist' => '0.07',
  },
  PREREQ_PM => {
    'Alien::Base' => 0,
  },
  # If you are going to write the recommended
  # tests you will will want these:
  #TEST_REQUIRES => {
  #  'Test::Alien' => 0,
  #  'Test2::V0'   => 0,
  #},
));
 
sub MY::postamble {
  $abmm->mm_postamble;
}
