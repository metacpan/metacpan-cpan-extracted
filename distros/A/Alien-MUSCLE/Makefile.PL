use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
  ABSTRACT           => 'Discover or easy install of MUSCLE',
  DISTNAME           => 'Alien-MUSCLE',
  NAME               => 'Alien::MUSCLE',
  VERSION_FROM       => 'lib/Alien/MUSCLE.pm',
  CONFIGURE_REQUIRES => {'Alien::Build::MM' => 0,},
  BUILD_REQUIRES     => {'Alien::Build::MM' => 0,},
  PREREQ_PM          => {
    'Alien::Base'        => 0,
    'Alien::Build'       => '2.20',
    'URI'                => 0,
    'Mojo::DOM58'        => 0,
    'Sort::Versions'     => 0,
    'ExtUtils::CBuilder' => '0.280226',
  },

  META_MERGE => {
    'dynamic_config' => 0,
    'meta-spec'      => {version => 2},
    'resources'      => {
      bugtracker =>
        {web => 'https://github.com/kiwiroy/p5-alien-muscle/issues'},
      homepage   => 'https://github.com/kiwiroy/p5-alien-muscle',
      repository => {
        type => 'git',
        url  => 'https://github.com/kiwiroy/p5-alien-muscle.git',
        web  => 'https://github.com/kiwiroy/p5-alien-muscle',
      },
    },
    'x_contributors' => [],
  },

  # If you are going to write the recommended
  # tests you will will want these:
  TEST_REQUIRES => {'Test::Alien' => 0, 'Test2::Suite' => '0.000129',},
));

sub MY::postamble {
  $abmm->mm_postamble;
}
