use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
  NAME           => 'Acme::CPANAuthors',
  AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM   => 'lib/Acme/CPANAuthors.pm',
  ABSTRACT_FROM  => 'lib/Acme/CPANAuthors.pm',
  META_MERGE => {
    resources => {
      repository  => 'https://github.com/charsbar/acme-cpanauthors',
    },
  },
  LICENSE => 'perl',
);
