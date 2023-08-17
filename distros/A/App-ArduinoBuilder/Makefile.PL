use 5.026;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::ArduinoBuilder',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/App/ArduinoBuilder.pm',
    ABSTRACT         => "Build system for Arduino programs",
    LICENSE          => 'mit',
    EXE_FILES        => ['script/arduino_builder'],
    # The only requirement on 5.26 are indented here docs in the tests.
    # Otherwise I believe that everything should work with 5.22
    MIN_PERL_VERSION => '5.026',
    MAN3PODS         => {},
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
    },
    TEST_REQUIRES => {
      'Test2::V0'             => 0,
    },
    # We don’t really need a MYMETA file, but then cpanm can’t correctly find
    # our dependencies. CPAN works correctly either way.
    # NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      dynamic_config => 0,
      no_index => {
        # ignores child of App::ArduinoBuilder, but not App::ArduinoBuilder itself.
        namespace => [ 'App::ArduinoBuilder' ],
      },
      prereqs => {
        test => {
          suggests => {
            'Perl::Tidy'               => '20220613',
            'Test::Pod'                => '1.00',
            'Test2::Tools::PerlCritic' => 0,
          },
        },
      },
      optional_features => {
        # This is set as an optional feature so that the GitHub CI does not need
        # to fetch this module that has a lot of dependencies.
        test_coverage => {
          description => 'Run `make cover` to compute test coverage',
          prereqs => {
            test => {
              requires => {
                'Devel::Cover' => 0,
              },
            },
          },
        },
      },
      keywords => [ qw(arduino embedded arm avr build make compiler source) ],
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/arduino_builder.git',
          web => 'https://github.com/mkende/arduino_builder',
        },
        bugtracker => {
          web => 'https://github.com/mkende/arduino_builder/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Arduino-Builder-* cover_db' },
);

sub MY::postamble {
  return <<MAKE_FRAGMENT
cover:
\tcover -test

critic:
\tperlcritic lib

tidy:
\tperltidy -b lib/App/ArduinoBuilder.pm

tidydiff:
\tperltidy lib/App/ArduinoBuilder.pm
\tdiff -u lib/App/ArduinoBuilder.pm lib/App/ArduinoBuilder.tdy

spelling: export TEST_AUTHOR = 1
spelling:
\tperl -Ilib t/00-spelling.t --interactive

alltest: export TEST_AUTHOR = 1
alltest: test
MAKE_FRAGMENT
}
