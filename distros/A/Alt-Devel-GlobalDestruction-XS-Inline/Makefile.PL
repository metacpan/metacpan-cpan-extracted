require 5.008001; use strict; use warnings; use utf8;

use lib 'inc';
use ExtUtils::MakeMaker;
use Inline::Module;

my $alt = $ENV{PERL_ALT_INSTALL} || '';
my %WriteMakefileArgs = (
  NAME => 'Alt::Devel::GlobalDestruction::XS::Inline',
  AUTHOR => 'Ingy döt Net <ingy@cpan.org>',
  VERSION_FROM => 'lib/Alt/Devel/GlobalDestruction/XS/Inline.pm',
  ABSTRACT => 'Alternate Faster implementation of the Devel::GlobalDestruction API (using Inline::Module)',
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.008001',
  test => { TESTS => 't/*.t' },
  postamble => {
    inline => {
      module => 'Devel::GlobalDestruction::XS',
      makestub => 1,
    },
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    prereqs => {
      develop => {
        requires => {
          'Inline::Module' => '0.30',
        },
      },
    },
    no_index => {
      directory => [
        'inc',
        'lib/Devel',
      ],
    },
  },
  DESTDIR => $alt ? $alt eq 'OVERWRITE' ? '' : $alt : 'no-install-alt',
);

WriteMakefile(%WriteMakefileArgs);
