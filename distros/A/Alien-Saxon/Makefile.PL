#!perl -w

require 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'SaxonHE9-8-0-7J';

WriteMakefile(
  NAME => 'Alien::Saxon',
  VERSION_FROM => 'lib/Alien/Saxon.pm',
  MIN_PERL_VERSION => '5.008',
  CONFIGURE_REQUIRES => {
    'File::ShareDir::Install' => '0',
  },
  BUILD_REQUIRES => {
    'File::ShareDir::Install' => '0',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  PREREQ_PM => {
    'File::ShareDir' => '0',
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/mohawk2/Alien-Saxon',
        web => 'https://github.com/mohawk2/Alien-Saxon',
      },
    },
  },
);

package MY;
use File::ShareDir::Install qw(postamble);
