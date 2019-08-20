use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Daje::Sentinel::Api',
  VERSION_FROM => 'lib/Daje/Sentinel/Api.pm',
  AUTHOR       => 'Jan Eskilsson <nospam@cpan.org>',
  PREREQ_PM    => {
      'Try::Tiny'                        => 0,
      'Daje::Utils::Factory::Collection' => 0,
      'POSIX'                            => 0,
      'Daje::Collection::Collection'     => 0,
    },
  test         => {
      TESTS => 't/*.t'
  }
);
