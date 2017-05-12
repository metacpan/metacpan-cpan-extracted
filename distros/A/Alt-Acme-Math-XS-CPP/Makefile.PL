use 5.008001; use strict; use warnings; use utf8;

use lib 'inc';
use ExtUtils::MakeMaker;
use Inline::Module;

WriteMakefile(
  NAME => 'Alt::Acme::Math::XS::CPP',
  VERSION => '0.0.5',
  ABSTRACT => 'Math is HARD (faster!)',
  AUTHOR => 'Ingy döt Net <ingy@cpan.org>',
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.008001',
  test => { TESTS => 't/*.t' },
  postamble => {
    inline => {
      module => 'Acme::Math::XS',
      ilsm => 'Inline::CPP',
      makestub => 1,
    },
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    prereqs => {
        develop => {
          requires => {
            'Inline::CPP'    => '0.69',
            'Inline::Module' => '0.30',
        },
      },
    },
    no_index => {
      directory => [
        'inc',
        'lib/Acme',
      ],
    },
  },
);
