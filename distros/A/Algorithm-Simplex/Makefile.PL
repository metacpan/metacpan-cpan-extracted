use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %RUN_DEPS = (
  'Moo'                    => 0,
  'MooX::Types::MooseLike' => 0.16,
  'namespace::clean'       => 0,
  'Math::Cephes::Fraction' => 0,
  'PDL'                    => 0,
  'PDL::Lite'              => 0,
  'Math::BigRat'           => 0,
);
my %BUILD_DEPS = (
  'Test::More'  => 0.96,
);

WriteMakefile(
  NAME           => 'Algorithm::Simplex',
  VERSION_FROM   => 'lib/Algorithm/Simplex.pm',
  PREREQ_PM      => {
    %RUN_DEPS,
  },
  BUILD_REQUIRES => {
    %BUILD_DEPS,
  },
  META_ADD => {
    resources => {
      repository  => 'git://github.com/mateu/Algorithm-Simplex.git',
      bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Simplex',
    },
  },
  LICENSE => 'perl',
);
