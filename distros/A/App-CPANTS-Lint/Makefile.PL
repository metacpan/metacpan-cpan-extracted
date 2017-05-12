use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
  NAME          => 'App::CPANTS::Lint',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/App/CPANTS/Lint.pm',
  ABSTRACT_FROM => 'lib/App/CPANTS/Lint.pm',
  LICENSE       => 'perl',
  EXE_FILES     => ['bin/cpants_lint.pl'],
  MIN_PERL_VERSION => '5.008001',
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/App-CPANTS-Lint',
    },
  },
);
