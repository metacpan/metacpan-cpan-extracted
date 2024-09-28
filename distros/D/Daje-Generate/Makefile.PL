use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Daje::Generate',
  VERSION_FROM => 'lib/Daje/Generate.pm',
  AUTHOR       => 'janskil1525@gmail.com',
  PREREQ_PM    => {
      'Syntax::Keyword::Match ' => '0.15',
      'Mojo::JSON'              => '0',
      'Config::Tiny'            => '2.30',
      'Digest::SHA'             => '6.04',
      'Mojo::File'              => '0',
  },
  test         => {TESTS => 't/*.t'}
);
