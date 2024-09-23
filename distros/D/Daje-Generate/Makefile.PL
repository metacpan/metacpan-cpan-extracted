use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Daje::Generate',
  VERSION_FROM => 'lib/Daje/Generate.pm',
  AUTHOR       => 'janskil1525@gmail.com',
  PREREQ_PM    => {
      'Syntax::Keyword::Match '  => '0.15',
      'Mojo::JSON'               => '9.38',

  },
  test         => {TESTS => 't/*.t'}
);
