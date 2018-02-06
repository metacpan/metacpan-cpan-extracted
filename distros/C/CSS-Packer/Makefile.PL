#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'CSS::Packer',
  ABSTRACT_FROM => 'lib/CSS/Packer.pm',
  VERSION_FROM  => 'lib/CSS/Packer.pm',
  AUTHOR        => 'Lee Johnson <leejo@cpan.org>',
  LICENSE       => 'perl',
  PREREQ_PM => {
    'Regexp::RegGrp'        => '1.001_001',
  },
  BUILD_REQUIRES => {
    'Test::More'               => 0,
    'Test::File::Contents'     => 0.21,
  },
  META_MERGE => {
    resources => {
      license    => 'http://dev.perl.org/licenses/',
      homepage   => 'https://metacpan.org/module/CSS::Packer',
      bugtracker => 'https://github.com/leejo/css-packer-perl/issues',
      repository => 'https://github.com/leejo/css-packer-perl'
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
