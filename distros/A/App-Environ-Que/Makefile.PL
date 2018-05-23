use strict;
use warnings;
use v5.10;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'App::Environ::Que',
  VERSION_FROM => 'lib/App/Environ/Que.pm',
  PREREQ_PM    => {
    'App::Environ'           => '0.18',
    'App::Environ::Mojo::Pg' => '0.2',
    'Params::Validate'       => 0,
  },
  ABSTRACT_FROM => 'lib/App/Environ/Que.pm',
  AUTHOR        => 'Andrey Kuzmin <kak-tus@mail.ru>',
  META_MERGE    => {
    dynamic_config => 0,
    'meta-spec'    => { version => 2 },
    no_index       => { directory => [ 'example', 't' ] },
    prereqs        => { runtime => { requires => { perl => '5.010001' } } },
    resources      => {
      repository => {
        type => 'git',
        url  => 'https://github.com/kak-tus/App-Environ-Que.git',
        web  => 'https://github.com/kak-tus/App-Environ-Que',
      },
    },
  },
);
