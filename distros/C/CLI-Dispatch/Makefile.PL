use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
  NAME          => 'CLI::Dispatch',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/CLI/Dispatch.pm',
  ABSTRACT_FROM => 'lib/CLI/Dispatch.pm',
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
      repository  => 'https://github.com/charsbar/cli-dispatch',
    },
  },
);
