package SlotMakeMaker;

use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::postamble {
  return <<EOS;

misc : readme manifest

release : test dist
\tcpan-upload \$(DISTVNAME).tar.gz

EOS
}

WriteMakefile(
  NAME             => 'Class::Slot',
  AUTHOR           => 'Jeff Ober <sysread@fastmail.fm>',
  VERSION_FROM     => "lib/Class/Slot.pm",
  ABSTRACT_FROM    => 'README.pod',
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.008002',
  PREREQ_PRINT     => 1,

  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      homepage => "https://github.com/sysread/slot",

      bugtracker => {
        web => "https://github.com/sysread/slot/issues"
      },

      repository => {
        type => "git",
        url  => "https://github.com/sysread/slot.git",
        web  => "https://github.com/sysread/slot"
      }
    },
  },

  MAN3PODS => {
    'README.pod' => "blib/man3/Class::Slot.3",
  },

  test => {
    TESTS => 't/*',
  },

  clean => {
    FILES => "*.bak Class-Slot-*.tar.gz",
  },

  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.63_03',
  },

  TEST_REQUIRES => {
    'Type::Tiny' => 0,
    'Test::More' => 0,
  },

  PREREQ_PM => {
    'Carp'           => 0,
    'Filter::Simple' => 0,
    'Scalar::Util'   => 0,
  },
);

1;
