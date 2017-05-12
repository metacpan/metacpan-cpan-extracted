use strict;
use warnings FATAL => 'all';
use 5.006;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %BUILD_DEPS = (
  'Test::More' => 0.47,
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta = eval($ExtUtils::MakeMaker::VERSION) >= 6.57_02;
my $mymeta_works = eval($ExtUtils::MakeMaker::VERSION) >= 6.57_07;

WriteMakefile(
  NAME => 'Algorithm::C3',
  VERSION_FROM => 'lib/Algorithm/C3.pm',
  PREREQ_PM => {
    'Carp' => 0.01,
    ($mymeta_works ? () : (%BUILD_DEPS)),
  },
  MIN_PERL_VERSION => 5.006,
  $mymeta_works ? (BUILD_REQUIRES => \%BUILD_DEPS) : (),
  ($mymeta && !$mymeta_works ? (NO_MYMETA => 1) : ()),

  -f 'META.yml' ? () : (META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      # r/w: gitmo@git.shadowcat.co.uk:Algorithm-C3.git
      repository => {
        url => 'git://git.shadowcat.co.uk/gitmo/Algorithm-C3.git',
        web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/Algorithm-C3.git',
        type => 'git',
      },
      bugtracker => {
          mailto => 'bug-Algorithm-C3@rt.cpan.org',
          web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-C3',
      },
    },
  }),
);
