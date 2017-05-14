use 5.018;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Acme::Tau',
  AUTHOR             => q{Jeremy Mates <jmates@cpan.org>},
  VERSION            => '6.28',
  ABSTRACT_FROM      => 'lib/Acme/Tau.pm',
  LICENSE            => 'MIT',
  PL_FILES           => {},
  MIN_PERL_VERSION   => 5.018,
  CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
  BUILD_REQUIRES     => { 'Test::More' => 0, },
  PREREQ_PM          => { 'Acme::Pi' => 0, },
  dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Acme-Tau-*' },
);
