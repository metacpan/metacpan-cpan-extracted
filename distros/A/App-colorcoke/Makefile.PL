#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::colorcoke',
    AUTHOR              => q{Magnus Woldrich <m@japh.se>},
    ABSTRACT            => 'Modify the extended terminal colorset',
    VERSION_FROM        => 'lib/App/colorcoke.pm',

    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),

    PL_FILES            => {},

    PREREQ_PM           => {
      'Test::More' =>     0,
      'Term::ExtendedColor'             => 0,
      'Term::ExtendedColor::Xresources' => 0,
    },

    EXE_FILES           => ['bin/colorcoke',
                            glob("scripts/*"),
    ],

    META_ADD                     => {
      provides => {
        'App::colorcoke' => {
          file => 'lib/App/colorcoke.pm',
        },
      },
    },

    MAN1PODS            => {
      'bin/colorcoke'           => 'blib/man1/colorcoke.1',
    },

    MIN_PERL_VERSION    => 5.010,

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'colorcoke-*' },
);


